#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bench_compare.sh [--baseline PATH] [--candidate PATH]
  bench_compare.sh BASELINE_PATH CANDIDATE_PATH

Each path may point to:
  - a benchmark capture directory
  - a capture's summary.txt
  - a capture's capture.env

Examples:
  bench_compare.sh .bench-captures/20260329T000000Z_baseline .bench-captures/20260329T000100Z_candidate
  bench_compare.sh --baseline /tmp/run-a/summary.txt --candidate /tmp/run-b/capture.env

Compares elapsed time and key capture metadata, then emits warnings when the runs
are not directly comparable.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

resolve_capture_dir() {
  local input="$1"

  if [ -d "$input" ]; then
    printf '%s\n' "$(cd "$input" && pwd)"
    return
  fi

  if [ -f "$input" ]; then
    case "$(basename "$input")" in
      summary.txt|capture.env)
        printf '%s\n' "$(cd "$(dirname "$input")" && pwd)"
        return
        ;;
    esac
  fi

  echo "Could not resolve capture directory from: $input" >&2
  exit 2
}

load_capture_field() {
  local capture_dir="$1"
  local field="$2"

  if [ ! -f "$capture_dir/capture.env" ]; then
    echo "Missing capture.env in $capture_dir" >&2
    exit 2
  fi

  (
    set -euo pipefail
    # shellcheck disable=SC1090
    . "$capture_dir/capture.env"
    eval "printf '%s' \"\${$field-}\""
  )
}

load_telemetry_field() {
  local capture_dir="$1"
  local field="$2"
  local summary_path="$capture_dir/telemetry_summary.txt"

  if [ ! -f "$summary_path" ]; then
    return 0
  fi

  sed -n "s/^${field}=//p" "$summary_path" | head -n 1
}

load_telemetry_warnings() {
  local capture_dir="$1"
  local summary_path="$capture_dir/telemetry_summary.txt"

  if [ ! -f "$summary_path" ]; then
    return 0
  fi

  sed -n 's/^warning=//p' "$summary_path"
}

format_ms() {
  local ms="$1"
  if have python3; then
    python3 - "$ms" <<'PY'
import sys
ms = float(sys.argv[1])
if ms >= 1000:
    print(f"{ms/1000:.3f}s")
else:
    print(f"{ms:.0f}ms")
PY
  else
    printf '%sms\n' "$ms"
  fi
}

compute_delta_block() {
  local baseline_ms="$1"
  local candidate_ms="$2"
  if have python3; then
    python3 - "$baseline_ms" "$candidate_ms" <<'PY'
import sys
baseline = float(sys.argv[1])
candidate = float(sys.argv[2])
delta = candidate - baseline
pct = 0.0 if baseline == 0 else (delta / baseline) * 100.0
speedup = None if candidate == 0 else baseline / candidate
if delta < 0:
    trend = "faster"
elif delta > 0:
    trend = "slower"
else:
    trend = "unchanged"
print(f"delta_ms={delta:.3f}")
print(f"delta_pct={pct:.2f}")
print(f"trend={trend}")
if speedup is not None:
    print(f"speedup={speedup:.3f}")
PY
  else
    echo "delta_ms=unknown"
    echo "delta_pct=unknown"
    echo "trend=unknown"
    echo "speedup=unknown"
  fi
}

parse_hyperfine_mean_ms() {
  local capture_dir="$1"
  local stdout_file="$capture_dir/stdout.txt"

  if [ ! -f "$stdout_file" ] || ! have python3; then
    return 1
  fi

  python3 - "$stdout_file" <<'PY'
import re
import sys

path = sys.argv[1]
unit_scale = {
    "ns": 0.000001,
    "us": 0.001,
    "µs": 0.001,
    "μs": 0.001,
    "ms": 1.0,
    "s": 1000.0,
}
pattern = re.compile(r"Time \(mean .*?\):\s*([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Zµμ]+)")

with open(path, "r", encoding="utf-8", errors="ignore") as fh:
    for line in fh:
        match = pattern.search(line)
        if not match:
            continue
        value = float(match.group(1))
        unit = match.group(2)
        if unit not in unit_scale:
            continue
        print(value * unit_scale[unit])
        sys.exit(0)

sys.exit(1)
PY
}

