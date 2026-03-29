#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-./_exemplars}"

REPOS=(
  "https://github.com/dmtrKovalenko/fff.nvim"
  "https://github.com/astral-sh/uv"
  "https://github.com/astral-sh/ruff"
  "https://github.com/BurntSushi/ripgrep"
  "https://github.com/sharkdp/fd"
  "https://github.com/jemalloc/jemalloc"
  "https://github.com/microsoft/mimalloc"
  "https://github.com/google/tcmalloc"
  "https://github.com/zkonduit/metal-msm-gpu-acceleration"
  "https://github.com/Digital-Defiance/node-zk-accelerate"
  "https://github.com/ingonyama-zk/metal-poc"
  "https://github.com/philipturner/metal-fft"
  "https://github.com/ashvardanian/USearch"
  "https://github.com/ashvardanian/StringZilla"
  "https://github.com/ashvardanian/NumKong"
  "https://github.com/ashvardanian/ForkUnion"
  "https://github.com/ashvardanian/less_slow.cpp"
  "https://github.com/simdjson/simdjson"
  "https://github.com/google/flatbuffers"
  "https://github.com/serde-rs/serde"
  "https://github.com/google/highway"
  "https://github.com/apache/arrow"
  "https://github.com/philipturner/amx-benchmarks"
  "https://github.com/tokio-rs/tokio"
  "https://github.com/uNetworking/uWebSockets"
  "https://github.com/facebook/zstd"
  "https://github.com/capnproto/capnproto"
  "https://github.com/pola-rs/polars"
  "https://github.com/duckdb/duckdb"
  "https://github.com/apache/datafusion"
  "https://github.com/sqlite/sqlite"
  "https://github.com/facebook/rocksdb"
  "https://github.com/FFTW/fftw3"
  "https://gitlab.com/libeigen/eigen.git"
  "https://github.com/OpenMathLib/OpenBLAS"
  "https://github.com/abseil/abseil-cpp"
  "https://github.com/facebook/folly"
  "https://github.com/rayon-rs/rayon"
  "https://github.com/crossbeam-rs/crossbeam"
  "https://github.com/scylladb/seastar"
  "https://github.com/scylladb/scylladb"
  "https://github.com/redpanda-data/redpanda"
  "https://github.com/nats-io/nats-server"
  "https://github.com/apple/foundationdb"
  "https://github.com/ClickHouse/ClickHouse"
  "https://github.com/tikv/tikv"
  "https://github.com/ray-project/ray"
  "https://github.com/cockroachdb/cockroach"
  "https://github.com/scipr-lab/dizk"
  "https://github.com/anza-xyz/agave"
  "https://github.com/firedancer-io/firedancer"
  "https://github.com/paradigmxyz/reth"
  "https://github.com/erigontech/erigon"
  "https://github.com/MystenLabs/sui"
  "https://github.com/aptos-labs/aptos-core"
)

if [ "${1-}" = "--list" ]; then
  printf '%s\n' "${REPOS[@]}"
  exit 0
fi

mkdir -p "$DEST"

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  target="$DEST/$name"

  if [ -d "$target/.git" ]; then
    echo "Updating $name"
    git -C "$target" pull --ff-only
  else
    echo "Cloning $name"
    git clone --depth 1 "$repo" "$target"
  fi
done
