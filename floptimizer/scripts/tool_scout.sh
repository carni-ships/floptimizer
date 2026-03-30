#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_NOISE_CHECK="${TOOL_SCOUT_RUN_NOISE_CHECK:-1}"
RUN_CLEANUP_AUDIT="${TOOL_SCOUT_RUN_CLEANUP_AUDIT:-1}"
APPLY_CLEANUP=0
CLEANUP_INCLUDE=""
ROOT=""
TMP_NOISE_REPORT="$(mktemp)"
TMP_CLEANUP_REPORT="$(mktemp)"
trap 'rm -f "$TMP_NOISE_REPORT" "$TMP_CLEANUP_REPORT"' EXIT

usage() {
  cat <<'EOF'
Usage:
  tool_scout.sh [--cleanup] [--cleanup-include LIST] [--skip-noise-check] [ROOT]

Examples:
  tool_scout.sh .
  tool_scout.sh --cleanup .
  tool_scout.sh --cleanup --cleanup-include skill-artifacts,project-caches /path/to/repo

Notes:
  - Default behavior is read-only.
  - --cleanup applies the conservative cleanup helper.
  - If --cleanup is used without --cleanup-include, only old skill artifacts are removed.
  - Cleanup guidance is safest on local developer machines; on CI or remote hosts, prefer read-only scouting and review the cleanup script directly before applying anything.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

have_xcrun_tool() {
  have xcrun && xcrun -f "$1" >/dev/null 2>&1
}

say() {
  printf '%s\n' "${1-}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --cleanup)
      APPLY_CLEANUP=1
      shift
      ;;
    --cleanup-include)
      if [ $# -lt 2 ]; then
        echo "--cleanup-include requires a value" >&2
        exit 2
      fi
      CLEANUP_INCLUDE="$2"
      shift 2
      ;;
    --skip-noise-check)
      RUN_NOISE_CHECK=0
      shift
      ;;
    --no-cleanup-audit)
      RUN_CLEANUP_AUDIT=0
      shift
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
      if [ -n "$ROOT" ]; then
        echo "Unexpected extra positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      ROOT="$1"
      shift
      ;;
  esac
done

ROOT="${ROOT:-.}"

say "# Performance Tool Scout"
say
say "repo_root=$(cd "$ROOT" && pwd)"
say "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
say

say "## Available Tools"
for tool in perf bpftrace dtrace sample spindump xctrace hyperfine wrk vegeta hey strace ltrace py-spy scalene node go java dotnet-trace dotnet-counters valgrind heaptrack iostat vmstat pidstat sar memory_pressure pmset sensors osx-cpu-temp nvidia-smi rocm-smi sqlite3 psql mysql redis-cli; do
  if have "$tool"; then
    say "- $tool"
  fi
done
if have xcrun; then
  say "- xcrun"
fi
if have_xcrun_tool metal; then
  say "- metal (via xcrun)"
fi
if have_xcrun_tool metallib; then
  say "- metallib (via xcrun)"
fi
if have_xcrun_tool coremlcompiler; then
  say "- coremlcompiler (via xcrun)"
fi
if have cargo && cargo flamegraph --help >/dev/null 2>&1; then
  say "- cargo flamegraph"
fi
if have go && go tool pprof -h >/dev/null 2>&1; then
  say "- go tool pprof"
fi
say

say "## Platform Signals"
if [ "$(uname -s)" = "Darwin" ]; then
  say "- macOS detected"
  if [ "$(uname -m)" = "arm64" ]; then
    say "- Apple Silicon / unified-memory platform detected"
  fi
fi
say

say "## Machine Noise"
if [ "$RUN_NOISE_CHECK" = "1" ] && [ -f "$SCRIPT_DIR/machine_noise_check.sh" ]; then
  NOISE_STATUS=0
  if bash "$SCRIPT_DIR/machine_noise_check.sh" --top 5 >"$TMP_NOISE_REPORT" 2>&1; then
    NOISE_STATUS=0
  else
    NOISE_STATUS=$?
  fi

  awk -F= '
    /^(logical_cpus|load_averages|status|recommendation)=/ {
      printf "- %s: %s\n", $1, $2
    }
  ' "$TMP_NOISE_REPORT"

  if [ "$NOISE_STATUS" -ne 0 ]; then
    say "- competing local work likely detected; distrust one-off profiles until the machine quiets down."
    say "- run scripts/machine_noise_check.sh directly for full process detail."
    say "- avoid starting more compute-heavy jobs right now; use the cooldown for lower-load analysis and planning."
  else
    say "- no obvious competing local work detected above the configured thresholds."
  fi