BASELINE=""
CANDIDATE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --baseline)
      if [ $# -lt 2 ]; then
        echo "--baseline requires a value" >&2
        exit 2
      fi
      BASELINE="$2"
      shift 2
      ;;
    --candidate)
      if [ $# -lt 2 ]; then
        echo "--candidate requires a value" >&2
        exit 2
      fi
      CANDIDATE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -z "$BASELINE" ]; then
        BASELINE="$1"
      elif [ -z "$CANDIDATE" ]; then
        CANDIDATE="$1"
      else
        echo "Unexpected extra positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [ -z "$BASELINE" ] || [ -z "$CANDIDATE" ]; then
  usage >&2
  exit 2
fi

BASELINE_DIR="$(resolve_capture_dir "$BASELINE")"
CANDIDATE_DIR="$(resolve_capture_dir "$CANDIDATE")"

BASELINE_LABEL="$(load_capture_field "$BASELINE_DIR" label)"
BASELINE_ELAPSED_MS="$(load_capture_field "$BASELINE_DIR" elapsed_ms)"
BASELINE_EXIT_STATUS="$(load_capture_field "$BASELINE_DIR" exit_status)"
BASELINE_NOISE_STATUS="$(load_capture_field "$BASELINE_DIR" noise_status)"
BASELINE_COMMAND="$(load_capture_field "$BASELINE_DIR" command)"
BASELINE_GIT_HEAD="$(load_capture_field "$BASELINE_DIR" git_head)"
BASELINE_GIT_DIRTY="$(load_capture_field "$BASELINE_DIR" git_dirty)"
BASELINE_NOTES="$(load_capture_field "$BASELINE_DIR" notes_path)"
BASELINE_TIMESTAMP="$(load_capture_field "$BASELINE_DIR" timestamp_utc)"

CANDIDATE_LABEL="$(load_capture_field "$CANDIDATE_DIR" label)"
CANDIDATE_ELAPSED_MS="$(load_capture_field "$CANDIDATE_DIR" elapsed_ms)"
CANDIDATE_EXIT_STATUS="$(load_capture_field "$CANDIDATE_DIR" exit_status)"
CANDIDATE_NOISE_STATUS="$(load_capture_field "$CANDIDATE_DIR" noise_status)"
CANDIDATE_COMMAND="$(load_capture_field "$CANDIDATE_DIR" command)"
CANDIDATE_GIT_HEAD="$(load_capture_field "$CANDIDATE_DIR" git_head)"
CANDIDATE_GIT_DIRTY="$(load_capture_field "$CANDIDATE_DIR" git_dirty)"
CANDIDATE_NOTES="$(load_capture_field "$CANDIDATE_DIR" notes_path)"
CANDIDATE_TIMESTAMP="$(load_capture_field "$CANDIDATE_DIR" timestamp_utc)"

BASELINE_TELEMETRY_STATUS="$(load_telemetry_field "$BASELINE_DIR" status)"
BASELINE_TELEMETRY_PRESSURE="$(load_telemetry_field "$BASELINE_DIR" peak_memory_pressure)"
BASELINE_TELEMETRY_THERMAL="$(load_telemetry_field "$BASELINE_DIR" thermal_signal)"
BASELINE_TELEMETRY_DISK="$(load_telemetry_field "$BASELINE_DIR" max_disk_used_percent)"
BASELINE_TELEMETRY_WARNINGS="$(load_telemetry_warnings "$BASELINE_DIR")"

CANDIDATE_TELEMETRY_STATUS="$(load_telemetry_field "$CANDIDATE_DIR" status)"
CANDIDATE_TELEMETRY_PRESSURE="$(load_telemetry_field "$CANDIDATE_DIR" peak_memory_pressure)"
CANDIDATE_TELEMETRY_THERMAL="$(load_telemetry_field "$CANDIDATE_DIR" thermal_signal)"
CANDIDATE_TELEMETRY_DISK="$(load_telemetry_field "$CANDIDATE_DIR" max_disk_used_percent)"
CANDIDATE_TELEMETRY_WARNINGS="$(load_telemetry_warnings "$CANDIDATE_DIR")"

WARNINGS=()

