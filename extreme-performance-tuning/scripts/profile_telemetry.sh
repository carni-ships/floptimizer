#!/usr/bin/env bash
set -euo pipefail

INTERVAL="${PROFILE_TELEMETRY_INTERVAL_SECONDS:-5}"
SAMPLES=0
TARGET_PATH="${PWD}"
STOP=0

usage() {
  cat <<'EOF'
Usage:
  profile_telemetry.sh [--once] [--interval SECONDS] [--samples N] [--target-path PATH]

Examples:
  profile_telemetry.sh --once
  profile_telemetry.sh --interval 5 --samples 3 --target-path .
  profile_telemetry.sh --interval 10 --target-path /var/lib/postgres

Notes:
  - Intended for broad system telemetry during serious profiling or benchmark runs.
  - Collects best-effort signals such as load, swap, memory pressure, disk usage,
    thermal or power hints, IO summaries, and accelerator telemetry when tools exist.
  - Keep the interval conservative. Over-collecting can perturb short benchmarks.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

compact_lines() {
  awk '
    NF {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if ($0 == "") next
      if (out != "") out = out " | "
      out = out $0
    }
    END {
      if (out != "") print out
    }
  '
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

disk_used_percent() {
  df -Pk "$TARGET_PATH" 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}

swap_used_mb() {
  if [ "$(uname -s)" = "Darwin" ] && have sysctl; then
    local swap_raw
    swap_raw="$(sysctl -n vm.swapusage 2>/dev/null | sed -n 's/.*used = \([0-9.][0-9.]*[KMG]\).*/\1/p')"
    if [ -n "$swap_raw" ]; then
      convert_swap_to_mb "$swap_raw"
      return
    fi
  elif have free; then
    free -m 2>/dev/null | awk '/^Swap:/ {print $3 + 0}'
    return
  fi

  echo "unknown"
}

memory_pressure_status() {
  local swap_mb="$1"

  if [ "$swap_mb" = "unknown" ]; then
    echo "unknown"
    return
  fi

  if [ "$swap_mb" -ge 4096 ]; then
    echo "high"
    return
  fi

  if [ "$swap_mb" -ge 1024 ]; then
    echo "elevated"
    return
  fi

  echo "normal"
}

memory_detail() {
  if [ "$(uname -s)" = "Darwin" ] && have memory_pressure; then
    memory_pressure 2>/dev/null | awk '
      /Pages free:/ {free=$3}
      /Pages purgeable:/ {purgeable=$3}
      /Swapins:/ {swapins=$2}
      /Swapouts:/ {swapouts=$2}
      END {
        if (free != "" || purgeable != "" || swapins != "" || swapouts != "") {
          printf "free_pages=%s purgeable_pages=%s swapins=%s swapouts=%s\n", free, purgeable, swapins, swapouts
        }
      }
    '
    return
  fi

  if have free; then
    free -m 2>/dev/null | awk '
      /^Mem:/ {mem_used=$3; mem_available=$7}
      /^Swap:/ {swap_used=$3; swap_total=$2}
      END {
        if (mem_used != "" || mem_available != "" || swap_used != "" || swap_total != "") {
          printf "mem_used_mb=%s mem_available_mb=%s swap_used_mb=%s swap_total_mb=%s\n", mem_used, mem_available, swap_used, swap_total
        }
      }
    '
    return
  fi

  if have vmstat; then
    vmstat 1 2 2>/dev/null | awk '
      NF >= 17 && $1 ~ /^[0-9]+$/ {line=$0}
      END {
        if (line != "") {
          split(line, a)
          printf "swpd_kb=%s si_kbps=%s so_kbps=%s bi=%s bo=%s cpu_idle=%s cpu_wait=%s\n", a[3], a[7], a[8], a[9], a[10], a[15], a[16]
        }
      }
    '
  fi
}

power_source() {
  if [ "$(uname -s)" = "Darwin" ] && have pmset; then
    pmset -g batt 2>/dev/null | sed -n "s/^Now drawing from '\\(.*\\)'$/\\1/p" | head -n 1
  fi
}

thermal_summary() {
  if [ "$(uname -s)" = "Darwin" ] && have pmset; then
    pmset -g therm 2>/dev/null \
      | sed 's/^Note:[[:space:]]*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
      | compact_lines
    return
  fi

  if have sensors; then
    sensors 2>/dev/null \
      | awk '/temp|fan|Package id|Composite|Tctl|Tdie|edge|junction|mem/ {print}' \
      | head -n 12 \
      | compact_lines
    return
  fi

  if have osx-cpu-temp; then
    osx-cpu-temp 2>/dev/null | compact_lines
    return
  fi
}

io_summary() {
  if ! have iostat; then
    return
  fi

  if [ "$(uname -s)" = "Darwin" ]; then
    iostat -Id 1 2 2>/dev/null | tail -n 3 | compact_lines
    return
  fi

  iostat -dx 1 2 2>/dev/null | tail -n 10 | compact_lines
}

gpu_summary() {
  if have nvidia-smi; then
    nvidia-smi \
      --query-gpu=index,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw,pstate \
      --format=csv,noheader,nounits \
      2>/dev/null \
      | compact_lines
    return
  fi

  if have rocm-smi; then
    rocm-smi --showtemp --showuse --showmemuse --csv 2>/dev/null | compact_lines
  fi
}

available_sources() {
  local sources=()

  for tool in uptime df iostat pmset memory_pressure free vmstat sensors osx-cpu-temp nvidia-smi rocm-smi; do
    if have "$tool"; then
      sources+=("$tool")
    fi
  done

  if [ "${#sources[@]}" -eq 0 ]; then
    echo "none"
    return
  fi

  printf '%s\n' "${sources[*]}"
}

emit_sample() {
  local sample_id="$1"
  local timestamp
  local loads
  local disk_pct
  local swap_mb
  local pressure
  local mem_detail
  local power
  local thermal
  local io
  local gpu

  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  loads="$(load_averages || true)"
  disk_pct="$(disk_used_percent || true)"
  swap_mb="$(swap_used_mb || true)"
  pressure="$(memory_pressure_status "${swap_mb:-unknown}")"
  mem_detail="$(memory_detail || true)"
  power="$(power_source || true)"
  thermal="$(thermal_summary || true)"
  io="$(io_summary || true)"
  gpu="$(gpu_summary || true)"

  echo "## Sample $sample_id"
  echo "timestamp=$timestamp"
  echo "load_averages=${loads:-unknown}"
  echo "logical_cpus=$(logical_cpus)"
  echo "target_path=$TARGET_PATH"
  echo "disk_used_percent=${disk_pct:-unknown}"
  echo "swap_used_mb=${swap_mb:-unknown}"
  echo "memory_pressure=${pressure:-unknown}"
  echo "memory_detail=${mem_detail:-unavailable}"
  echo "power_source=${power:-unknown}"
  echo "thermal=${thermal:-unavailable}"
  echo "io=${io:-unavailable}"
  echo "gpu=${gpu:-unavailable}"
  echo
}

while [ $# -gt 0 ]; do
  case "$1" in
    --once)
      SAMPLES=1
      shift
      ;;
    --interval)
      if [ $# -lt 2 ]; then
        echo "--interval requires a value" >&2
        exit 2
      fi
      INTERVAL="$2"
      shift 2
      ;;
    --samples)
      if [ $# -lt 2 ]; then
        echo "--samples requires a value" >&2
        exit 2
      fi
      SAMPLES="$2"
      shift 2
      ;;
    --target-path)
      if [ $# -lt 2 ]; then
        echo "--target-path requires a value" >&2
        exit 2
      fi
      TARGET_PATH="$2"
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

if [ ! -e "$TARGET_PATH" ]; then
  echo "target path does not exist: $TARGET_PATH" >&2
  exit 2
fi

TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd || printf '%s\n' "$TARGET_PATH")"

trap 'STOP=1' INT TERM

echo "# Profiling Telemetry"
echo
echo "timestamp_started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "platform=$(uname -s) $(uname -m)"
echo "interval_seconds=$INTERVAL"
echo "samples=${SAMPLES:-0}"
echo "target_path=$TARGET_PATH"
echo "available_sources=$(available_sources)"
echo

sample_id=1
while [ "$STOP" -eq 0 ]; do
  emit_sample "$sample_id"

  if [ "$SAMPLES" -gt 0 ] && [ "$sample_id" -ge "$SAMPLES" ]; then
    break
  fi

  sample_id=$((sample_id + 1))
  sleep "$INTERVAL"
done
