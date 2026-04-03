#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEDGER_FILE=""
CAPTURE_DIR=""
BASELINE_CAPTURE=""
CANDIDATE_CAPTURE=""
COMPARE_REPORT=""
STATUS=""
DECISION=""
DESCRIPTION=""
PRIMARY_BEFORE=""
PRIMARY_AFTER=""
DELTA_PCT=""
PRESERVATION_CLASS=""

usage() {
  cat <<'EOF'
Usage:
  append_campaign_result.sh --ledger-file PATH --capture-dir DIR [--status TEXT] [--description TEXT] [--decision TEXT] [--primary-before TEXT] [--primary-after TEXT] [--delta-pct TEXT] [--preservation-class TEXT]
  append_campaign_result.sh --ledger-file PATH --baseline-capture DIR --candidate-capture DIR [--compare-report PATH] [--status TEXT] [--description TEXT] [--decision TEXT] [--preservation-class TEXT]

Appends a compact TSV row for a serious run to a campaign ledger.
EOF
}

resolve_abs() {
  local input="$1"
  if [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s\n' "$(pwd)/$input"
  fi
}

escape_tsv() {
  printf '%s' "$1" | tr '\t' ' ' | tr '\n' ' '
}

parse_compare_field() {
  local text="$1"
  local key="$2"
  printf '%s\n' "$text" | sed -n "s/^- ${key}: //p" | head -n 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --ledger-file)
      LEDGER_FILE="$2"
      shift 2
      ;;
    --capture-dir)
      CAPTURE_DIR="$2"
      shift 2
      ;;
    --baseline-capture)
      BASELINE_CAPTURE="$2"
      shift 2
      ;;
    --candidate-capture)
      CANDIDATE_CAPTURE="$2"
      shift 2
      ;;
    --compare-report)
      COMPARE_REPORT="$2"
      shift 2
      ;;
    --status)
      STATUS="$2"
      shift 2
      ;;
    --decision)
      DECISION="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --primary-before)
      PRIMARY_BEFORE="$2"
      shift 2
      ;;
    --primary-after)
      PRIMARY_AFTER="$2"
      shift 2
      ;;
    --delta-pct)
      DELTA_PCT="$2"
      shift 2
      ;;
    --preservation-class)
      PRESERVATION_CLASS="$2"
      shift 2
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

if [ -z "$LEDGER_FILE" ]; then
  usage >&2
  exit 2
fi

LEDGER_FILE="$(resolve_abs "$LEDGER_FILE")"
if [ -n "$CAPTURE_DIR" ]; then
  CAPTURE_DIR="$(resolve_abs "$CAPTURE_DIR")"
fi
if [ -n "$BASELINE_CAPTURE" ]; then
  BASELINE_CAPTURE="$(resolve_abs "$BASELINE_CAPTURE")"
fi
if [ -n "$CANDIDATE_CAPTURE" ]; then
  CANDIDATE_CAPTURE="$(resolve_abs "$CANDIDATE_CAPTURE")"
fi
if [ -n "$COMPARE_REPORT" ]; then
  COMPARE_REPORT="$(resolve_abs "$COMPARE_REPORT")"
fi

if [ -z "$CAPTURE_DIR" ] && [ -n "$CANDIDATE_CAPTURE" ]; then
  CAPTURE_DIR="$CANDIDATE_CAPTURE"
fi

if [ -z "$CAPTURE_DIR" ]; then
  usage >&2
  exit 2
fi

if [ ! -f "$LEDGER_FILE" ]; then
  echo "Ledger file not found: $LEDGER_FILE" >&2
  exit 1
fi

if [ ! -f "$CAPTURE_DIR/capture.env" ]; then
  echo "capture.env not found under: $CAPTURE_DIR" >&2
  exit 1
fi

# Compare-driven fill is preferred when baseline and candidate are available.
if [ -n "$BASELINE_CAPTURE" ] || [ -n "$CANDIDATE_CAPTURE" ]; then
  if [ -z "$BASELINE_CAPTURE" ] || [ -z "$CANDIDATE_CAPTURE" ]; then
    echo "--baseline-capture and --candidate-capture must be provided together" >&2
    exit 2
  fi
  if [ ! -f "$BASELINE_CAPTURE/capture.env" ]; then
    echo "Baseline capture.env not found under: $BASELINE_CAPTURE" >&2
    exit 1
  fi
  if [ ! -f "$CANDIDATE_CAPTURE/capture.env" ]; then
    echo "Candidate capture.env not found under: $CANDIDATE_CAPTURE" >&2
    exit 1
  fi
  CAPTURE_DIR="$CANDIDATE_CAPTURE"
fi

