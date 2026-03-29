#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CAPTURES_ROOT="${BENCH_CAPTURE_OUTPUT_ROOT:-$PWD/.bench-captures}"
DEFAULT_SESSIONS_ROOT="${PERF_SESSION_OUTPUT_ROOT:-$PWD/.perf-sessions}"
DEFAULT_CATALOG_ROOT="$SCRIPT_DIR/../catalog"
CAPTURES_ROOT="$DEFAULT_CAPTURES_ROOT"
SESSIONS_ROOT="$DEFAULT_SESSIONS_ROOT"
CATALOG_ROOT="$DEFAULT_CATALOG_ROOT"

usage() {
  cat <<'EOF'
Usage:
  harvest_trick_candidates.sh [--captures-root DIR] [--sessions-root DIR] [--catalog-root DIR]

Scans benchmark capture notes and session starter reports for the
"Reusable Optimization Trick Candidate" section, emits candidate trick
cards into catalog/candidates/, and regenerates candidate and curated
indexes under catalog/indexes/.
EOF
}

extract_field() {
  local field="$1"
  local file="$2"

  awk -v field="$field" '
    /^## Reusable Optimization Trick Candidate$/ { in_section=1; next }
    in_section && /^## / { in_section=0 }
    in_section {
      prefix="- " field ":"
      if (index($0, prefix) == 1) {
        value=substr($0, length(prefix) + 1)
        sub(/^[[:space:]]+/, "", value)
        print value
        exit
      }
    }
  ' "$file"
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9._-' '-' \
    | sed 's/^-*//; s/-*$//'
}

is_falsey() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    no|n|false|0|skip|skipped)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

card_title() {
  sed -n 's/^# //p' "$1" | head -n 1
}

