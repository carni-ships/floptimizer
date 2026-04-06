#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ROOT="${PERF_SESSION_OUTPUT_ROOT:-$PWD/.perf-sessions}"
ROOT="."
LABEL=""
REPORT_TITLE="Performance Session Report"
RUN_NOISE_CHECK=1
RUN_TOOL_SCOUT=1
DETACH_BASELINE=0
EXPECTED_DURATION=""
SOFT_CHECKPOINT=""
HARD_STOP=""
BOOTSTRAP_COORDINATION=0
COORDINATION_LEDGER=""
CAMPAIGN_FILE=""
CAMPAIGN_LEDGER=""
AGENT_NAME=""
HYPOTHESIS_BRANCH=""
WRITE_SCOPE=""
COMPUTE_SLOT=""

usage() {
  cat <<'EOF'
Usage:
  perf_session_bootstrap.sh [--label NAME] [--root DIR] [--output-root DIR] [--report-title TITLE] [--skip-noise-check] [--skip-tool-scout] [--detach-baseline] [--with-coordination-ledger] [--coordination-ledger PATH] [--campaign-file PATH] [--campaign-ledger PATH] [--agent-name NAME] [--hypothesis-branch TEXT] [--write-scope TEXT] [--compute-slot TEXT] [--expected-duration TEXT] [--soft-checkpoint TEXT] [--hard-stop TEXT] [-- <baseline command> ...]

Examples:
  perf_session_bootstrap.sh --label api-p99 --root .
  perf_session_bootstrap.sh --label cli-startup --root . -- hyperfine 'cargo run --release -- --help'
  perf_session_bootstrap.sh --label nightly --root . --detach-baseline -- hyperfine 'cargo run --release -- input.json'

Creates a timestamped session directory containing:
  - system snapshot
  - broad telemetry snapshot
  - machine noise report
  - tool scout report
  - optional baseline benchmark capture
  - starter performance report template
  - session metadata for later continuation
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

while [ $# -gt 0 ]; do
  case "$1" in
    --label)
      if [ $# -lt 2 ]; then
        echo "--label requires a value" >&2
        exit 2
      fi
      LABEL="$2"
      shift 2
      ;;
    --root)
      if [ $# -lt 2 ]; then
        echo "--root requires a value" >&2
        exit 2
      fi
      ROOT="$2"
      shift 2
      ;;
    --output-root)
      if [ $# -lt 2 ]; then
        echo "--output-root requires a value" >&2
        exit 2
      fi
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --report-title)
      if [ $# -lt 2 ]; then
        echo "--report-title requires a value" >&2
        exit 2
      fi
      REPORT_TITLE="$2"
      shift 2
      ;;
    --skip-noise-check)
      RUN_NOISE_CHECK=0
      shift
      ;;
    --skip-tool-scout)
      RUN_TOOL_SCOUT=0
      shift
      ;;
    --detach-baseline)
      DETACH_BASELINE=1
      shift
      ;;
    --with-coordination-ledger)
      BOOTSTRAP_COORDINATION=1
      shift
      ;;
    --coordination-ledger)
      if [ $# -lt 2 ]; then
        echo "--coordination-ledger requires a value" >&2
        exit 2
      fi
      COORDINATION_LEDGER="$2"
      shift 2
      ;;
    --campaign-file)
      if [ $# -lt 2 ]; then
        echo "--campaign-file requires a value" >&2
        exit 2
      fi
      CAMPAIGN_FILE="$2"
      shift 2
      ;;
    --campaign-ledger)
      if [ $# -lt 2 ]; then
        echo "--campaign-ledger requires a value" >&2
        exit 2
      fi
      CAMPAIGN_LEDGER="$2"
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

ROOT_ABS="$(cd "$ROOT" && pwd)"
mkdir -p "$OUTPUT_ROOT"
OUTPUT_ROOT="$(cd "$OUTPUT_ROOT" && pwd)"

if [ -n "$COORDINATION_LEDGER" ] && [[ "$COORDINATION_LEDGER" != /* ]]; then
  COORDINATION_LEDGER="$ROOT_ABS/$COORDINATION_LEDGER"
fi
if [ -n "$CAMPAIGN_FILE" ] && [[ "$CAMPAIGN_FILE" != /* ]]; then
  CAMPAIGN_FILE="$ROOT_ABS/$CAMPAIGN_FILE"
fi
if [ -n "$CAMPAIGN_LEDGER" ] && [[ "$CAMPAIGN_LEDGER" != /* ]]; then
  CAMPAIGN_LEDGER="$ROOT_ABS/$CAMPAIGN_LEDGER"
fi
if [ -z "$CAMPAIGN_FILE" ] && [ -f "$ROOT_ABS/.perf-campaign/campaign.md" ]; then
  CAMPAIGN_FILE="$ROOT_ABS/.perf-campaign/campaign.md"
fi
if [ -z "$CAMPAIGN_LEDGER" ] && [ -f "$ROOT_ABS/.perf-campaign/results.tsv" ]; then
  CAMPAIGN_LEDGER="$ROOT_ABS/.perf-campaign/results.tsv"
fi

TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TIMESTAMP_SLUG="$(date -u +%Y%m%dT%H%M%SZ)"
LABEL_SLUG=""
if [ -n "$LABEL" ]; then
  LABEL_SLUG="$(sanitize_label "$LABEL")"
fi

SESSION_NAME="$TIMESTAMP_SLUG"
if [ -n "$LABEL_SLUG" ]; then
  SESSION_NAME="${SESSION_NAME}_${LABEL_SLUG}"
fi

SESSION_DIR="${OUTPUT_ROOT%/}/$SESSION_NAME"
if [ -e "$SESSION_DIR" ]; then
  SESSION_DIR="${SESSION_DIR}_$$"
fi

mkdir -p "$SESSION_DIR/captures"

NOISE_STATUS="SKIPPED"
NOISE_EXIT_STATUS=0
BASELINE_CAPTURE_DIR=""
BASELINE_EXIT_STATUS="not-run"
BASELINE_SUMMARY=""
BASELINE_STATE_PATH=""
BASELINE_RUNNER_PID=""
BASELINE_RUN_MODE="not-run"
BASELINE_CAMPAIGN_ENTRY_PATH=""
BASELINE_CAMPAIGN_APPEND_STATUS="not-run"
TELEMETRY_SNAPSHOT_SUMMARY="$SESSION_DIR/telemetry_snapshot_summary.txt"
RESOURCE_GATE_STATUS="not-run"
RESOURCE_GATE_REPORT="$SESSION_DIR/resource_gate.txt"

if [ -f "$SCRIPT_DIR/system_snapshot.sh" ]; then
  (
    cd "$ROOT_ABS"
    bash "$SCRIPT_DIR/system_snapshot.sh"
  ) > "$SESSION_DIR/system_snapshot.txt" 2>&1 || true
else
  printf 'system_snapshot.sh not found at %s\n' "$SCRIPT_DIR/system_snapshot.sh" > "$SESSION_DIR/system_snapshot.txt"
fi

if [ -f "$SCRIPT_DIR/profile_telemetry.sh" ]; then
  (
    cd "$ROOT_ABS"
    bash "$SCRIPT_DIR/profile_telemetry.sh" --once --target-path "$ROOT_ABS"
  ) > "$SESSION_DIR/telemetry_snapshot.txt" 2>&1 || true
else
  printf 'profile_telemetry.sh not found at %s\n' "$SCRIPT_DIR/profile_telemetry.sh" > "$SESSION_DIR/telemetry_snapshot.txt"
fi

if [ -f "$SCRIPT_DIR/telemetry_summary.sh" ]; then
  bash "$SCRIPT_DIR/telemetry_summary.sh" "$SESSION_DIR/telemetry_snapshot.txt" > "$TELEMETRY_SNAPSHOT_SUMMARY" 2>&1 || true
else
  printf 'telemetry summary helper not found at %s\n' "$SCRIPT_DIR/telemetry_summary.sh" > "$TELEMETRY_SNAPSHOT_SUMMARY"
fi

if [ "$BOOTSTRAP_COORDINATION" = "1" ] && [ -f "$SCRIPT_DIR/coordination_bootstrap.sh" ]; then
  COORD_CMD=(bash "$SCRIPT_DIR/coordination_bootstrap.sh" --root "$ROOT_ABS")
  if [ -n "$COORDINATION_LEDGER" ]; then
    COORD_CMD+=(--ledger "$COORDINATION_LEDGER")
  fi
  if [ -n "$AGENT_NAME" ]; then
    COORD_CMD+=(--agent "$AGENT_NAME")
  fi
  if [ -n "$HYPOTHESIS_BRANCH" ]; then
    COORD_CMD+=(--hypothesis-branch "$HYPOTHESIS_BRANCH")
  fi
  if [ -n "$WRITE_SCOPE" ]; then
    COORD_CMD+=(--write-scope "$WRITE_SCOPE")
  fi
  if [ -n "$COMPUTE_SLOT" ]; then
    COORD_CMD+=(--compute-task "$COMPUTE_SLOT")
  fi
  if [ -n "$EXPECTED_DURATION" ]; then
    COORD_CMD+=(--expected-duration "$EXPECTED_DURATION")
  fi
  if [ -n "$SOFT_CHECKPOINT" ]; then
    COORD_CMD+=(--soft-checkpoint "$SOFT_CHECKPOINT")
  fi
  if [ -n "$HARD_STOP" ]; then
    COORD_CMD+=(--hard-stop "$HARD_STOP")
  fi

  COORD_OUTPUT="$("${COORD_CMD[@]}")"
  COORDINATION_LEDGER="$(printf '%s\n' "$COORD_OUTPUT" | sed -n 's/^ledger=//p' | tail -n 1)"
fi

if [ "$RUN_NOISE_CHECK" = "1" ] && [ -f "$SCRIPT_DIR/machine_noise_check.sh" ]; then
  if (
    cd "$ROOT_ABS"
    bash "$SCRIPT_DIR/machine_noise_check.sh"
  ) > "$SESSION_DIR/machine_noise.txt" 2>&1; then
    NOISE_STATUS="QUIET"
    NOISE_EXIT_STATUS=0
  else
    NOISE_EXIT_STATUS=$?
    NOISE_STATUS="NOISY"
  fi
else
  printf 'machine noise check skipped\n' > "$SESSION_DIR/machine_noise.txt"
fi

if [ "$RUN_TOOL_SCOUT" = "1" ] && [ -f "$SCRIPT_DIR/tool_scout.sh" ]; then
  TOOL_SCOUT_ENV=()
  if [ "$RUN_NOISE_CHECK" = "1" ]; then
    TOOL_SCOUT_ENV=("TOOL_SCOUT_RUN_NOISE_CHECK=0")
  fi
  (
    cd "$ROOT_ABS"
    env "${TOOL_SCOUT_ENV[@]}" bash "$SCRIPT_DIR/tool_scout.sh" "$ROOT_ABS"
  ) > "$SESSION_DIR/tool_scout.txt" 2>&1 || true
else
  printf 'tool scout skipped\n' > "$SESSION_DIR/tool_scout.txt"
fi

if [ -f "$SCRIPT_DIR/resource_gate.sh" ]; then
  set +e
  (
    cd "$ROOT_ABS"
    bash "$SCRIPT_DIR/resource_gate.sh" --target-path "$ROOT_ABS"
  ) > "$RESOURCE_GATE_REPORT" 2>&1
  RESOURCE_GATE_EXIT=$?
  set -e
  RESOURCE_GATE_STATUS="$(sed -n 's/^gate_status=//p' "$RESOURCE_GATE_REPORT" | tail -n 1)"
  if [ -z "$RESOURCE_GATE_STATUS" ]; then
    case "$RESOURCE_GATE_EXIT" in
      0) RESOURCE_GATE_STATUS="READY" ;;
      10) RESOURCE_GATE_STATUS="REVIEW" ;;
      *) RESOURCE_GATE_STATUS="PAUSE" ;;
    esac
  fi
else
  printf 'resource gate helper not found at %s\n' "$SCRIPT_DIR/resource_gate.sh" > "$RESOURCE_GATE_REPORT"
fi

if [ $# -gt 0 ] && [ -f "$SCRIPT_DIR/bench_capture.sh" ]; then
  BENCH_CMD=(bash "$SCRIPT_DIR/bench_capture.sh" --output-root "$SESSION_DIR/captures" --label baseline)
  if [ "$DETACH_BASELINE" = "1" ]; then
    BENCH_CMD+=(--detach)
  fi
  if [ "$RUN_NOISE_CHECK" = "0" ]; then
    BENCH_CMD+=(--skip-noise-check)
  fi
  if [ -n "$EXPECTED_DURATION" ]; then
    BENCH_CMD+=(--expected-duration "$EXPECTED_DURATION")
  fi
  if [ -n "$SOFT_CHECKPOINT" ]; then
    BENCH_CMD+=(--soft-checkpoint "$SOFT_CHECKPOINT")
  fi
  if [ -n "$HARD_STOP" ]; then
    BENCH_CMD+=(--hard-stop "$HARD_STOP")
  fi
  if [ -n "$COORDINATION_LEDGER" ]; then
    BENCH_CMD+=(--coordination-ledger "$COORDINATION_LEDGER")
  fi
  if [ -n "$CAMPAIGN_FILE" ]; then
    BENCH_CMD+=(--campaign-file "$CAMPAIGN_FILE")
  fi
  if [ -n "$CAMPAIGN_LEDGER" ]; then
    BENCH_CMD+=(--campaign-ledger "$CAMPAIGN_LEDGER")
  fi
  if [ -n "$AGENT_NAME" ]; then
    BENCH_CMD+=(--agent-name "$AGENT_NAME")
  fi
  if [ -n "$HYPOTHESIS_BRANCH" ]; then
    BENCH_CMD+=(--hypothesis-branch "$HYPOTHESIS_BRANCH")
  fi
  if [ -n "$WRITE_SCOPE" ]; then
    BENCH_CMD+=(--write-scope "$WRITE_SCOPE")
  fi
  if [ -n "$COMPUTE_SLOT" ]; then
    BENCH_CMD+=(--compute-slot "$COMPUTE_SLOT")
  fi
  BENCH_CMD+=(-- "$@")

  set +e
  BASELINE_OUTPUT="$(
    cd "$ROOT_ABS" &&
    "${BENCH_CMD[@]}"
  )"
  BASELINE_STATUS=$?
  set -e

  printf '%s\n' "$BASELINE_OUTPUT" > "$SESSION_DIR/baseline_capture_console.txt"
  BASELINE_EXIT_STATUS="$BASELINE_STATUS"
  BASELINE_CAPTURE_DIR="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^capture_dir=//p' | tail -n 1)"
  BASELINE_SUMMARY="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^summary=//p' | tail -n 1)"
  BASELINE_STATE_PATH="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^state_path=//p' | tail -n 1)"
  BASELINE_RUNNER_PID="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^runner_pid=//p' | tail -n 1)"
  BASELINE_RUN_MODE="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^run_mode=//p' | tail -n 1)"
  BASELINE_CAMPAIGN_ENTRY_PATH="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^campaign_entry_path=//p' | tail -n 1)"
  BASELINE_CAMPAIGN_APPEND_STATUS="$(printf '%s\n' "$BASELINE_OUTPUT" | sed -n 's/^campaign_append_status=//p' | tail -n 1)"
  if [ "$DETACH_BASELINE" = "1" ] && [ "$BASELINE_STATUS" = "0" ]; then
    BASELINE_EXIT_STATUS="detached"
  fi
else
  printf 'baseline capture not requested\n' > "$SESSION_DIR/baseline_capture_console.txt"
fi

cat > "$SESSION_DIR/starter-report.md" <<EOF
# $REPORT_TITLE

## Session

- timestamp_utc: $TIMESTAMP_UTC
- label: ${LABEL_SLUG:-none}
- repo_root: $ROOT_ABS
- session_dir: $SESSION_DIR
- machine_noise_status: $NOISE_STATUS
- resource_gate_status: ${RESOURCE_GATE_STATUS:-not-run}
- baseline_exit_status: $BASELINE_EXIT_STATUS
- baseline_run_mode: ${BASELINE_RUN_MODE:-not-run}
- coordination_ledger: ${COORDINATION_LEDGER:-none}
- campaign_ledger: ${CAMPAIGN_LEDGER:-none}

## Artifacts

- system_snapshot: $SESSION_DIR/system_snapshot.txt
- telemetry_snapshot: $SESSION_DIR/telemetry_snapshot.txt
- telemetry_snapshot_summary: $TELEMETRY_SNAPSHOT_SUMMARY
- machine_noise: $SESSION_DIR/machine_noise.txt
- resource_gate: $RESOURCE_GATE_REPORT
- tool_scout: $SESSION_DIR/tool_scout.txt
- baseline_capture_console: $SESSION_DIR/baseline_capture_console.txt
- baseline_capture_dir: ${BASELINE_CAPTURE_DIR:-not-run}
- baseline_summary: ${BASELINE_SUMMARY:-not-run}
- baseline_state_path: ${BASELINE_STATE_PATH:-not-run}
- baseline_campaign_entry_path: ${BASELINE_CAMPAIGN_ENTRY_PATH:-not-run}
- campaign_file: ${CAMPAIGN_FILE:-none}
- campaign_ledger: ${CAMPAIGN_LEDGER:-none}

## Goal

-

## Workload

-

## Correctness Checks

-

## Validation Gate

- correctness_checks_run:
- validation_status: passed | failed | not-run | blocked
- missing_or_blocked_checks:
- blocked_reason:
- completion_status: complete | implementation-only | blocked-on-validation

## Initial Signals

- bottleneck clues:
- duplicate work clues:
- dependency clues:
- unconventional bottleneck clues:
- machine noise caveats:

## Coordination Context

- coordination_ledger: ${COORDINATION_LEDGER:-none}
- agent_name: ${AGENT_NAME:-none}
- hypothesis_branch: ${HYPOTHESIS_BRANCH:-none}
- write_scope: ${WRITE_SCOPE:-none}
- compute_slot: ${COMPUTE_SLOT:-not-recorded}

## Campaign Context

- campaign_file: ${CAMPAIGN_FILE:-none}
- campaign_ledger: ${CAMPAIGN_LEDGER:-none}
- campaign_append_status: ${BASELINE_CAMPAIGN_APPEND_STATUS:-pending | appended | skipped}
- campaign_entry_path: ${BASELINE_CAMPAIGN_ENTRY_PATH:-baseline capture entry file or none}
- campaign_next_step: append the baseline or next serious run to the ledger with append_campaign_result.sh

## Wait Budget

- expected_duration: ${EXPECTED_DURATION:-not-recorded}
- soft_checkpoint: ${SOFT_CHECKPOINT:-not-recorded}
- hard_stop: ${HARD_STOP:-not-recorded}
- progress_signals_checked:
- budget_outcome: completed | terminated | retried | timed-out
- termination_reason:

## Hypothesis Queue

- ranked ideas:
- speculative branches:
- blocked branches:

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

## Baseline

-

## Next Experiments

-

## Risks And Guardrails

-

## Checkpoint Decision

- checkpoint_type: knowledge | code | both
- checkpoint_reason:
- preservation_class: rollback-baseline | winner | fallback | oracle | non-winning-correct | enabler | comparison-point
- previous_good_branch_or_worktree:
- previous_good_commit_ref:
- preserved_branch_or_worktree:
- commit_ref:
- rerun_or_rebuild_hint:

## Skill Feedback

- guidance_that_helped:
- missing_guidance:
- tool_or_script_gap:
- trigger_issue:
- candidate_update:
EOF

{
  printf 'timestamp_utc=%q\n' "$TIMESTAMP_UTC"
  printf 'session_dir=%q\n' "$SESSION_DIR"
  printf 'repo_root=%q\n' "$ROOT_ABS"
  printf 'label=%q\n' "${LABEL_SLUG:-none}"
  printf 'noise_status=%q\n' "$NOISE_STATUS"
  printf 'noise_exit_status=%q\n' "$NOISE_EXIT_STATUS"
  printf 'telemetry_snapshot=%q\n' "$SESSION_DIR/telemetry_snapshot.txt"
  printf 'telemetry_snapshot_summary=%q\n' "$TELEMETRY_SNAPSHOT_SUMMARY"
  printf 'resource_gate_report=%q\n' "$RESOURCE_GATE_REPORT"
  printf 'resource_gate_status=%q\n' "${RESOURCE_GATE_STATUS:-not-run}"
  printf 'baseline_exit_status=%q\n' "$BASELINE_EXIT_STATUS"
  printf 'baseline_capture_dir=%q\n' "${BASELINE_CAPTURE_DIR:-}"
  printf 'baseline_summary=%q\n' "${BASELINE_SUMMARY:-}"
  printf 'baseline_state_path=%q\n' "${BASELINE_STATE_PATH:-}"
  printf 'baseline_runner_pid=%q\n' "${BASELINE_RUNNER_PID:-}"
  printf 'baseline_run_mode=%q\n' "${BASELINE_RUN_MODE:-not-run}"
  printf 'baseline_campaign_entry_path=%q\n' "${BASELINE_CAMPAIGN_ENTRY_PATH:-}"
  printf 'baseline_campaign_append_status=%q\n' "${BASELINE_CAMPAIGN_APPEND_STATUS:-not-run}"
  printf 'coordination_ledger=%q\n' "${COORDINATION_LEDGER:-none}"
  printf 'campaign_file=%q\n' "${CAMPAIGN_FILE:-none}"
  printf 'campaign_ledger=%q\n' "${CAMPAIGN_LEDGER:-none}"
  printf 'campaign_append_status=%q\n' "${BASELINE_CAMPAIGN_APPEND_STATUS:-$([ -n "$CAMPAIGN_LEDGER" ] && printf 'pending' || printf 'skipped')}"
  printf 'agent_name=%q\n' "${AGENT_NAME:-none}"
  printf 'hypothesis_branch=%q\n' "${HYPOTHESIS_BRANCH:-none}"
  printf 'write_scope=%q\n' "${WRITE_SCOPE:-none}"
  printf 'compute_slot=%q\n' "${COMPUTE_SLOT:-not-recorded}"
  printf 'expected_duration=%q\n' "${EXPECTED_DURATION:-not-recorded}"
  printf 'soft_checkpoint=%q\n' "${SOFT_CHECKPOINT:-not-recorded}"
  printf 'hard_stop=%q\n' "${HARD_STOP:-not-recorded}"
  printf 'starter_report=%q\n' "$SESSION_DIR/starter-report.md"
} > "$SESSION_DIR/session.env"

printf 'session_dir=%s\n' "$SESSION_DIR"
printf 'repo_root=%s\n' "$ROOT_ABS"
printf 'noise_status=%s\n' "$NOISE_STATUS"
printf 'telemetry_snapshot=%s\n' "$SESSION_DIR/telemetry_snapshot.txt"
printf 'telemetry_snapshot_summary=%s\n' "$TELEMETRY_SNAPSHOT_SUMMARY"
printf 'baseline_exit_status=%s\n' "$BASELINE_EXIT_STATUS"
printf 'starter_report=%s\n' "$SESSION_DIR/starter-report.md"
if [ -n "$COORDINATION_LEDGER" ]; then
  printf 'coordination_ledger=%s\n' "$COORDINATION_LEDGER"
fi
if [ -n "$CAMPAIGN_LEDGER" ]; then
  printf 'campaign_ledger=%s\n' "$CAMPAIGN_LEDGER"
fi
if [ -n "$BASELINE_CAPTURE_DIR" ]; then
  printf 'baseline_capture_dir=%s\n' "$BASELINE_CAPTURE_DIR"
fi
if [ -n "$BASELINE_STATE_PATH" ]; then
  printf 'baseline_state_path=%s\n' "$BASELINE_STATE_PATH"
fi
if [ -n "$BASELINE_CAMPAIGN_ENTRY_PATH" ]; then
  printf 'baseline_campaign_entry_path=%s\n' "$BASELINE_CAMPAIGN_ENTRY_PATH"
fi
