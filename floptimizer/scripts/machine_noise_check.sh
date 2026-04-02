#!/usr/bin/env bash
set -euo pipefail

CPU_THRESHOLD="${CPU_THRESHOLD:-10}"
MEM_THRESHOLD="${MEM_THRESHOLD:-8}"
BACKGROUND_CPU_THRESHOLD="${BACKGROUND_CPU_THRESHOLD:-2}"
TOP_N="${TOP_N:-8}"

while [ $# -gt 0 ]; do
  case "$1" in
    --cpu-threshold)
      CPU_THRESHOLD="$2"
      shift 2
      ;;
    --mem-threshold)
      MEM_THRESHOLD="$2"
      shift 2
      ;;
    --background-cpu-threshold)
      BACKGROUND_CPU_THRESHOLD="$2"
      shift 2
      ;;
    --top)
      TOP_N="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

have() {
  command -v "$1" >/dev/null 2>&1
}

logical_cpus() {
  if have sysctl; then
    sysctl -n hw.logicalcpu 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || true
    return
  fi
  if have nproc; then
    nproc
    return
  fi
  echo "unknown"
}

load_averages() {
  if ! have uptime; then
    return
  fi
  uptime 2>/dev/null | awk '
    /load averages?:/ {
      split($0, parts, /load averages?: /)
      if (length(parts) > 1) {
        loads = parts[2]
        gsub(/,/, "", loads)
        print loads
      }
    }
  '
}

LOADS="$(load_averages)"
CPUS="$(logical_cpus)"
SELF_PID="$$"

TMP_TOP="$(mktemp)"
TMP_NOISE="$(mktemp)"
trap 'rm -f "$TMP_TOP" "$TMP_NOISE"' EXIT

PS_FORMAT="pid=,pcpu=,pmem=,etime=,command="

if ! ps -axo $PS_FORMAT >/dev/null 2>&1; then
  echo "Unable to inspect process table with ps -axo." >&2
  exit 1
fi

ps -axo $PS_FORMAT 2>/dev/null | awk -v self="$SELF_PID" '
  $1 == self { next }
  {
    pid = $1
    cpu = $2
    mem = $3
    etime = $4
    $1 = $2 = $3 = $4 = ""
    sub(/^ +/, "", $0)
    cmd = $0
    if (cmd ~ /(ps -axo|machine_noise_check\.sh|awk -v self|sort -k|head -n)/) next
    printf "%7s %6s %6s %10s  %s\n", pid, cpu, mem, etime, cmd
  }
' | LC_ALL=C sort -k2,2nr -k3,3nr | head -n "$TOP_N" > "$TMP_TOP"

ps -axo $PS_FORMAT 2>/dev/null | awk \
  -v self="$SELF_PID" \
  -v cpu_t="$CPU_THRESHOLD" \
  -v mem_t="$MEM_THRESHOLD" \
  -v bg_cpu_t="$BACKGROUND_CPU_THRESHOLD" '
  BEGIN { IGNORECASE = 1 }
  $1 == self { next }
  {
    pid = $1
    cpu = $2 + 0
    mem = $3 + 0
    etime = $4
    $1 = $2 = $3 = $4 = ""
    sub(/^ +/, "", $0)
    cmd = $0
    if (cmd ~ /(ps -axo|machine_noise_check\.sh|awk -v self|sort -k|head -n)/) next

    reason = ""
    if (cpu >= cpu_t) reason = reason "high-cpu "
    if (mem >= mem_t) reason = reason "high-mem "
    if (cmd ~ /(flopt|floptimizer|codex|claude|cargo|rustc|clang|gcc|cc1|go|pytest|jest|pnpm|npm|yarn|bun|docker|podman|qemu|xcodebuild|swift|node|java|gradle|mvn|ray|chrome|firefox|safari|backupd|mdworker|mds|Spotlight)/ && cpu >= bg_cpu_t) {
      reason = reason "active-work "
    }

    if (reason != "") {
      printf "%-18s %7s %6.1f %6.1f %10s  %s\n", reason, pid, cpu, mem, etime, cmd
    }
  }
' | LC_ALL=C sort -k3,3nr -k4,4nr > "$TMP_NOISE"

echo "# Machine Noise Check"
echo
echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "logical_cpus=$CPUS"
if [ -n "${LOADS:-}" ]; then
  echo "load_averages=$LOADS"
fi
echo "cpu_threshold=${CPU_THRESHOLD}%"
echo "mem_threshold=${MEM_THRESHOLD}%"
echo "background_cpu_threshold=${BACKGROUND_CPU_THRESHOLD}%"
echo

echo "## Top Active Processes"
if [ -s "$TMP_TOP" ]; then
  printf "%7s %6s %6s %10s  %s\n" "pid" "cpu%" "mem%" "elapsed" "command"
  cat "$TMP_TOP"
else
  echo "No process data available."
fi
echo

echo "## Potential Noise Sources"
if [ -s "$TMP_NOISE" ]; then
  printf "%-18s %7s %6s %6s %10s  %s\n" "reason" "pid" "cpu%" "mem%" "elapsed" "command"
  cat "$TMP_NOISE"
  echo
  echo "status=NOISY"
  echo "recommendation=Pause new compute-heavy runs until unrelated work settles. Enter non-competing mode and use the time for code review, low-risk editing, refining hypotheses, reviewing captures, or literature review, then re-run benchmarks or profiles on a quieter machine state."
  exit 1
fi

echo "No obvious competing local work detected above the configured thresholds."
echo
echo "status=QUIET"
