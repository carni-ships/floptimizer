#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ROOT="${BENCH_CAPTURE_OUTPUT_ROOT:-$PWD/.bench-captures}"
LABEL=""
RUN_NOISE_CHECK=1
RUN_TELEMETRY=1
TELEMETRY_INTERVAL="${BENCH_CAPTURE_TELEMETRY_INTERVAL_SECONDS:-5}"
TELEMETRY_PID=""
COMMAND_PID=""
EXPECTED_DURATION=""
SOFT_CHECKPOINT=""
HARD_STOP=""
AGENT_NAME=""
HYPOTHESIS_BRANCH=""
WRITE_SCOPE=""
COORDINATION_LEDGER=""
COMPUTE_SLOT=""
DETACH=0
INTERNAL_RUNNER=0
RUN_DIR_OVERRIDE=""
RUN_MODE="foreground"
RUN_STATUS="preparing"
RUN_STATE_PATH=""
TERMINATE_SCRIPT_PATH=""
DETACHED_LAUNCH_LOG=""
COMMAND_EXIT_STATUS="not-run"
RUNNER_PID_VALUE=""

usage() {
  cat <<'EOF'
Usage:
  bench_capture.sh [--label NAME] [--output-root DIR] [--skip-noise-check] [--skip-telemetry] [--telemetry-interval SECONDS] [--detach] [--expected-duration TEXT] [--soft-checkpoint TEXT] [--hard-stop TEXT] [--coordination-ledger PATH] [--agent-name NAME] [--hypothesis-branch TEXT] [--write-scope TEXT] [--compute-slot TEXT] -- <command> [args...]

Examples:
  bench_capture.sh --label baseline -- hyperfine 'cargo test --release'
  bench_capture.sh --label nightly-sweep --detach -- hyperfine 'cargo run --release -- input.json'
  bench_capture.sh --output-root /tmp/perf-runs -- ./target/release/my-cli --input data.json

Creates a timestamped run directory and stores:
  - exact command
  - git context
  - system snapshot
  - machine noise report
  - broad system telemetry captured during the run
  - telemetry summary
  - experiment notes template
  - stdout/stderr
  - timing and exit status
  - run_state.env for detached supervision
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

sanitize_label() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9._-' '-' \
    | sed 's/^-*//; s/-*$//'
}

now_ms() {
  if have python3; then
    python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
    return
  fi

  if have perl; then
    perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
    return
  fi

  echo "$(( $(date +%s) * 1000 ))"
}

git_field() {
  local fallback="$1"
  shift

  if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    "$@" 2>/dev/null || printf '%s\n' "$fallback"
    return
  fi

  printf '%s\n' "$fallback"
}

