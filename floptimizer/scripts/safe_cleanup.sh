#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="."
AGE_DAYS="${SAFE_CLEANUP_AGE_DAYS:-7}"
APPLY=0
INCLUDE_CATEGORIES=""
SUMMARY_ONLY=0

TMP_CANDIDATES="$(mktemp)"
TMP_ACTIONS="$(mktemp)"
trap 'rm -f "$TMP_CANDIDATES" "$TMP_ACTIONS"' EXIT

TOTAL_CANDIDATE_KB=0
DEFAULT_APPLY_KB=0
DISK_FREE_KB=0
DISK_USED_PERCENT="unknown"
SWAP_USED_MB="unknown"
MEMORY_PRESSURE="unknown"
APPLY_STATUS="not-requested"
APPLIED_CATEGORIES="none"
TEMP_ROOT="/tmp"

usage() {
  cat <<'EOF'
Usage:
  safe_cleanup.sh [--project-root DIR] [--age-days N] [--summary] [--apply] [--include LIST]

Examples:
  safe_cleanup.sh --project-root .
  safe_cleanup.sh --project-root . --apply
  safe_cleanup.sh --project-root . --apply --include skill-artifacts,project-caches

Behavior:
  - Audits memory, swap, disk headroom, and common reclaimable caches.
  - By default, only reports opportunities.
  - --summary keeps the audit fast by skipping deeper global cache scans.
  - With --apply and no --include, only removes old skill artifacts:
      * old .bench-captures children under the project root
      * old temp directories matching floptimizer*
  - Extra cleanup scopes are opt-in:
      * project-caches
      * package-manager-caches
  - Intended mainly for local developer machines. On CI, remote hosts, or unfamiliar Linux setups, prefer audit mode first and review candidates before using --apply.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

human_kb() {
  awk -v kb="${1:-0}" 'BEGIN {
    if (kb >= 1048576) { printf "%.2f GiB", kb / 1048576; exit }
    if (kb >= 1024) { printf "%.2f MiB", kb / 1024; exit }
    printf "%d KiB", kb
  }'
}

kb_for_path() {
  local path="$1"

  if [ ! -e "$path" ]; then
    echo 0
    return
  fi

  du -sk "$path" 2>/dev/null | awk '{print $1 + 0}'
}

sum_old_entries_kb() {
  local root="$1"
  local pattern="$2"
  local age_days="$3"

  if [ ! -d "$root" ]; then
    echo 0
    return
  fi

  find "$root" -mindepth 1 -maxdepth 1 -name "$pattern" -mtime +"$age_days" -print 2>/dev/null \
    | while IFS= read -r path; do
        kb_for_path "$path"
      done \
    | awk '{sum += $1} END {print sum + 0}'
}

record_candidate() {
  local category="$1"
  local size_kb="$2"
  local path="$3"
  local action="$4"
  local add_to_default="${5:-0}"

  if [ "${size_kb:-0}" -le 0 ]; then
    return
  fi

  TOTAL_CANDIDATE_KB=$((TOTAL_CANDIDATE_KB + size_kb))
  if [ "$add_to_default" = "1" ]; then
    DEFAULT_APPLY_KB=$((DEFAULT_APPLY_KB + size_kb))
  fi

  printf "%-24s %12s  %-24s  %s\n" \
    "$category" \
    "$(human_kb "$size_kb")" \
    "$action" \
    "$path" >> "$TMP_CANDIDATES"
}

include_category() {
  local category="$1"
  case ",$INCLUDE_CATEGORIES," in
    *,"$category",*) return 0 ;;
    *) return 1 ;;
  esac
}

convert_swap_to_mb() {
  local raw="$1"

  awk -v value="$raw" 'BEGIN {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    if (value == "" || value == "unknown") { print "unknown"; exit }
    suffix = substr(value, length(value), 1)
    number = value
    gsub(/[[:alpha:]]/, "", number)
    if (number == "") { print "unknown"; exit }
    if (suffix == "G" || suffix == "g") { printf "%.0f\n", number * 1024; exit }
    if (suffix == "K" || suffix == "k") { printf "%.0f\n", number / 1024; exit }
    printf "%.0f\n", number
  }'
}

