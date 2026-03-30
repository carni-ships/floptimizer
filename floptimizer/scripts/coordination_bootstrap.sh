#!/usr/bin/env bash
set -euo pipefail

ROOT="."
LEDGER_PATH=""
AGENT_NAME=""
BRANCH_OR_WORKTREE=""
HYPOTHESIS_BRANCH=""
WRITE_SCOPE=""
COMPUTE_TASK=""
EXPECTED_DURATION=""
SOFT_CHECKPOINT=""
HARD_STOP=""
FORCE=0

usage() {
  cat <<'EOF'
Usage:
  coordination_bootstrap.sh [--root DIR] [--ledger PATH] [--agent NAME] [--branch-or-worktree NAME] [--hypothesis-branch TEXT] [--write-scope TEXT] [--compute-task TEXT] [--expected-duration TEXT] [--soft-checkpoint TEXT] [--hard-stop TEXT] [--force]

Examples:
  coordination_bootstrap.sh --root .
  coordination_bootstrap.sh --root . --agent codex-a --hypothesis-branch batching-path --write-scope 'src/encoder.rs'
  coordination_bootstrap.sh --root . --agent codex-b --compute-task 'baseline sweep' --expected-duration '12m' --soft-checkpoint '18m' --hard-stop '30m'

Creates a lightweight coordination ledger for multi-agent work. By default the
ledger is written to .perf-coordination/coordination-ledger.md under the target
root. Existing ledgers are left in place unless --force is used.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

resolve_path() {
  local root_abs="$1"
  local input="$2"

  if [ -z "$input" ]; then
    return
  fi

  if [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
    return
  fi

  printf '%s\n' "$root_abs/$input"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      if [ $# -lt 2 ]; then
        echo "--root requires a value" >&2
        exit 2
      fi
      ROOT="$2"
      shift 2
      ;;
    --ledger)
      if [ $# -lt 2 ]; then
        echo "--ledger requires a value" >&2
        exit 2
      fi
      LEDGER_PATH="$2"
      shift 2
      ;;
    --agent)
      if [ $# -lt 2 ]; then
        echo "--agent requires a value" >&2
        exit 2
      fi
      AGENT_NAME="$2"
      shift 2
      ;;
    --branch-or-worktree)
      if [ $# -lt 2 ]; then
        echo "--branch-or-worktree requires a value" >&2
        exit 2
      fi
      BRANCH_OR_WORKTREE="$2"
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
    --compute-task)
      if [ $# -lt 2 ]; then
        echo "--compute-task requires a value" >&2
        exit 2
      fi
      COMPUTE_TASK="$2"
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
    --force)
      FORCE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT_ABS="$(cd "$ROOT" && pwd)"

if [ -z "$LEDGER_PATH" ]; then
  LEDGER_PATH="$ROOT_ABS/.perf-coordination/coordination-ledger.md"
else
  LEDGER_PATH="$(resolve_path "$ROOT_ABS" "$LEDGER_PATH")"
fi

if [ -z "$BRANCH_OR_WORKTREE" ] && have git && git -C "$ROOT_ABS" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH_OR_WORKTREE="$(git -C "$ROOT_ABS" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
fi

TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

ACTIVE_STATUS="active | blocked | parked | done"
WRITE_STATUS="active | released"
COMPUTE_STATUS="active | released"
if [ -n "$AGENT_NAME" ] || [ -n "$HYPOTHESIS_BRANCH" ] || [ -n "$WRITE_SCOPE" ]; then
  ACTIVE_STATUS="active"
fi
if [ -n "$AGENT_NAME" ] || [ -n "$WRITE_SCOPE" ]; then
  WRITE_STATUS="active"
fi
if [ -n "$COMPUTE_TASK" ]; then
  COMPUTE_STATUS="active"
fi

if [ -e "$LEDGER_PATH" ] && [ "$FORCE" != "1" ]; then
  printf 'status=existing\n'
  printf 'ledger=%s\n' "$LEDGER_PATH"
  exit 0
fi

mkdir -p "$(dirname "$LEDGER_PATH")"

cat > "$LEDGER_PATH" <<EOF
# Agent Coordination Ledger

last_updated: $TIMESTAMP_UTC
workspace_root: $ROOT_ABS
generated_by: scripts/coordination_bootstrap.sh

## Active Agents

- agent: $AGENT_NAME
  branch_or_worktree: $BRANCH_OR_WORKTREE
  hypothesis_branch: $HYPOTHESIS_BRANCH
  status: $ACTIVE_STATUS
  write_scope: $WRITE_SCOPE
  notes:

## Write Claims

- owner: $AGENT_NAME
  files_or_modules: $WRITE_SCOPE
  started_at: $TIMESTAMP_UTC
  status: $WRITE_STATUS
  release_when:

## Compute Slot

- holder: $AGENT_NAME
  task: $COMPUTE_TASK
  expected_duration: $EXPECTED_DURATION
  soft_checkpoint: $SOFT_CHECKPOINT
  hard_stop: $HARD_STOP
  started_at: $TIMESTAMP_UTC
  status: $COMPUTE_STATUS

## Experiment Frontier

- branch: $HYPOTHESIS_BRANCH
  owner: $AGENT_NAME
  status: active | won | lost | blocked | parked
  blocker_or_result:
  revisit_trigger:
EOF

printf 'status=created\n'
printf 'ledger=%s\n' "$LEDGER_PATH"
