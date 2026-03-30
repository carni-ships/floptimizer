#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PATH="."
CPU_THRESHOLD="${CPU_THRESHOLD:-10}"
MEM_THRESHOLD="${MEM_THRESHOLD:-8}"
BACKGROUND_CPU_THRESHOLD="${BACKGROUND_CPU_THRESHOLD:-2}"
TOP_N="${TOP_N:-5}"
KEEP_ARTIFACTS=0

usage() {
  cat <<'EOF'
Usage:
  resource_gate.sh [--target-path PATH] [--keep-artifacts]

Runs a lightweight admission check before starting a new compute-heavy job.

Exit codes:
  0 -> READY
 10 -> REVIEW
  1 -> PAUSE
EOF
}

REASONS=()
GATE_STATUS="READY"
GATE_EXIT=0
NOISE_STATUS="unknown"
TELEMETRY_STATUS="unknown"

TMP_DIR="$(mktemp -d)"
cleanup() {
  if [ "$KEEP_ARTIFACTS" != "1" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    --target-path)
      if [ $# -lt 2 ]; then
        echo "--target-path requires a value" >&2
        exit 2
      fi
      TARGET_PATH="$2"
      shift 2
      ;;
    --keep-artifacts)
      KEEP_ARTIFACTS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

NOISE_REPORT="$TMP_DIR/machine_noise.txt"
TELEMETRY_RAW="$TMP_DIR/telemetry.txt"
TELEMETRY_SUMMARY="$TMP_DIR/telemetry_summary.txt"

if [ -f "$SCRIPT_DIR/machine_noise_check.sh" ]; then
  if bash "$SCRIPT_DIR/machine_noise_check.sh" \
    --cpu-threshold "$CPU_THRESHOLD" \
    --mem-threshold "$MEM_THRESHOLD" \
    --background-cpu-threshold "$BACKGROUND_CPU_THRESHOLD" \
    --top "$TOP_N" > "$NOISE_REPORT" 2>&1; then
    NOISE_STATUS="QUIET"
  else
    NOISE_STATUS="NOISY"
    GATE_STATUS="PAUSE"
    GATE_EXIT=1
    REASONS+=("competing-local-work")
  fi
else
  printf 'machine_noise_check unavailable\n' > "$NOISE_REPORT"
  NOISE_STATUS="unavailable"
fi

if [ -f "$SCRIPT_DIR/profile_telemetry.sh" ] && [ -f "$SCRIPT_DIR/telemetry_summary.sh" ]; then
  if bash "$SCRIPT_DIR/profile_telemetry.sh" --once --target-path "$TARGET_PATH" > "$TELEMETRY_RAW" 2>&1; then
    bash "$SCRIPT_DIR/telemetry_summary.sh" "$TELEMETRY_RAW" > "$TELEMETRY_SUMMARY" 2>&1 || true
    TELEMETRY_STATUS="$(sed -n 's/^status=//p' "$TELEMETRY_SUMMARY" | tail -n 1)"
    case "$TELEMETRY_STATUS" in
      constrained)
        GATE_STATUS="PAUSE"
        GATE_EXIT=1
        REASONS+=("telemetry-constrained")
        ;;
      review)
        if [ "$GATE_EXIT" = "0" ]; then
          GATE_STATUS="REVIEW"
          GATE_EXIT=10
        fi
        REASONS+=("telemetry-review")
        ;;
      stable|"")
        :
        ;;
      *)
        if [ "$GATE_EXIT" = "0" ]; then
          GATE_STATUS="REVIEW"
          GATE_EXIT=10
        fi
        REASONS+=("telemetry-$TELEMETRY_STATUS")
        ;;
    esac
  else
    printf 'telemetry snapshot failed\n' > "$TELEMETRY_SUMMARY"
    TELEMETRY_STATUS="unavailable"
  fi
else
  printf 'telemetry helpers unavailable\n' > "$TELEMETRY_SUMMARY"
  TELEMETRY_STATUS="unavailable"
fi

echo "# Resource Gate"
echo
echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "target_path=$TARGET_PATH"
echo "gate_status=$GATE_STATUS"
echo "noise_status=$NOISE_STATUS"
echo "telemetry_status=$TELEMETRY_STATUS"
echo "noise_report=$NOISE_REPORT"
echo "telemetry_summary=$TELEMETRY_SUMMARY"
if [ "${#REASONS[@]}" -gt 0 ]; then
  echo "reasons=$(IFS=,; printf '%s' "${REASONS[*]}")"
else
  echo "reasons=none"
fi
echo

case "$GATE_STATUS" in
  READY)
    echo "recommendation=Machine looks healthy enough for a new heavy run."
    ;;
  REVIEW)
    echo "recommendation=Prefer caution: the machine is not clearly maxed out, but pressure signals deserve review before stacking more load."
    ;;
  PAUSE)
    echo "recommendation=Do not launch a new heavy run yet. Pause and switch to non-competing work until the machine settles."
    ;;
esac

if [ -f "$TELEMETRY_SUMMARY" ]; then
  echo
  echo "## Telemetry Warnings"
  sed -n 's/^warning=/warning: /p' "$TELEMETRY_SUMMARY" || true
fi

exit "$GATE_EXIT"
