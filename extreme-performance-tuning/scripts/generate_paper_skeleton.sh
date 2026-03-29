#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_INPUT="$SCRIPT_DIR/../catalog/papers/arxiv-findings.md"
DEFAULT_OUTPUT="$SCRIPT_DIR/../catalog/papers/paper-skeleton.md"
INPUT_FILE="$DEFAULT_INPUT"
OUTPUT_FILE="$DEFAULT_OUTPUT"
TITLE="Draft Title"
SHORT_TITLE="Draft Short Title"

usage() {
  cat <<'EOF'
Usage:
  generate_paper_skeleton.sh [--input FILE] [--output FILE] [--title TEXT] [--short-title TEXT]

Builds a research-style paper skeleton from the aggregated
`arxiv-findings.md` bundle produced by `harvest_paper_findings.sh`.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --input)
      if [ $# -lt 2 ]; then
        echo "--input requires a value" >&2
        exit 2
      fi
      INPUT_FILE="$2"
      shift 2
      ;;
    --output)
      if [ $# -lt 2 ]; then
        echo "--output requires a value" >&2
        exit 2
      fi
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --title)
      if [ $# -lt 2 ]; then
        echo "--title requires a value" >&2
        exit 2
      fi
      TITLE="$2"
      shift 2
      ;;
    --short-title)
      if [ $# -lt 2 ]; then
        echo "--short-title requires a value" >&2
        exit 2
      fi
      SHORT_TITLE="$2"
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

mkdir -p "$(dirname "$OUTPUT_FILE")"

titles="$(awk '/^## / { sub(/^## /, "", $0); print }' "$INPUT_FILE" 2>/dev/null || true)"
title_count="$(printf '%s\n' "$titles" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ ! -f "$INPUT_FILE" ]; then
  {
    echo "# $TITLE"
    echo
    echo "_Input findings file not found: \`$INPUT_FILE\`_"
  } > "$OUTPUT_FILE"
  printf 'paper_skeleton=%s\n' "$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")"
  exit 0
fi

{
  echo "# $TITLE"
  echo
  echo "- short_title: $SHORT_TITLE"
  echo "- source_findings: \`$INPUT_FILE\`"
  echo "- generated_by: \`scripts/generate_paper_skeleton.sh\`"
  echo "- finding_count: ${title_count:-0}"
  echo
  echo "## Abstract"
  echo
  echo "- Problem framing:"
  echo "- Core thesis:"
  echo "- Main quantitative result:"
  echo "- Key mechanism insight:"
  echo "- Scope and caveats:"
  echo
  echo "## Introduction"
  echo
  echo "- Why this problem matters:"
  echo "- Why prior intuition or implementations were insufficient:"
  echo "- What this work contributes:"
  echo
  echo "## Contributions"
  echo
  if [ "${title_count:-0}" -gt 0 ]; then
    printf '%s\n' "$titles" | sed '/^$/d' | while IFS= read -r finding_title; do
      printf -- "- %s\n" "$finding_title"
    done
  else
    echo "- No harvested findings yet."
  fi
  echo
  echo "## Methodology"
  echo
  echo "- Workload and benchmark setup:"
  echo "- Correctness and invariant checks:"
  echo "- Measurement controls:"
  echo "- Telemetry and noise handling:"
  echo "- Hardware and software environments:"
  echo
  echo "## Experimental Findings"
  echo
} > "$OUTPUT_FILE"

awk '
  /^## / {
    if (in_block) {
      print "" >> out
    }
    title=$0
    sub(/^## /, "", title)
    print "### " title >> out
    print "" >> out
    in_block=1
    next
  }
  in_block {
    if ($0 ~ /^### Claim$/) {
      section="claim"
      next
    }
    if ($0 ~ /^### Draft Summary$/) {
      section="summary"
      next
    }
    if ($0 ~ /^### Intervention$/) {
      section="intervention"
      next
    }
    if ($0 ~ /^### Mechanism And Scope$/) {
      section="mechanism"
      next
    }
    if ($0 ~ /^### Reproducibility$/) {
      section="repro"
      next
    }
    if ($0 ~ /^### Suggested Table Row$/) {
      section="table"
      next
    }
    if ($0 ~ /^## /) {
      section=""
    }
    if (section == "summary" && $0 !~ /^$/) {
      print $0 >> out
    } else if (section == "mechanism" && $0 !~ /^$/) {
      print $0 >> out
    } else if (section == "repro" && $0 !~ /^$/) {
      repro_lines[repro_count++]=$0
    } else if (section == "table" && $0 !~ /^$/) {
      table_lines[table_count++]=$0
    }
  }
  END {
    if (in_block) {
      print "" >> out
    }
    print "## Ablations And Sensitivity" >> out
    print "" >> out
    print "- Which findings need ablation follow-up:" >> out
    print "- Which findings are hardware-sensitive:" >> out
    print "- Which findings are likely only fine-tuning versus conceptual direction:" >> out
    print "" >> out
    print "## Threats To Validity" >> out
    print "" >> out
    print "- Measurement noise or contamination risks:" >> out
    print "- Hardware-specificity and portability limits:" >> out
    print "- Workload representativeness limits:" >> out
    print "- Negative results or missing replications:" >> out
    print "" >> out
    print "## Reproducibility" >> out
    print "" >> out
    print "- Findings bundle: source-generated from notes and session reports" >> out
    if (repro_count > 0) {
      for (i = 0; i < repro_count; i++) {
        print repro_lines[i] >> out
      }
    } else {
      print "- No reproducibility notes harvested yet." >> out
    }
    print "" >> out
    print "## Table Candidates" >> out
    print "" >> out
    print "| Finding | Intervention | Metric | Effect | Operating Region | Caveats |" >> out
    print "|---|---|---|---|---|---|" >> out
    if (table_count > 0) {
      for (i = 0; i < table_count; i++) {
        print table_lines[i] >> out
      }
    } else {
      print "| TBA | TBA | TBA | TBA | TBA | TBA |" >> out
    }
    print "" >> out
    print "## Related Work" >> out
    print "" >> out
    print "- Prior implementations and exemplar systems to cite:" >> out
    print "- Relevant papers, maintainer writeups, and public benchmarks:" >> out
    print "" >> out
    print "## Conclusion" >> out
    print "" >> out
    print "- Main takeaway:" >> out
    print "- Practical recommendation:" >> out
    print "- Open questions:" >> out
  }
' out="$OUTPUT_FILE" "$INPUT_FILE"

printf 'paper_skeleton=%s\n' "$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")"