card_field() {
  local field="$1"
  local file="$2"
  sed -n "s/^- ${field}: //p" "$file" | head -n 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --captures-root)
      if [ $# -lt 2 ]; then
        echo "--captures-root requires a value" >&2
        exit 2
      fi
      CAPTURES_ROOT="$2"
      shift 2
      ;;
    --sessions-root)
      if [ $# -lt 2 ]; then
        echo "--sessions-root requires a value" >&2
        exit 2
      fi
      SESSIONS_ROOT="$2"
      shift 2
      ;;
    --catalog-root)
      if [ $# -lt 2 ]; then
        echo "--catalog-root requires a value" >&2
        exit 2
      fi
      CATALOG_ROOT="$2"
      shift 2
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

mkdir -p "$CATALOG_ROOT/candidates" "$CATALOG_ROOT/indexes" "$CATALOG_ROOT/tricks"

found_any=0

while IFS= read -r notes_file; do
  trick_name="$(extract_field trick_name "$notes_file")"
  candidate_for_catalog="$(extract_field candidate_for_catalog "$notes_file")"

  if [ -z "$trick_name" ]; then
    continue
  fi

  if [ -n "$candidate_for_catalog" ] && is_falsey "$candidate_for_catalog"; then
    continue
  fi

  symptoms="$(extract_field symptoms_or_problem_shape "$notes_file")"
  mechanism="$(extract_field mechanism "$notes_file")"
  best_for="$(extract_field best_for "$notes_file")"
  not_for="$(extract_field not_for "$notes_file")"
  prerequisites="$(extract_field prerequisites "$notes_file")"
  expected_upside="$(extract_field expected_upside "$notes_file")"
  cost="$(extract_field cost "$notes_file")"
  risk="$(extract_field risk "$notes_file")"
  portable_principle="$(extract_field portable_principle "$notes_file")"
  machine_specific_tuning="$(extract_field machine_specific_tuning "$notes_file")"
  evidence_level="$(extract_field evidence_level "$notes_file")"
  confidence="$(extract_field confidence "$notes_file")"
  related_exemplars="$(extract_field related_exemplars "$notes_file")"
  promotion_notes="$(extract_field promotion_notes "$notes_file")"

  timestamp="$(sed -n 's/^- timestamp_utc: //p' "$notes_file" | head -n 1)"
  label="$(sed -n 's/^- label: //p' "$notes_file" | head -n 1)"
  timestamp_slug="$(printf '%s' "${timestamp:-unknown-time}" | tr -cs '0-9a-zA-Z' '-')"
  trick_slug="$(slugify "$trick_name")"
  card_path="$CATALOG_ROOT/candidates/${timestamp_slug}_${trick_slug}.md"
  run_dir="$(dirname "$notes_file")"

  cat > "$card_path" <<EOF
# $trick_name

- status: candidate
- mechanism: ${mechanism:-}
- symptoms_or_problem_shape: ${symptoms:-}
- best_for: ${best_for:-}
- not_for: ${not_for:-}
- prerequisites: ${prerequisites:-}
- expected_upside: ${expected_upside:-}
- cost: ${cost:-}
- risk: ${risk:-}
- portable_principle: ${portable_principle:-}
- machine_specific_tuning: ${machine_specific_tuning:-}
- evidence_level: ${evidence_level:-single-run}
- confidence: ${confidence:-}
- source_runs: \`$run_dir\`
- related_exemplars: ${related_exemplars:-}
- promotion_notes: ${promotion_notes:-}
- source_note: \`$notes_file\`
- label: ${label:-}
- timestamp_utc: ${timestamp:-}

## Why It Works

- ${mechanism:-}

## When To Try It

- ${best_for:-}

## When To Avoid It

- ${not_for:-}

## Evidence

- source_run: \`$run_dir\`
- evidence_level: ${evidence_level:-single-run}
- confidence: ${confidence:-}

## Notes

- portable_principle: ${portable_principle:-}
- machine_specific_tuning: ${machine_specific_tuning:-}
- promotion_notes: ${promotion_notes:-}
EOF

  found_any=1
done < <(
  {
    if [ -d "$CAPTURES_ROOT" ]; then
      find "$CAPTURES_ROOT" -type f -name notes.md
    fi
    if [ -d "$SESSIONS_ROOT" ]; then
      find "$SESSIONS_ROOT" -type f -name starter-report.md
    fi
  } | sort
)

candidate_index="$CATALOG_ROOT/indexes/candidate-tricks.md"
{
  echo "# Candidate Tricks"
  echo
  echo "Generated by \`scripts/harvest_trick_candidates.sh\`."
  echo
} > "$candidate_index"

candidate_count=0
while IFS= read -r card; do
  candidate_count=$((candidate_count + 1))
  title="$(card_title "$card")"
  evidence="$(card_field evidence_level "$card")"
  confidence="$(card_field confidence "$card")"
  printf -- "- [%s](../candidates/%s)" "$title" "$(basename "$card")" >> "$candidate_index"
  if [ -n "$evidence" ]; then
    printf -- " - evidence: %s" "$evidence" >> "$candidate_index"
  fi
  if [ -n "$confidence" ]; then
    printf -- ", confidence: %s" "$confidence" >> "$candidate_index"
  fi
  printf '\n' >> "$candidate_index"
done < <(find "$CATALOG_ROOT/candidates" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort)

if [ "$candidate_count" -eq 0 ]; then
  echo "No trick candidates harvested yet." >> "$candidate_index"
fi

curated_index="$CATALOG_ROOT/indexes/curated-tricks.md"
{
  echo "# Curated Tricks"
  echo
  echo "Generated by \`scripts/harvest_trick_candidates.sh\`."
  echo
} > "$curated_index"

curated_count=0
while IFS= read -r card; do
  curated_count=$((curated_count + 1))
  title="$(card_title "$card")"
  status="$(card_field status "$card")"
  printf -- "- [%s](../tricks/%s)" "$title" "$(basename "$card")" >> "$curated_index"
  if [ -n "$status" ]; then
    printf -- " - status: %s" "$status" >> "$curated_index"
  fi
  printf '\n' >> "$curated_index"
done < <(find "$CATALOG_ROOT/tricks" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort)

if [ "$curated_count" -eq 0 ]; then
  echo "No curated trick cards yet." >> "$curated_index"
fi

printf 'catalog_root=%s\n' "$CATALOG_ROOT"
printf 'candidate_index=%s\n' "$candidate_index"
printf 'curated_index=%s\n' "$curated_index"
printf 'harvested_any=%s\n' "$found_any"