collect_disk_state() {
  local df_line
  df_line="$(df -Pk "$PROJECT_ROOT" 2>/dev/null | awk 'NR==2 {print $4 " " $5}')"
  if [ -n "$df_line" ]; then
    DISK_FREE_KB="$(printf '%s\n' "$df_line" | awk '{print $1 + 0}')"
    DISK_USED_PERCENT="$(printf '%s\n' "$df_line" | awk '{gsub(/%/, "", $2); print $2}')"
  fi
}

collect_memory_state() {
  if [ "$(uname -s)" = "Darwin" ] && have sysctl; then
    local swap_raw
    swap_raw="$(sysctl -n vm.swapusage 2>/dev/null | sed -n 's/.*used = \([0-9.][0-9.]*[KMG]\).*/\1/p')"
    if [ -n "$swap_raw" ]; then
      SWAP_USED_MB="$(convert_swap_to_mb "$swap_raw")"
    fi
  elif have free; then
    SWAP_USED_MB="$(free -m 2>/dev/null | awk '/^Swap:/ {print $3 + 0}')"
  fi

  if [ "$SWAP_USED_MB" = "unknown" ]; then
    MEMORY_PRESSURE="unknown"
    return
  fi

  if [ "$SWAP_USED_MB" -ge 4096 ]; then
    MEMORY_PRESSURE="high"
  elif [ "$SWAP_USED_MB" -ge 1024 ]; then
    MEMORY_PRESSURE="elevated"
  else
    MEMORY_PRESSURE="normal"
  fi
}

collect_project_candidates() {
  local skill_project_kb
  local skill_tmp_kb

  skill_project_kb="$(sum_old_entries_kb "$PROJECT_ROOT/.bench-captures" '*' "$AGE_DAYS")"
  record_candidate \
    "skill-artifacts" \
    "$skill_project_kb" \
    "$PROJECT_ROOT/.bench-captures (children older than ${AGE_DAYS}d)" \
    "apply: skill-artifacts" \
    "1"

  skill_tmp_kb="$(sum_old_entries_kb "$TEMP_ROOT" 'floptimizer*' "$AGE_DAYS")"
  record_candidate \
    "skill-artifacts" \
    "$skill_tmp_kb" \
    "$TEMP_ROOT/floptimizer* (older than ${AGE_DAYS}d)" \
    "apply: skill-artifacts" \
    "1"

  while IFS='|' read -r rel_path category action; do
    if [ -z "$rel_path" ]; then
      continue
    fi
    record_candidate "$category" "$(kb_for_path "$PROJECT_ROOT/$rel_path")" "$PROJECT_ROOT/$rel_path" "$action"
  done <<'EOF'
.pytest_cache|project-caches|apply: project-caches
.mypy_cache|project-caches|apply: project-caches
.ruff_cache|project-caches|apply: project-caches
node_modules/.cache|project-caches|apply: project-caches
.turbo|project-caches|apply: project-caches
.parcel-cache|project-caches|apply: project-caches
.next/cache|project-caches|apply: project-caches
.nuxt|project-caches|apply: project-caches
.vite|project-caches|apply: project-caches
coverage|project-caches|apply: project-caches
target|build-artifacts|manual review
dist|build-artifacts|manual review
build|build-artifacts|manual review
EOF
}

pip_cache_dir() {
  if have python3; then
    python3 -m pip cache dir 2>/dev/null | tail -n 1
    return
  fi
  if have pip; then
    pip cache dir 2>/dev/null | tail -n 1
  fi
}

