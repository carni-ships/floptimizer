#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  telemetry_summary.sh TELEMETRY_FILE
  telemetry_summary.sh --input TELEMETRY_FILE

Summarizes broad telemetry captured by profile_telemetry.sh into a smaller set of
signals and warnings that are easier to compare across runs.
EOF
}

INPUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --input)
      if [ $# -lt 2 ]; then
        echo "--input requires a value" >&2
        exit 2
      fi
      INPUT="$2"
      shift 2
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
      if [ -n "$INPUT" ]; then
        echo "Unexpected extra positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      INPUT="$1"
      shift
      ;;
  esac
done

if [ -z "$INPUT" ]; then
  usage >&2
  exit 2
fi

if [ ! -f "$INPUT" ]; then
  echo "telemetry file not found: $INPUT" >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  cat <<EOF
# Telemetry Summary

telemetry_file=$INPUT
sample_count=unknown
status=unknown
warning=python3 not available; telemetry summary fallback only
EOF
  exit 0
fi

python3 - "$INPUT" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="ignore").splitlines()

sample_count = 0
load_peaks = []
disk_peaks = []
swap_values = []
pressure_rank = {"unknown": 0, "normal": 1, "elevated": 2, "high": 3}
pressure_name = {value: key for key, value in pressure_rank.items()}
peak_pressure = 0
thermal_signals = []
gpu_signals = []
power_sources = []
warnings = []

def maybe_float(value: str):
    try:
        return float(value)
    except ValueError:
        return None

def maybe_int(value: str):
    try:
        return int(float(value))
    except ValueError:
        return None

def thermal_constrained(signal: str) -> bool:
    lowered = signal.lower()
    for field in ("cpu_speed_limit", "gpu_speed_limit"):
        match = re.search(field + r"\s*=\s*(\d+)", lowered)
        if match and int(match.group(1)) < 100:
            return True
    return bool(re.search(r"(throttl|thermal[^|]*pressure|thermal[^|]*limit|performance[^|]*limit)", lowered))

for line in text:
    if line.startswith("## Sample "):
        sample_count += 1
        continue

    if "=" not in line:
        continue

    key, value = line.split("=", 1)
    key = key.strip()
    value = value.strip()

    if key == "load_averages":
        first = value.split()
        if first:
            load_value = maybe_float(first[0])
            if load_value is not None:
                load_peaks.append(load_value)
    elif key == "disk_used_percent":
        disk_value = maybe_int(value)
        if disk_value is not None:
            disk_peaks.append(disk_value)
    elif key == "swap_used_mb":
        swap_value = maybe_int(value)
        if swap_value is not None:
            swap_values.append(swap_value)
    elif key == "memory_pressure":
        peak_pressure = max(peak_pressure, pressure_rank.get(value, 0))
    elif key == "thermal" and value and value != "unavailable":
        thermal_signals.append(value)
    elif key == "gpu" and value and value != "unavailable":
        gpu_signals.append(value)
    elif key == "power_source" and value and value != "unknown":
        power_sources.append(value)

peak_load = max(load_peaks) if load_peaks else None
peak_disk = max(disk_peaks) if disk_peaks else None
first_swap = swap_values[0] if swap_values else None
peak_swap = max(swap_values) if swap_values else None
peak_pressure_name = pressure_name.get(peak_pressure, "unknown")

thermal_flag = any(thermal_constrained(signal) for signal in thermal_signals)
thermal_hint = thermal_signals[-1] if thermal_signals else "unavailable"
gpu_hint = gpu_signals[-1] if gpu_signals else "unavailable"
power_hint = power_sources[-1] if power_sources else "unknown"

status = "stable"
if peak_pressure_name == "high":
    status = "constrained"
elif peak_pressure_name == "elevated":
    status = "review"

if peak_swap is not None and peak_swap >= 4096:
    status = "constrained"
elif peak_swap is not None and peak_swap >= 1024 and status == "stable":
    status = "review"

if peak_disk is not None and peak_disk >= 95:
    status = "constrained"
elif peak_disk is not None and peak_disk >= 90 and status == "stable":
    status = "review"

if thermal_flag:
    status = "constrained"

if peak_pressure_name == "high":
    warnings.append("high memory pressure observed")
elif peak_pressure_name == "elevated":
    warnings.append("elevated memory pressure observed")

if peak_swap is not None and peak_swap >= 4096:
    warnings.append("swap use exceeded 4096 MB")
elif peak_swap is not None and peak_swap >= 1024:
    warnings.append("swap use exceeded 1024 MB")

if peak_disk is not None and peak_disk >= 95:
    warnings.append("disk usage exceeded 95 percent")
elif peak_disk is not None and peak_disk >= 90:
    warnings.append("disk usage exceeded 90 percent")

if thermal_flag:
    warnings.append("thermal or power limiting signals observed")

print("# Telemetry Summary")
print()
print(f"telemetry_file={path}")
print(f"sample_count={sample_count}")
print(f"max_load_1m={peak_load if peak_load is not None else 'unknown'}")
print(f"first_swap_used_mb={first_swap if first_swap is not None else 'unknown'}")
print(f"peak_swap_used_mb={peak_swap if peak_swap is not None else 'unknown'}")
print(f"peak_memory_pressure={peak_pressure_name}")
print(f"max_disk_used_percent={peak_disk if peak_disk is not None else 'unknown'}")
print(f"power_source_last={power_hint}")
print(f"thermal_signal={thermal_hint}")
print(f"gpu_signal={gpu_hint}")
print(f"status={status}")
if warnings:
    for warning in warnings:
        print(f"warning={warning}")
else:
    print("warning=none")
PY
