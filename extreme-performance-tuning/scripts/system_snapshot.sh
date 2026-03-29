#!/usr/bin/env bash
set -euo pipefail

echo "# Performance Environment Snapshot"
echo
echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "cwd=$(pwd)"
echo "user=$(whoami)"
echo "shell=${SHELL:-unknown}"
echo

echo "## OS"
uname -a || true
echo

if command -v sw_vers >/dev/null 2>&1; then
  echo "## macOS"
  sw_vers || true
  echo
fi

if command -v lsb_release >/dev/null 2>&1; then
  echo "## Distribution"
  lsb_release -a 2>/dev/null || true
  echo
fi

echo "## CPU"
if command -v sysctl >/dev/null 2>&1; then
  sysctl -n machdep.cpu.brand_string 2>/dev/null || true
  sysctl -n hw.ncpu 2>/dev/null | awk '{print "logical_cpus=" $1}' || true
fi
if command -v lscpu >/dev/null 2>&1; then
  lscpu || true
fi
echo

echo "## Memory"
if command -v vm_stat >/dev/null 2>&1; then
  vm_stat || true
fi
if command -v free >/dev/null 2>&1; then
  free -h || true
fi
echo

if command -v memory_pressure >/dev/null 2>&1; then
  echo "## Memory Pressure"
  memory_pressure 2>/dev/null | head -n 16 || true
  echo
fi

echo "## Storage"
df -Pk . 2>/dev/null || true
echo

if command -v iostat >/dev/null 2>&1; then
  echo "## IO Snapshot"
  if [ "$(uname -s)" = "Darwin" ]; then
    iostat -Id 1 2 2>/dev/null || true
  else
    iostat -dx 1 2 2>/dev/null || true
  fi
  echo
fi

echo "## Thermal And Power"
if command -v pmset >/dev/null 2>&1; then
  pmset -g batt 2>/dev/null || true
  pmset -g therm 2>/dev/null || true
fi
if command -v sensors >/dev/null 2>&1; then
  sensors 2>/dev/null || true
fi
if command -v osx-cpu-temp >/dev/null 2>&1; then
  osx-cpu-temp 2>/dev/null || true
fi
echo

echo "## GPU And Accelerators"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw,pstate --format=csv 2>/dev/null || true
fi
if command -v rocm-smi >/dev/null 2>&1; then
  rocm-smi --showtemp --showuse --showmemuse --csv 2>/dev/null || true
fi
echo

echo "## Ulimits"
ulimit -a || true
echo

echo "## Tool Versions"
for tool in git python3 node npm pnpm yarn bun go rustc cargo java javac mvn gradle gcc clang cmake make ninja docker docker-compose psql mysql redis-cli sqlite3; do
  if command -v "$tool" >/dev/null 2>&1; then
    version="$("$tool" --version 2>&1 | head -n 1 || true)"
    if [ -z "$version" ]; then
      version="$("$tool" -V 2>&1 | head -n 1 || true)"
    fi
    echo "$tool=${version:-available}"
  fi
done
echo

echo "## Git"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git rev-parse --show-toplevel || true
  git rev-parse --abbrev-ref HEAD || true
  git rev-parse HEAD || true
  git status --short || true
else
  echo "not a git repository"
fi