collect_global_candidates() {
  local path

  path="$(pip_cache_dir || true)"
  if [ -n "${path:-}" ]; then
    record_candidate "package-cache" "$(kb_for_path "$path")" "$path" "apply: package-manager-caches"
  fi

  if have uv; then
    path="$(uv cache dir 2>/dev/null || true)"
    if [ -n "$path" ]; then
      record_candidate "package-cache" "$(kb_for_path "$path")" "$path" "apply: package-manager-caches"
    fi
  fi

  if have pnpm; then
    path="$(pnpm store path 2>/dev/null || true)"
    if [ -n "$path" ]; then
      record_candidate "package-cache" "$(kb_for_path "$path")" "$path" "apply: package-manager-caches"
    fi
  fi

  if have yarn; then
    path="$(yarn cache dir 2>/dev/null || true)"
    if [ -n "$path" ]; then
      record_candidate "package-cache" "$(kb_for_path "$path")" "$path" "apply: package-manager-caches"
    fi
  fi

  if have go; then
    path="$(go env GOCACHE 2>/dev/null || true)"
    if [ -n "$path" ]; then
      record_candidate "package-cache" "$(kb_for_path "$path")" "$path" "apply: package-manager-caches"
    fi
  fi

  if have npm; then
    path="$(npm config get cache 2>/dev/null || true)"
    if [ -n "$path" ] && [ "$path" != "undefined" ]; then
      record_candidate "package-cache" "$(kb_for_path "$path")" "$path" "manual review"
    fi
  fi

  record_candidate "global-cache" "$(kb_for_path "$HOME/.cargo/registry")" "$HOME/.cargo/registry" "manual review"
  record_candidate "global-cache" "$(kb_for_path "$HOME/.cargo/git")" "$HOME/.cargo/git" "manual review"

  if [ "$(uname -s)" = "Darwin" ]; then
    record_candidate "global-cache" "$(kb_for_path "$HOME/Library/Developer/Xcode/DerivedData")" "$HOME/Library/Developer/Xcode/DerivedData" "manual review"
    if have brew; then
      path="$(brew --cache 2>/dev/null || true)"
      if [ -n "$path" ]; then
        record_candidate "global-cache" "$(kb_for_path "$path")" "$path" "manual review"
      fi
    fi
  else
    record_candidate "global-cache" "$(kb_for_path "$HOME/.cache")" "$HOME/.cache" "manual review"
  fi
}

run_action() {
  local label="$1"
  shift

  if "$@" >> "$TMP_ACTIONS" 2>&1; then
    printf "%s: ok\n" "$label" >> "$TMP_ACTIONS"
  else
    printf "%s: failed\n" "$label" >> "$TMP_ACTIONS"
  fi
}

apply_skill_artifacts() {
  local removed=0

  if [ -d "$PROJECT_ROOT/.bench-captures" ]; then
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      rm -rf "$path"
      printf "removed %s\n" "$path" >> "$TMP_ACTIONS"
      removed=1
    done < <(find "$PROJECT_ROOT/.bench-captures" -mindepth 1 -maxdepth 1 -mtime +"$AGE_DAYS" -print 2>/dev/null || true)
  fi

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    rm -rf "$path"
    printf "removed %s\n" "$path" >> "$TMP_ACTIONS"
    removed=1
  done < <(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -name 'floptimizer*' -mtime +"$AGE_DAYS" -print 2>/dev/null || true)

  if [ "$removed" = "0" ]; then
    printf "skill-artifacts: nothing eligible to remove\n" >> "$TMP_ACTIONS"
  fi
}

apply_project_caches() {
  local rel_path

  while IFS= read -r rel_path; do
    [ -n "$rel_path" ] || continue
    if [ -e "$PROJECT_ROOT/$rel_path" ]; then
      rm -rf "$PROJECT_ROOT/$rel_path"
      printf "removed %s\n" "$PROJECT_ROOT/$rel_path" >> "$TMP_ACTIONS"
    fi
  done <<'EOF'
.pytest_cache
.mypy_cache
.ruff_cache
node_modules/.cache
.turbo
.parcel-cache
.next/cache
.nuxt
.vite
coverage
EOF
}

apply_package_manager_caches() {
  if have python3; then
    run_action "python-pip-cache" python3 -m pip cache purge
  elif have pip; then
    run_action "pip-cache" pip cache purge
  fi

  if have uv; then
    run_action "uv-cache" uv cache clean
  fi

  if have pnpm; then
    run_action "pnpm-store" pnpm store prune
  fi

  if have yarn; then
    run_action "yarn-cache" yarn cache clean
  fi

  if have go; then
    run_action "go-build-cache" go clean -cache -testcache
  fi
}