# shellcheck disable=SC1090
source "$CAPTURE_DIR/capture.env"

if [ -n "$COMPARE_REPORT" ] && [ ! -f "$COMPARE_REPORT" ]; then
  echo "Compare report not found: $COMPARE_REPORT" >&2
  exit 1
fi

if [ -n "$BASELINE_CAPTURE" ] && [ -z "$COMPARE_REPORT" ]; then
  COMPARE_REPORT="$(mktemp)"
  trap 'rm -f "$COMPARE_REPORT"' EXIT
  "$SCRIPT_DIR/bench_compare.sh" --baseline "$BASELINE_CAPTURE" --candidate "$CANDIDATE_CAPTURE" > "$COMPARE_REPORT"
fi

if [ -n "$COMPARE_REPORT" ]; then
  COMPARE_TEXT="$(cat "$COMPARE_REPORT")"
  if [ -z "$PRIMARY_BEFORE" ]; then
    PRIMARY_BEFORE="$(parse_compare_field "$COMPARE_TEXT" "baseline_metric")"
  fi
  if [ -z "$PRIMARY_AFTER" ]; then
    PRIMARY_AFTER="$(parse_compare_field "$COMPARE_TEXT" "candidate_metric")"
  fi
  if [ -z "$DELTA_PCT" ]; then
    DELTA_PCT="$(parse_compare_field "$COMPARE_TEXT" "metric_percent_delta" | sed 's/%$//')"
  fi
fi

if [ -z "$STATUS" ]; then
  STATUS="recorded"
fi
if [ -z "$DECISION" ]; then
  DECISION="$STATUS"
fi
if [ -z "$DESCRIPTION" ]; then
  DESCRIPTION="capture ${label:-unknown}"
fi

ARTIFACT_PATH="$CAPTURE_DIR"
NOTES_PATH="${notes_path:-$CAPTURE_DIR/notes.md}"
ENTRY_PATH="$CAPTURE_DIR/campaign-entry.env"

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(escape_tsv "${timestamp_utc:-unknown}")" \
  "$(escape_tsv "${git_branch:-unknown}")" \
  "$(escape_tsv "${git_head:-unknown}")" \
  "$(escape_tsv "${label:-none}")" \
  "$(escape_tsv "$STATUS")" \
  "$(escape_tsv "$DECISION")" \
  "$(escape_tsv "$DESCRIPTION")" \
  "$(escape_tsv "$PRIMARY_BEFORE")" \
  "$(escape_tsv "$PRIMARY_AFTER")" \
  "$(escape_tsv "$DELTA_PCT")" \
  "$(escape_tsv "${noise_status:-unknown}")" \
  "$(escape_tsv "$PRESERVATION_CLASS")" \
  "$(escape_tsv "$ARTIFACT_PATH")" \
  "$(escape_tsv "$NOTES_PATH")" >> "$LEDGER_FILE"

{
  printf 'campaign_file=%q\n' "${campaign_file:-none}"
  printf 'ledger_file=%q\n' "$LEDGER_FILE"
  printf 'capture_dir=%q\n' "$CAPTURE_DIR"
  printf 'status=%q\n' "$STATUS"
  printf 'decision=%q\n' "$DECISION"
  printf 'description=%q\n' "$DESCRIPTION"
  printf 'primary_before=%q\n' "$PRIMARY_BEFORE"
  printf 'primary_after=%q\n' "$PRIMARY_AFTER"
  printf 'delta_pct=%q\n' "$DELTA_PCT"
  printf 'preservation_class=%q\n' "$PRESERVATION_CLASS"
  printf 'appended_at_utc=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$ENTRY_PATH"

if [ -f "$NOTES_PATH" ]; then
  python3 - "$NOTES_PATH" "$LEDGER_FILE" "$ENTRY_PATH" <<'PY'
import sys
from pathlib import Path
import re

path = Path(sys.argv[1])
ledger = sys.argv[2]
entry = sys.argv[3]
text = path.read_text(encoding="utf-8")
text = re.sub(r"^- campaign_append_status: .*$", "- campaign_append_status: appended", text, flags=re.MULTILINE)
text = re.sub(r"^- campaign_ledger: .*$", f"- campaign_ledger: {ledger}", text, flags=re.MULTILINE)
text = re.sub(r"^- campaign_entry_path: .*$", f"- campaign_entry_path: {entry}", text, flags=re.MULTILINE)
path.write_text(text, encoding="utf-8")
PY
fi

printf 'ledger_file=%s\n' "$LEDGER_FILE"
printf 'capture_dir=%s\n' "$CAPTURE_DIR"
printf 'appended_status=%s\n' "$STATUS"