PRIMARY_METRIC_NAME="capture_elapsed_ms"
PRIMARY_METRIC_SOURCE="capture elapsed time"
PRIMARY_BASELINE_VALUE="$BASELINE_ELAPSED_MS"
PRIMARY_CANDIDATE_VALUE="$CANDIDATE_ELAPSED_MS"

if [[ "$BASELINE_COMMAND" == hyperfine* ]] && [[ "$CANDIDATE_COMMAND" == hyperfine* ]]; then
  if BASELINE_HYPERFINE_MS="$(parse_hyperfine_mean_ms "$BASELINE_DIR" 2>/dev/null)" && \
     CANDIDATE_HYPERFINE_MS="$(parse_hyperfine_mean_ms "$CANDIDATE_DIR" 2>/dev/null)"; then
    PRIMARY_METRIC_NAME="hyperfine_mean_ms"
    PRIMARY_METRIC_SOURCE="hyperfine mean benchmark time"
    PRIMARY_BASELINE_VALUE="$BASELINE_HYPERFINE_MS"
    PRIMARY_CANDIDATE_VALUE="$CANDIDATE_HYPERFINE_MS"
  else
    WARNINGS+=("hyperfine detected but mean benchmark time could not be parsed; falling back to outer capture elapsed time")
  fi
fi

DELTA_BLOCK="$(compute_delta_block "$PRIMARY_BASELINE_VALUE" "$PRIMARY_CANDIDATE_VALUE")"
DELTA_MS="$(printf '%s\n' "$DELTA_BLOCK" | sed -n 's/^delta_ms=//p')"
DELTA_PCT="$(printf '%s\n' "$DELTA_BLOCK" | sed -n 's/^delta_pct=//p')"
TREND="$(printf '%s\n' "$DELTA_BLOCK" | sed -n 's/^trend=//p')"
SPEEDUP="$(printf '%s\n' "$DELTA_BLOCK" | sed -n 's/^speedup=//p')"

if [ "$BASELINE_COMMAND" != "$CANDIDATE_COMMAND" ]; then
  WARNINGS+=("commands differ; compare with caution")
fi

if [ "$BASELINE_GIT_HEAD" != "$CANDIDATE_GIT_HEAD" ]; then
  WARNINGS+=("git_head differs between runs")
fi

if [ "$BASELINE_GIT_DIRTY" = "yes" ] || [ "$CANDIDATE_GIT_DIRTY" = "yes" ]; then
  WARNINGS+=("at least one run came from a dirty worktree")
fi

if [ "$BASELINE_EXIT_STATUS" != "0" ] || [ "$CANDIDATE_EXIT_STATUS" != "0" ]; then
  WARNINGS+=("at least one run exited nonzero")
fi

if [ "$BASELINE_NOISE_STATUS" = "NOISY" ] || [ "$CANDIDATE_NOISE_STATUS" = "NOISY" ]; then
  WARNINGS+=("at least one run was captured on a noisy machine")
fi

if [ -n "$BASELINE_TELEMETRY_STATUS" ] && [ "$BASELINE_TELEMETRY_STATUS" != "stable" ] && [ "$BASELINE_TELEMETRY_STATUS" != "unknown" ]; then
  WARNINGS+=("baseline telemetry status is $BASELINE_TELEMETRY_STATUS")
fi

if [ -n "$CANDIDATE_TELEMETRY_STATUS" ] && [ "$CANDIDATE_TELEMETRY_STATUS" != "stable" ] && [ "$CANDIDATE_TELEMETRY_STATUS" != "unknown" ]; then
  WARNINGS+=("candidate telemetry status is $CANDIDATE_TELEMETRY_STATUS")
fi

printf '# Bench Compare\n\n'
printf 'baseline_capture=%s\n' "$BASELINE_DIR"
printf 'candidate_capture=%s\n\n' "$CANDIDATE_DIR"

printf '## Baseline\n'
printf -- '- label: %s\n' "$BASELINE_LABEL"
printf -- '- timestamp_utc: %s\n' "$BASELINE_TIMESTAMP"
printf -- '- elapsed: %s\n' "$(format_ms "$BASELINE_ELAPSED_MS")"
printf -- '- exit_status: %s\n' "$BASELINE_EXIT_STATUS"
printf -- '- noise_status: %s\n' "$BASELINE_NOISE_STATUS"
printf -- '- git_head: %s\n' "$BASELINE_GIT_HEAD"
printf -- '- notes: %s\n\n' "$BASELINE_NOTES"