write_run_state() {
  if [ -z "${RUN_STATE_PATH:-}" ]; then
    return
  fi

  {
    printf 'capture_dir=%q\n' "$RUN_DIR"
    printf 'run_mode=%q\n' "$RUN_MODE"
    printf 'run_status=%q\n' "$RUN_STATUS"
    printf 'runner_pid=%q\n' "${RUNNER_PID_VALUE:-$$}"
    printf 'command_pid=%q\n' "${COMMAND_PID:-}"
    printf 'command_exit_status=%q\n' "${COMMAND_EXIT_STATUS:-not-run}"
    printf 'command=%q\n' "${COMMAND_QUOTED:-}"
    printf 'stdout_path=%q\n' "$RUN_DIR/stdout.txt"
    printf 'stderr_path=%q\n' "$RUN_DIR/stderr.txt"
    printf 'telemetry_path=%q\n' "$RUN_DIR/telemetry.txt"
    printf 'notes_path=%q\n' "$RUN_DIR/notes.md"
    printf 'summary_path=%q\n' "$RUN_DIR/summary.txt"
    printf 'capture_env_path=%q\n' "$RUN_DIR/capture.env"
    printf 'rerun_path=%q\n' "$RUN_DIR/rerun.sh"
    printf 'terminate_script=%q\n' "${TERMINATE_SCRIPT_PATH:-}"
    printf 'detached_launch_log=%q\n' "${DETACHED_LAUNCH_LOG:-}"
    printf 'expected_duration=%q\n' "${EXPECTED_DURATION:-not-recorded}"
    printf 'soft_checkpoint=%q\n' "${SOFT_CHECKPOINT:-not-recorded}"
    printf 'hard_stop=%q\n' "${HARD_STOP:-not-recorded}"
    printf 'last_update_utc=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$RUN_STATE_PATH"
}

cleanup() {
  if [ -n "${TELEMETRY_PID:-}" ]; then
    kill "$TELEMETRY_PID" >/dev/null 2>&1 || true
    wait "$TELEMETRY_PID" >/dev/null 2>&1 || true
    TELEMETRY_PID=""
  fi

  if [ -n "${COMMAND_PID:-}" ]; then
    kill "$COMMAND_PID" >/dev/null 2>&1 || true
    wait "$COMMAND_PID" >/dev/null 2>&1 || true
    COMMAND_PID=""
  fi
}

handle_termination() {
  RUN_STATUS="terminated"
  COMMAND_EXIT_STATUS="terminated"
  write_run_state
  cleanup
  exit 143
}

trap cleanup EXIT
trap handle_termination TERM INT

while [ $# -gt 0 ]; do
  case "$1" in
    --label)
      if [ $# -lt 2 ]; then
        echo "--label requires a value" >&2
        exit 2
      fi
      LABEL="${2:-}"
      shift 2
      ;;
    --output-root)
      if [ $# -lt 2 ]; then
        echo "--output-root requires a value" >&2
        exit 2
      fi
      OUTPUT_ROOT="${2:-}"
      shift 2
      ;;
    --skip-noise-check)
      RUN_NOISE_CHECK=0
      shift
      ;;
    --skip-telemetry)
      RUN_TELEMETRY=0
      shift
      ;;
    --telemetry-interval)
      if [ $# -lt 2 ]; then
        echo "--telemetry-interval requires a value" >&2
        exit 2
      fi
      TELEMETRY_INTERVAL="$2"
      shift 2
      ;;
    --detach)
      DETACH=1
      RUN_MODE="background"
      shift
      ;;
    --expected-duration)
      if [ $# -lt 2 ]; then
        echo "--expected-duration requires a value" >&2
        exit 2
      fi
      EXPECTED_DURATION="$2"
      shift 2
      ;;
    --soft-checkpoint)
      if [ $# -lt 2 ]; then
        echo "--soft-checkpoint requires a value" >&2
        exit 2
      fi
      SOFT_CHECKPOINT="$2"
      shift 2
      ;;
    --hard-stop)
      if [ $# -lt 2 ]; then
        echo "--hard-stop requires a value" >&2
        exit 2
      fi
      HARD_STOP="$2"
      shift 2
      ;;
    --coordination-ledger)
      if [ $# -lt 2 ]; then
        echo "--coordination-ledger requires a value" >&2
        exit 2
      fi
      COORDINATION_LEDGER="$2"
      shift 2
      ;;
    --agent-name)
      if [ $# -lt 2 ]; then
        echo "--agent-name requires a value" >&2
        exit 2
      fi
      AGENT_NAME="$2"
      shift 2
      ;;
    --hypothesis-branch)
      if [ $# -lt 2 ]; then
        echo "--hypothesis-branch requires a value" >&2
        exit 2
      fi
      HYPOTHESIS_BRANCH="$2"
      shift 2
      ;;
    --write-scope)
      if [ $# -lt 2 ]; then
        echo "--write-scope requires a value" >&2
        exit 2
      fi
      WRITE_SCOPE="$2"
      shift 2
      ;;
    --compute-slot)
      if [ $# -lt 2 ]; then
        echo "--compute-slot requires a value" >&2
        exit 2
      fi
      COMPUTE_SLOT="$2"
      shift 2
      ;;
    --_runner)
      INTERNAL_RUNNER=1
      shift
      ;;
    --run-dir)
      if [ $# -lt 2 ]; then
        echo "--run-dir requires a value" >&2
        exit 2
      fi
      RUN_DIR_OVERRIDE="$2"
      shift 2
      ;;
    --run-mode)
      if [ $# -lt 2 ]; then
        echo "--run-mode requires a value" >&2
        exit 2
      fi
      RUN_MODE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ $# -eq 0 ]; then
  usage >&2
  exit 2
fi

if [ "$INTERNAL_RUNNER" = "1" ] && [ -z "$RUN_DIR_OVERRIDE" ]; then
  echo "--_runner requires --run-dir" >&2
  exit 2
fi

if [ "$INTERNAL_RUNNER" != "1" ]; then
  mkdir -p "$OUTPUT_ROOT"
  OUTPUT_ROOT="$(cd "$OUTPUT_ROOT" && pwd)"
fi

if [ -n "$COORDINATION_LEDGER" ] && [ -e "$COORDINATION_LEDGER" ]; then
  COORDINATION_LEDGER="$(cd "$(dirname "$COORDINATION_LEDGER")" && pwd)/$(basename "$COORDINATION_LEDGER")"
fi

TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TIMESTAMP_SLUG="$(date -u +%Y%m%dT%H%M%SZ)"
LABEL_SLUG=""
if [ -n "$LABEL" ]; then
  LABEL_SLUG="$(sanitize_label "$LABEL")"
fi

RUN_NAME="$TIMESTAMP_SLUG"
if [ -n "$LABEL_SLUG" ]; then
  RUN_NAME="${RUN_NAME}_${LABEL_SLUG}"
fi

if [ "$INTERNAL_RUNNER" = "1" ]; then
  mkdir -p "$RUN_DIR_OVERRIDE"
  RUN_DIR="$(cd "$RUN_DIR_OVERRIDE" && pwd)"
else
  RUN_DIR="${OUTPUT_ROOT%/}/$RUN_NAME"
  if [ -e "$RUN_DIR" ]; then
    RUN_DIR="${RUN_DIR}_$$"
  fi
  mkdir -p "$RUN_DIR"
fi

COMMAND_QUOTED="$(printf '%q ' "$@")"
COMMAND_QUOTED="${COMMAND_QUOTED% }"
HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown\n')"
GIT_ROOT="$(git_field "not-a-git-repo" git rev-parse --show-toplevel)"
GIT_BRANCH="$(git_field "detached-or-unavailable" git rev-parse --abbrev-ref HEAD)"
GIT_HEAD="$(git_field "unavailable" git rev-parse HEAD)"
RUN_STATE_PATH="$RUN_DIR/run_state.env"
TERMINATE_SCRIPT_PATH="$RUN_DIR/terminate.sh"
DETACHED_LAUNCH_LOG="$RUN_DIR/detached_runner.log"
GIT_DIRTY="unknown"
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
    GIT_DIRTY="yes"
  else
    GIT_DIRTY="no"
  fi
fi

cat > "$TERMINATE_SCRIPT_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

STATE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/run_state.env"
if [ ! -f "$STATE_PATH" ]; then
  echo "Missing run_state.env next to terminate.sh" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$STATE_PATH"

if [ -z "${runner_pid:-}" ]; then
  echo "runner_pid missing from $STATE_PATH" >&2
  exit 1
fi

kill "$runner_pid"
EOF
chmod +x "$TERMINATE_SCRIPT_PATH"

if [ "$DETACH" = "1" ] && [ "$INTERNAL_RUNNER" != "1" ]; then
  RUN_STATUS="launching"
  write_run_state

  RUNNER_CMD=(bash "$0" --_runner --run-dir "$RUN_DIR" --run-mode background)
  if [ -n "$LABEL" ]; then
    RUNNER_CMD+=(--label "$LABEL")
  fi
  if [ "$RUN_NOISE_CHECK" = "0" ]; then
    RUNNER_CMD+=(--skip-noise-check)
  fi
  if [ "$RUN_TELEMETRY" = "0" ]; then
    RUNNER_CMD+=(--skip-telemetry)
  fi
  RUNNER_CMD+=(--telemetry-interval "$TELEMETRY_INTERVAL")
  if [ -n "$EXPECTED_DURATION" ]; then
    RUNNER_CMD+=(--expected-duration "$EXPECTED_DURATION")
  fi
  if [ -n "$SOFT_CHECKPOINT" ]; then
    RUNNER_CMD+=(--soft-checkpoint "$SOFT_CHECKPOINT")
  fi
  if [ -n "$HARD_STOP" ]; then
    RUNNER_CMD+=(--hard-stop "$HARD_STOP")
  fi
  if [ -n "$COORDINATION_LEDGER" ]; then
    RUNNER_CMD+=(--coordination-ledger "$COORDINATION_LEDGER")
  fi
  if [ -n "$AGENT_NAME" ]; then
    RUNNER_CMD+=(--agent-name "$AGENT_NAME")
  fi
  if [ -n "$HYPOTHESIS_BRANCH" ]; then
    RUNNER_CMD+=(--hypothesis-branch "$HYPOTHESIS_BRANCH")
  fi
  if [ -n "$WRITE_SCOPE" ]; then
    RUNNER_CMD+=(--write-scope "$WRITE_SCOPE")
  fi
  if [ -n "$COMPUTE_SLOT" ]; then
    RUNNER_CMD+=(--compute-slot "$COMPUTE_SLOT")
  fi
  RUNNER_CMD+=(-- "$@")

  if have nohup; then
    nohup "${RUNNER_CMD[@]}" < /dev/null > "$DETACHED_LAUNCH_LOG" 2>&1 &
  else
    "${RUNNER_CMD[@]}" < /dev/null > "$DETACHED_LAUNCH_LOG" 2>&1 &
  fi
  DETACHED_PID=$!
  RUNNER_PID_VALUE="$DETACHED_PID"
  printf '%s\n' "$DETACHED_PID" > "$RUN_DIR/runner.pid"
  RUN_STATUS="running"
  write_run_state
  printf 'capture_dir=%s\n' "$RUN_DIR"
  printf 'run_mode=%s\n' "$RUN_MODE"
  printf 'runner_pid=%s\n' "$DETACHED_PID"
  printf 'state_path=%s\n' "$RUN_STATE_PATH"
  printf 'summary=%s\n' "$RUN_DIR/summary.txt"
  printf 'terminate_script=%s\n' "$TERMINATE_SCRIPT_PATH"
  exit 0
fi

printf '%s\n' "$COMMAND_QUOTED" > "$RUN_DIR/command.txt"

cat > "$RUN_DIR/rerun.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cd $(printf '%q' "$PWD")
$COMMAND_QUOTED
EOF
chmod +x "$RUN_DIR/rerun.sh"

if [ -f "$SCRIPT_DIR/system_snapshot.sh" ]; then
  bash "$SCRIPT_DIR/system_snapshot.sh" > "$RUN_DIR/system_snapshot.txt" 2>&1 || true
else
  printf 'system_snapshot.sh not found at %s\n' "$SCRIPT_DIR/system_snapshot.sh" > "$RUN_DIR/system_snapshot.txt"
fi

NOISE_STATUS="SKIPPED"
NOISE_EXIT_STATUS=0
if [ "$RUN_NOISE_CHECK" = "1" ] && [ -f "$SCRIPT_DIR/machine_noise_check.sh" ]; then
  if bash "$SCRIPT_DIR/machine_noise_check.sh" > "$RUN_DIR/machine_noise.txt" 2>&1; then
    NOISE_STATUS="QUIET"
    NOISE_EXIT_STATUS=0
  else
    NOISE_EXIT_STATUS=$?
    NOISE_STATUS="NOISY"
  fi
else
  printf 'machine noise check skipped\n' > "$RUN_DIR/machine_noise.txt"
fi

TELEMETRY_STATUS="SKIPPED"
if [ "$RUN_TELEMETRY" = "1" ] && [ -f "$SCRIPT_DIR/profile_telemetry.sh" ]; then
  TELEMETRY_STATUS="RUNNING"
  bash "$SCRIPT_DIR/profile_telemetry.sh" \
    --interval "$TELEMETRY_INTERVAL" \
    --target-path "$PWD" \
    > "$RUN_DIR/telemetry.txt" 2>&1 &
  TELEMETRY_PID=$!
else
  printf 'profiling telemetry skipped\n' > "$RUN_DIR/telemetry.txt"
fi

cat > "$RUN_DIR/notes.md" <<EOF
# Experiment Notes

- label: ${LABEL_SLUG:-none}
- timestamp_utc: $TIMESTAMP_UTC
- command: \`$COMMAND_QUOTED\`
- git_head: \`$GIT_HEAD\`
- noise_status: $NOISE_STATUS
- run_mode: $RUN_MODE

## Coordination Context

- coordination_ledger: ${COORDINATION_LEDGER:-none}
- agent_name: ${AGENT_NAME:-none}
- hypothesis_branch: ${HYPOTHESIS_BRANCH:-none}
- write_scope: ${WRITE_SCOPE:-none}
- compute_slot: ${COMPUTE_SLOT:-not-recorded}

## Wait Budget

- expected_duration: ${EXPECTED_DURATION:-not-recorded}
- soft_checkpoint: ${SOFT_CHECKPOINT:-not-recorded}
- hard_stop: ${HARD_STOP:-not-recorded}
- progress_signals_checked:
- budget_outcome: completed | terminated | retried | timed-out
- termination_reason:

## Hypothesis

-

## Expected Mechanism

-

## Prerequisites Or Assumptions

-

## Result Summary

-

## Why It Helped Or Did Not

-

## Confounders

-

## Unblockers

-

## Revisit Condition

-

## Environment-Specific Tuning Notes

- hardware_profile:
- firmware_or_driver:
- tuned_parameters:
- best_region:
- cliff_points:
- impact_summary:
- direction_type:
- portable_principle:
- portability_notes:

## Reusable Optimization Trick Candidate

- trick_name:
- symptoms_or_problem_shape:
- mechanism:
- best_for:
- not_for:
- prerequisites:
- expected_upside:
- cost:
- risk:
- portable_principle:
- machine_specific_tuning:
- evidence_level:
- confidence:
- related_exemplars:
- candidate_for_catalog: yes | no
- promotion_notes:

## Paper-Ready Finding

- finding_title:
- claim:
- finding_type: positive | negative | enabling | mixed
- novelty_class: novel synthesis | adaptation | replication | unclear
- bottleneck_class:
- intervention:
- baseline_condition:
- improved_condition:
- primary_metric:
- effect_size:
- secondary_effects:
- mechanism:
- operating_region:
- prerequisites:
- caveats:
- reproducibility_artifacts:
- figure_or_table_suggestion:
- paper_candidate: yes | no

## Skill Feedback

- guidance_that_helped:
- missing_guidance:
- tool_or_script_gap:
- trigger_issue:
- candidate_update:
EOF

START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_MS="$(now_ms)"
RUN_STATUS="running"
RUNNER_PID_VALUE="$$"
write_run_state

set +e
"$@" > "$RUN_DIR/stdout.txt" 2> "$RUN_DIR/stderr.txt" &
COMMAND_PID=$!
write_run_state
wait "$COMMAND_PID"
COMMAND_EXIT_STATUS=$?
COMMAND_PID=""
set -e
END_MS="$(now_ms)"
END_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ELAPSED_MS="$((END_MS - START_MS))"

if [ -n "${TELEMETRY_PID:-}" ]; then
  kill "$TELEMETRY_PID" >/dev/null 2>&1 || true
  wait "$TELEMETRY_PID" >/dev/null 2>&1 || true
  TELEMETRY_PID=""
  TELEMETRY_STATUS="CAPTURED"
fi

TELEMETRY_SUMMARY_STATUS="SKIPPED"
TELEMETRY_SUMMARY_PATH="$RUN_DIR/telemetry_summary.txt"
if [ "$TELEMETRY_STATUS" = "CAPTURED" ] && [ -f "$SCRIPT_DIR/telemetry_summary.sh" ]; then
  if bash "$SCRIPT_DIR/telemetry_summary.sh" "$RUN_DIR/telemetry.txt" > "$TELEMETRY_SUMMARY_PATH" 2>&1; then
    TELEMETRY_SUMMARY_STATUS="CAPTURED"
  else
  TELEMETRY_SUMMARY_STATUS="ERROR"
  fi
else
  printf 'telemetry summary skipped\n' > "$TELEMETRY_SUMMARY_PATH"
fi

if [ "$COMMAND_EXIT_STATUS" = "0" ]; then
  RUN_STATUS="completed"
else
  RUN_STATUS="failed"
fi

{
  printf 'timestamp_utc=%q\n' "$TIMESTAMP_UTC"
  printf 'run_dir=%q\n' "$RUN_DIR"
  printf 'label=%q\n' "${LABEL_SLUG:-none}"
  printf 'cwd=%q\n' "$PWD"
  printf 'hostname=%q\n' "$HOSTNAME_VALUE"
  printf 'command=%q\n' "$COMMAND_QUOTED"
  printf 'run_mode=%q\n' "$RUN_MODE"
  printf 'start_utc=%q\n' "$START_UTC"
  printf 'end_utc=%q\n' "$END_UTC"
  printf 'elapsed_ms=%q\n' "$ELAPSED_MS"
  printf 'exit_status=%q\n' "$COMMAND_EXIT_STATUS"
  printf 'noise_status=%q\n' "$NOISE_STATUS"
  printf 'noise_exit_status=%q\n' "$NOISE_EXIT_STATUS"
  printf 'telemetry_status=%q\n' "$TELEMETRY_STATUS"
  printf 'telemetry_path=%q\n' "$RUN_DIR/telemetry.txt"
  printf 'telemetry_summary_status=%q\n' "$TELEMETRY_SUMMARY_STATUS"
  printf 'telemetry_summary_path=%q\n' "$TELEMETRY_SUMMARY_PATH"
  printf 'state_path=%q\n' "$RUN_STATE_PATH"
  printf 'terminate_script=%q\n' "$TERMINATE_SCRIPT_PATH"
  printf 'notes_path=%q\n' "$RUN_DIR/notes.md"
  printf 'expected_duration=%q\n' "${EXPECTED_DURATION:-not-recorded}"
  printf 'soft_checkpoint=%q\n' "${SOFT_CHECKPOINT:-not-recorded}"
  printf 'hard_stop=%q\n' "${HARD_STOP:-not-recorded}"
  printf 'coordination_ledger=%q\n' "${COORDINATION_LEDGER:-none}"
  printf 'agent_name=%q\n' "${AGENT_NAME:-none}"
  printf 'hypothesis_branch=%q\n' "${HYPOTHESIS_BRANCH:-none}"
  printf 'write_scope=%q\n' "${WRITE_SCOPE:-none}"
  printf 'compute_slot=%q\n' "${COMPUTE_SLOT:-not-recorded}"
  printf 'git_root=%q\n' "$GIT_ROOT"
  printf 'git_branch=%q\n' "$GIT_BRANCH"
  printf 'git_head=%q\n' "$GIT_HEAD"
  printf 'git_dirty=%q\n' "$GIT_DIRTY"
} > "$RUN_DIR/capture.env"

cat > "$RUN_DIR/summary.txt" <<EOF
# Benchmark Capture Summary

timestamp_utc=$TIMESTAMP_UTC
run_dir=$RUN_DIR
label=${LABEL_SLUG:-none}
cwd=$PWD
hostname=$HOSTNAME_VALUE
command=$COMMAND_QUOTED
start_utc=$START_UTC
end_utc=$END_UTC
elapsed_ms=$ELAPSED_MS
exit_status=$COMMAND_EXIT_STATUS
noise_status=$NOISE_STATUS
noise_exit_status=$NOISE_EXIT_STATUS
telemetry_status=$TELEMETRY_STATUS
telemetry_path=$RUN_DIR/telemetry.txt
telemetry_summary_status=$TELEMETRY_SUMMARY_STATUS
telemetry_summary_path=$TELEMETRY_SUMMARY_PATH
expected_duration=${EXPECTED_DURATION:-not-recorded}
soft_checkpoint=${SOFT_CHECKPOINT:-not-recorded}
hard_stop=${HARD_STOP:-not-recorded}
coordination_ledger=${COORDINATION_LEDGER:-none}
agent_name=${AGENT_NAME:-none}
hypothesis_branch=${HYPOTHESIS_BRANCH:-none}
write_scope=${WRITE_SCOPE:-none}
compute_slot=${COMPUTE_SLOT:-not-recorded}
git_root=$GIT_ROOT
git_branch=$GIT_BRANCH
git_head=$GIT_HEAD
git_dirty=$GIT_DIRTY
run_mode=$RUN_MODE
state_path=$RUN_STATE_PATH
terminate_script=$TERMINATE_SCRIPT_PATH

artifacts:
- command.txt
- capture.env
- summary.txt
- run_state.env
- notes.md
- stdout.txt
- stderr.txt
- system_snapshot.txt
- machine_noise.txt
- telemetry.txt
- telemetry_summary.txt
- rerun.sh
EOF

printf 'capture_dir=%s\n' "$RUN_DIR"
printf 'run_mode=%s\n' "$RUN_MODE"
printf 'state_path=%s\n' "$RUN_STATE_PATH"
printf 'summary=%s\n' "$RUN_DIR/summary.txt"
printf 'terminate_script=%s\n' "$TERMINATE_SCRIPT_PATH"
write_run_state
printf 'exit_status=%s\n' "$COMMAND_EXIT_STATUS"
printf 'elapsed_ms=%s\n' "$ELAPSED_MS"
printf 'noise_status=%s\n' "$NOISE_STATUS"
printf 'telemetry_status=%s\n' "$TELEMETRY_STATUS"
printf 'telemetry=%s\n' "$RUN_DIR/telemetry.txt"
printf 'telemetry_summary=%s\n' "$TELEMETRY_SUMMARY_PATH"
printf 'notes=%s\n' "$RUN_DIR/notes.md"
printf 'summary=%s\n' "$RUN_DIR/summary.txt"

exit "$COMMAND_EXIT_STATUS"