else
  say "- machine noise check not run"
fi
say

say "## Cleanup Opportunities"
if [ "$RUN_CLEANUP_AUDIT" = "1" ] && [ -f "$SCRIPT_DIR/safe_cleanup.sh" ]; then
  CLEANUP_CMD=(bash "$SCRIPT_DIR/safe_cleanup.sh" --summary --project-root "$ROOT")
  if [ "$APPLY_CLEANUP" = "1" ]; then
    CLEANUP_CMD+=(--apply)
    if [ -n "$CLEANUP_INCLUDE" ]; then
      CLEANUP_CMD+=(--include "$CLEANUP_INCLUDE")
    fi
  fi

  if "${CLEANUP_CMD[@]}" >"$TMP_CLEANUP_REPORT" 2>&1; then
    :
  else
    :
  fi

  awk -F= '
    /^(cleanup_disk_used_percent|cleanup_swap_used_mb|cleanup_memory_pressure|cleanup_storage_candidates_kb|cleanup_default_apply_kb|cleanup_default_apply_categories|cleanup_apply_status|cleanup_applied_categories|cleanup_recommendation)=/ {
      key = $1
      sub(/^cleanup_/, "", key)
      value = substr($0, index($0, "=") + 1)
      printf "- %s: %s\n", key, value
    }
  ' "$TMP_CLEANUP_REPORT"

  if [ "$APPLY_CLEANUP" = "1" ]; then
    say "- safe cleanup was requested through tool_scout."
    if [ -n "$CLEANUP_INCLUDE" ]; then
      say "- applied cleanup scopes were constrained to: $CLEANUP_INCLUDE"
    else
      say "- default cleanup scope is conservative: old skill artifacts only."
    fi
  else
    say "- run scripts/tool_scout.sh --cleanup to prune old skill artifacts via the conservative cleanup helper."
    say "- for a deeper audit or broader cleanup scopes, run scripts/safe_cleanup.sh directly without --summary."
  fi
else
  say "- cleanup audit not run"
fi
say

say "## Repo Signals"
if [ -f "$ROOT/package.json" ]; then
  say "- JavaScript/TypeScript project detected"
fi
if find "$ROOT" -maxdepth 3 -name 'go.mod' -print -quit | grep -q .; then
  say "- Go project detected"
fi
if find "$ROOT" -maxdepth 3 -name 'Cargo.toml' -print -quit | grep -q .; then
  say "- Rust project detected"
fi
if find "$ROOT" -maxdepth 3 \( -name 'pyproject.toml' -o -name 'requirements.txt' -o -name 'setup.py' \) -print -quit | grep -q .; then
  say "- Python project detected"
fi
if find "$ROOT" -maxdepth 3 \( -name 'pom.xml' -o -name 'build.gradle' -o -name 'build.gradle.kts' \) -print -quit | grep -q .; then
  say "- JVM project detected"
fi
if find "$ROOT" -maxdepth 3 \( -name '*.sql' -o -name 'schema.prisma' \) -print -quit | grep -q .; then
  say "- Database-related files detected"
fi
if find "$ROOT" -maxdepth 4 -name '*.metal' -print -quit | grep -q .; then
  say "- Metal shader sources detected"
fi
if find "$ROOT" -maxdepth 4 \( -name '*.mlmodel' -o -name '*.mlpackage' \) -print -quit | grep -q .; then
  say "- Core ML assets detected"
fi
if find "$ROOT" -maxdepth 3 \( -name 'Dockerfile' -o -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \) -print -quit | grep -q .; then
  say "- Container/deployment files detected"
fi
say

say "## Recommended First Moves"
if have hyperfine; then
  say "- Use hyperfine for repeatable command timing."
fi
if [ -f "$SCRIPT_DIR/bench_capture.sh" ]; then
  say "- Wrap important baseline and candidate runs with scripts/bench_capture.sh to preserve the command, git state, noise evidence, and run-time telemetry."
fi
if [ -f "$SCRIPT_DIR/bench_compare.sh" ]; then
  say "- Use scripts/bench_compare.sh to compare captured baseline and candidate runs before trusting a claimed win."
