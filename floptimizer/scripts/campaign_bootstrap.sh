#!/usr/bin/env bash
set -euo pipefail

ROOT="."
CAMPAIGN_DIR=""
CAMPAIGN_FILE=""
LEDGER_FILE=""
OBJECTIVE=""
PRIMARY_METRIC=""
TARGET=""
BENCHMARK_COMMAND=""
FORCE=0

usage() {
  cat <<'EOF'
Usage:
  campaign_bootstrap.sh [--root DIR] [--campaign-dir DIR] [--campaign-file PATH] [--ledger-file PATH] [--objective TEXT] [--primary-metric TEXT] [--target TEXT] [--benchmark-command TEXT] [--force]

Creates a lightweight campaign directive and compact TSV ledger for a long-running
optimization effort.
EOF
}

resolve_path() {
  local root_abs="$1"
  local input="$2"

  if [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s\n' "$root_abs/$input"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="$2"
      shift 2
      ;;
    --campaign-dir)
      CAMPAIGN_DIR="$2"
      shift 2
      ;;
    --campaign-file)
      CAMPAIGN_FILE="$2"
      shift 2
      ;;
    --ledger-file)
      LEDGER_FILE="$2"
      shift 2
      ;;
    --objective)
      OBJECTIVE="$2"
      shift 2
      ;;
    --primary-metric)
      PRIMARY_METRIC="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --benchmark-command)
      BENCHMARK_COMMAND="$2"
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
      exit 2
      ;;
  esac
done

ROOT_ABS="$(cd "$ROOT" && pwd)"
if [ -z "$CAMPAIGN_DIR" ]; then
  CAMPAIGN_DIR="$ROOT_ABS/.perf-campaign"
else
  CAMPAIGN_DIR="$(resolve_path "$ROOT_ABS" "$CAMPAIGN_DIR")"
fi

if [ -z "$CAMPAIGN_FILE" ]; then
  CAMPAIGN_FILE="$CAMPAIGN_DIR/campaign.md"
else
  CAMPAIGN_FILE="$(resolve_path "$ROOT_ABS" "$CAMPAIGN_FILE")"
fi

if [ -z "$LEDGER_FILE" ]; then
  LEDGER_FILE="$CAMPAIGN_DIR/results.tsv"
else
  LEDGER_FILE="$(resolve_path "$ROOT_ABS" "$LEDGER_FILE")"
fi

mkdir -p "$CAMPAIGN_DIR"
mkdir -p "$(dirname "$CAMPAIGN_FILE")"
mkdir -p "$(dirname "$LEDGER_FILE")"

if [ ! -e "$CAMPAIGN_FILE" ] || [ "$FORCE" = "1" ]; then
  cat > "$CAMPAIGN_FILE" <<EOF
# Optimization Campaign

## Objective

${OBJECTIVE:-}

## Primary Metric

${PRIMARY_METRIC:-}

## Target

${TARGET:-}

## Benchmark Or Evaluation Command

\`\`\`bash
${BENCHMARK_COMMAND:-}
\`\`\`

## Keep Or Discard Rule

- Keep if the primary metric improves without violating invariants.
- Keep if the primary metric is flat and the implementation is simpler, safer, or easier to maintain.
- Park and preserve if the result is correct but not yet winning and still looks like a believable future branch.
- Discard if the result regresses the target metric or breaks invariants.

## Must-Not-Regress Invariants

- 

## Operating Region That Matters

- 

## Current Leader

- branch_or_worktree:
- commit_ref:
- reason:

## Branch Families To Keep Alive

- leading_family:
- alternative_family:
- speculative_or_enabling_family:

## Recent Failure Families

- 

## Known Blockers

- 

## Evaluator Risks

- 

## Prompt Or Skill Steering Variant

- variant_name:
- compared_against:
- expected_behavior_change:

## Stop Rule

- 
EOF
fi

if [ ! -e "$LEDGER_FILE" ] || [ "$FORCE" = "1" ]; then
  cat > "$LEDGER_FILE" <<'EOF'
timestamp_utc	git_branch	git_head	label	status	decision	description	primary_metric_before	primary_metric_after	delta_pct	noise_status	preservation_class	artifact_path	notes_path
EOF
fi

printf 'campaign_dir=%s\n' "$CAMPAIGN_DIR"
printf 'campaign_file=%s\n' "$CAMPAIGN_FILE"
printf 'ledger_file=%s\n' "$LEDGER_FILE"