printf '## Candidate\n'
printf -- '- label: %s\n' "$CANDIDATE_LABEL"
printf -- '- timestamp_utc: %s\n' "$CANDIDATE_TIMESTAMP"
printf -- '- elapsed: %s\n' "$(format_ms "$CANDIDATE_ELAPSED_MS")"
printf -- '- exit_status: %s\n' "$CANDIDATE_EXIT_STATUS"
printf -- '- noise_status: %s\n' "$CANDIDATE_NOISE_STATUS"
printf -- '- git_head: %s\n' "$CANDIDATE_GIT_HEAD"
printf -- '- notes: %s\n\n' "$CANDIDATE_NOTES"

printf '## Delta\n'
printf -- '- primary_metric: %s\n' "$PRIMARY_METRIC_NAME"
printf -- '- metric_source: %s\n' "$PRIMARY_METRIC_SOURCE"
printf -- '- baseline_metric: %s\n' "$(format_ms "$PRIMARY_BASELINE_VALUE")"
printf -- '- candidate_metric: %s\n' "$(format_ms "$PRIMARY_CANDIDATE_VALUE")"
printf -- '- metric_delta_ms: %s\n' "$DELTA_MS"
printf -- '- metric_percent_delta: %s%%\n' "$DELTA_PCT"
printf -- '- trend: %s\n' "$TREND"
printf -- '- relative_speed: %sx\n\n' "$SPEEDUP"

printf '## Telemetry\n'
printf -- '- baseline_status: %s\n' "${BASELINE_TELEMETRY_STATUS:-unavailable}"
printf -- '- baseline_peak_memory_pressure: %s\n' "${BASELINE_TELEMETRY_PRESSURE:-unknown}"
printf -- '- baseline_max_disk_used_percent: %s\n' "${BASELINE_TELEMETRY_DISK:-unknown}"
printf -- '- baseline_thermal_signal: %s\n' "${BASELINE_TELEMETRY_THERMAL:-unavailable}"
printf -- '- candidate_status: %s\n' "${CANDIDATE_TELEMETRY_STATUS:-unavailable}"
printf -- '- candidate_peak_memory_pressure: %s\n' "${CANDIDATE_TELEMETRY_PRESSURE:-unknown}"
printf -- '- candidate_max_disk_used_percent: %s\n' "${CANDIDATE_TELEMETRY_DISK:-unknown}"
printf -- '- candidate_thermal_signal: %s\n' "${CANDIDATE_TELEMETRY_THERMAL:-unavailable}"
if [ -n "$BASELINE_TELEMETRY_WARNINGS" ]; then
  while IFS= read -r warning; do
    [ -n "$warning" ] || continue
    printf -- '- baseline_warning: %s\n' "$warning"
  done <<< "$BASELINE_TELEMETRY_WARNINGS"
fi
if [ -n "$CANDIDATE_TELEMETRY_WARNINGS" ]; then
  while IFS= read -r warning; do
    [ -n "$warning" ] || continue
    printf -- '- candidate_warning: %s\n' "$warning"
  done <<< "$CANDIDATE_TELEMETRY_WARNINGS"
fi
printf '\n'

printf '## Comparability\n'
printf -- '- baseline_command: %s\n' "$BASELINE_COMMAND"
printf -- '- candidate_command: %s\n' "$CANDIDATE_COMMAND"
if [ "${#WARNINGS[@]}" -eq 0 ]; then
  printf -- '- status: comparable\n'
else
  printf -- '- status: compare-with-caution\n'
  for warning in "${WARNINGS[@]}"; do
    printf -- '- warning: %s\n' "$warning"
  done
fi
printf '\n'

printf '## Next Moves\n'
printf -- '- Inspect the two notes.md files for the causal explanation, blockers, and unblockers behind the numbers.\n'
printf -- '- Inspect telemetry_summary.txt when machine-level constraints may explain the result or the comparability warnings.\n'
printf -- '- If the commands or machine conditions differ, rerun the critical point under tighter control before keeping the win.\n'