fi
if [ -f "$SCRIPT_DIR/profile_telemetry.sh" ]; then
  say "- Use scripts/profile_telemetry.sh during long or ambiguous runs to capture swap, memory-pressure, thermal, IO, and device-limit clues."
fi
if [ -f "$SCRIPT_DIR/telemetry_summary.sh" ]; then
  say "- Use scripts/telemetry_summary.sh to condense captured telemetry into machine-level warnings before comparing runs."
fi
if [ -f "$SCRIPT_DIR/perf_session_bootstrap.sh" ]; then
  say "- Use scripts/perf_session_bootstrap.sh for a one-command kickoff that gathers context, a telemetry snapshot, scouting output, and an optional baseline capture."
fi
if [ -f "$SCRIPT_DIR/coordination_bootstrap.sh" ]; then
  say "- If multiple agents share the workspace or machine, bootstrap a live coordination ledger with scripts/coordination_bootstrap.sh before parallel experiments."
fi
if have perf; then
  say "- Use perf + flamegraph for Linux CPU hotspots."
fi
if have dtrace || have sample || have xctrace; then
  say "- Use native macOS profilers for CPU and blocking analysis."
fi
if [ "$RUN_NOISE_CHECK" = "1" ] && [ -s "$TMP_NOISE_REPORT" ] && grep -q '^status=NOISY$' "$TMP_NOISE_REPORT"; then
  say "- Re-check measurements after the machine quiets down; current numbers are likely contaminated by unrelated work."
  say "- Prefer review, hypothesis generation, or literature work over launching more heavy runs until that happens."
fi
if [ "$RUN_CLEANUP_AUDIT" = "1" ] && [ -s "$TMP_CLEANUP_REPORT" ]; then
  if grep -q '^cleanup_memory_pressure=high$' "$TMP_CLEANUP_REPORT" || grep -q '^cleanup_memory_pressure=elevated$' "$TMP_CLEANUP_REPORT"; then
    say "- If swap or memory pressure is elevated, stop heavy processes before trusting new benchmark numbers."
  fi
  if grep -Eq '^cleanup_default_apply_kb=[1-9]' "$TMP_CLEANUP_REPORT"; then
    say "- Reclaim old skill artifacts first if you need a quick, low-risk cleanup pass."
  fi
fi
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  say "- On Apple Silicon, benchmark CPU SIMD and multicore first, then evaluate Metal only for large data-parallel kernels."
fi
if have pmset || have sensors || have nvidia-smi || have rocm-smi; then
  say "- If sustained runs slow down or flatten unexpectedly, inspect thermal and power telemetry before assuming the code path is exhausted."
fi
if have nvidia-smi || have rocm-smi; then
  say "- Track accelerator memory use and utilization during GPU experiments; memory cliffs often explain why a promising path fails."
fi
if have_xcrun_tool metal; then
  say "- If GPU offload looks promising, compare a Metal path against the best CPU path and vendor baselines before writing custom kernels."
fi
if find "$ROOT" -maxdepth 4 -name '*.metal' -print -quit | grep -q .; then
  say "- Profile existing Metal kernels with Xcode Instruments and inspect threadgroup memory, barriers, and dispatch granularity."
fi
if find "$ROOT" -maxdepth 4 \( -name '*.mlmodel' -o -name '*.mlpackage' \) -print -quit | grep -q .; then
  say "- For ML-shaped workloads, benchmark Core ML or ANE-friendly paths separately from general GPU compute."
fi
if have strace; then
  say "- Use strace -c to check syscall-heavy paths."
fi
if have py-spy || have scalene; then
  say "- Use a Python sampler before rewriting Python hotspots."
fi
if [ -f "$ROOT/package.json" ]; then
  say "- Inspect event-loop blocking and heap usage for Node-based services."
fi
if find "$ROOT" -maxdepth 3 -name 'go.mod' -print -quit | grep -q .; then
  say "- Check go test -bench, pprof, and lock/allocation profiles."
fi
if find "$ROOT" -maxdepth 3 -name 'Cargo.toml' -print -quit | grep -q .; then
  say "- Check criterion or cargo bench, then perf or cargo flamegraph."
fi
if find "$ROOT" -maxdepth 3 \( -name '*.sql' -o -name 'schema.prisma' \) -print -quit | grep -q .; then
  say "- Review slow queries and EXPLAIN ANALYZE before app-side tuning."
fi