recommendation_text() {
  if [ "$MEMORY_PRESSURE" = "high" ] || [ "$MEMORY_PRESSURE" = "elevated" ]; then
    if [ "$TOTAL_CANDIDATE_KB" -gt 0 ]; then
      printf '%s\n' "Reclaim old caches or artifacts first, but expect memory and swap pressure to improve mostly by stopping heavy processes."
    else
      printf '%s\n' "Safe automatic swap cleanup is limited; stop heavy processes or reboot before trusting profiling numbers."
    fi
    return
  fi

  if [ "$DEFAULT_APPLY_KB" -gt 0 ]; then
    printf '%s\n' "Run safe_cleanup.sh --apply to remove only old skill artifacts, or add --include project-caches/package-manager-caches for deeper cleanup."
    return
  fi

  if [ "$TOTAL_CANDIDATE_KB" -gt 0 ]; then
    printf '%s\n' "Review the listed cache and build directories before reclaiming space; the default apply scope stays conservative."
    return
  fi

  printf '%s\n' "No urgent cleanup need detected."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project-root)
      if [ $# -lt 2 ]; then
        echo "--project-root requires a value" >&2
        exit 2
      fi
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --age-days)
      if [ $# -lt 2 ]; then
        echo "--age-days requires a value" >&2
        exit 2
      fi
      AGE_DAYS="$2"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --summary)
      SUMMARY_ONLY=1
      shift
      ;;
    --include)
      if [ $# -lt 2 ]; then
        echo "--include requires a value" >&2
        exit 2
      fi
      INCLUDE_CATEGORIES="$2"
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

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
TEMP_ROOT="$(cd /tmp 2>/dev/null && pwd -P || printf '/tmp\n')"
if [ "$APPLY" = "1" ] && [ -z "$INCLUDE_CATEGORIES" ]; then
  INCLUDE_CATEGORIES="skill-artifacts"
fi

collect_disk_state
collect_memory_state
collect_project_candidates
if [ "$SUMMARY_ONLY" != "1" ]; then
  collect_global_candidates
fi

if [ "$APPLY" = "1" ]; then
  APPLY_STATUS="applied"
  APPLIED_CATEGORIES="$INCLUDE_CATEGORIES"

  if include_category "skill-artifacts"; then
    apply_skill_artifacts
  fi
  if include_category "project-caches"; then
    apply_project_caches
  fi
  if include_category "package-manager-caches"; then
    apply_package_manager_caches
  fi
fi

echo "# Safe Cleanup Audit"
echo
echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "project_root=$PROJECT_ROOT"
echo "age_days=$AGE_DAYS"
echo "apply=$APPLY"
echo "applied_categories=${APPLIED_CATEGORIES}"
echo "summary_only=$SUMMARY_ONLY"
echo

echo "## Resource Pressure"
echo "- disk_free: $(human_kb "$DISK_FREE_KB")"
echo "- disk_used_percent: ${DISK_USED_PERCENT}%"
echo "- swap_used_mb: $SWAP_USED_MB"
echo "- memory_pressure: $MEMORY_PRESSURE"
echo "- note: safe automatic swap cleanup is limited; freeing memory usually means stopping or restarting heavy processes."
echo

if [ "$SUMMARY_ONLY" != "1" ]; then
  echo "## Top Memory Processes"
  if ps -axo pid=,pmem=,rss=,etime=,command= >/dev/null 2>&1; then
    printf "%7s %6s %10s %10s  %s\n" "pid" "mem%" "rss_kb" "elapsed" "command"
    ps -axo pid=,pmem=,rss=,etime=,command= 2>/dev/null \
      | LC_ALL=C sort -k2,2nr \
      | head -n 5
  else
    echo "Unable to inspect process memory usage."
  fi
  echo
fi

echo "## Reclaimable Candidates"
if [ -s "$TMP_CANDIDATES" ]; then
  printf "%-24s %12s  %-24s  %s\n" "category" "size" "action" "path"
  cat "$TMP_CANDIDATES"
else
  echo "No obvious reclaimable cache or artifact directories detected."
fi
echo

if [ "$APPLY" = "1" ]; then
  echo "## Apply Results"
  if [ -s "$TMP_ACTIONS" ]; then
    cat "$TMP_ACTIONS"
  else
    echo "No cleanup actions ran."
  fi
  echo
fi

RECOMMENDATION="$(recommendation_text)"
echo "cleanup_storage_candidates_kb=$TOTAL_CANDIDATE_KB"
echo "cleanup_default_apply_kb=$DEFAULT_APPLY_KB"
echo "cleanup_default_apply_categories=skill-artifacts"
echo "cleanup_disk_free_kb=$DISK_FREE_KB"
echo "cleanup_disk_used_percent=$DISK_USED_PERCENT"
echo "cleanup_swap_used_mb=$SWAP_USED_MB"
echo "cleanup_memory_pressure=$MEMORY_PRESSURE"
echo "cleanup_apply_status=$APPLY_STATUS"
echo "cleanup_applied_categories=$APPLIED_CATEGORIES"
echo "cleanup_recommendation=$RECOMMENDATION"
