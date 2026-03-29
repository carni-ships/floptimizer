# Exemplars

Use this file after the bottleneck class is known and you want proven design ideas from fast, widely used codebases. Treat these repos as pattern sources, not as templates to copy blindly.

## Contents

- How To Use This Catalog
- Domain Files
- Selection Heuristic
- Suggested Study Order

## How To Use This Catalog

- Pick the domain file that matches the bottleneck class.
- Read the repo README and a few hot-path source files, not the entire project.
- Extract the optimization idea, then revalidate it on the target system.
- Treat benchmark claims in READMEs as hypotheses until reproduced locally.

## Domain Files

- [`exemplars-local-and-data.md`](exemplars-local-and-data.md): local tooling, allocators, SIMD, parsing, analytics, and storage engines
- [`exemplars-concurrency-and-distributed.md`](exemplars-concurrency-and-distributed.md): runtimes, distributed systems, proving clusters, and validator pipelines
- [`exemplars-apple-and-hardware.md`](exemplars-apple-and-hardware.md): Apple Silicon CPU paths, Metal offload, and hardware-oriented teaching references

## Selection Heuristic

- Search and traversal bottleneck: start with `fff.nvim`, `ripgrep`, `fd`
- Python CLI or tooling bottleneck: start with `uv`, `ruff`
- Allocator or fragmentation bottleneck: start with `jemalloc`, `mimalloc`, `tcmalloc`
- String or parsing bottleneck: start with `StringZilla`, `simdjson`, `FlatBuffers`, `serde`
- Vector math or ANN bottleneck: start with `NumKong`, `USearch`, `Highway`, `OpenBLAS`
- Columnar or analytical execution bottleneck: start with `Apache Arrow`, `DuckDB`, `Polars`, `DataFusion`
- Embedded or storage-engine bottleneck: start with `SQLite`, `RocksDB`
- Hashing or concurrency bottleneck: start with `Abseil`, `folly`, `rayon`, `crossbeam`, `ForkUnion`, `tokio`
- Compression or wire-format bottleneck: start with `zstd`, `Cap'n Proto`, `FlatBuffers`
- Distributed throughput or stream-processing bottleneck: start with `Seastar`, `ScyllaDB`, `Redpanda`, `NATS Server`, `FoundationDB`, `ClickHouse`
- Distributed database or consensus-backed storage bottleneck: start with `FoundationDB`, `TiKV`, `CockroachDB`, `ScyllaDB`
- Distributed proving or embarrassingly parallel cluster bottleneck: start with `DIZK`, `Ray`, then compare against the hardware-accelerated local-kernel references
- Blockchain execution or validator bottleneck: start with `Firedancer`, `Agave`, `Reth`, `Erigon`, `Sui`, `Aptos`
- Apple Silicon CPU intrinsic bottleneck: start with `amx-benchmarks`, `simdjson`, the Apple CPU optimization guide, then the Dougall J NEON write-up
- Apple Silicon or Metal offload bottleneck: start with `metal-msm-gpu-acceleration`, `metal-poc`, `metal-fft`, `node-zk-accelerate`

## Suggested Study Order

- New to performance engineering: start with `SQLite`, `simdjson`, `mimalloc`, then `DuckDB` or `Polars`
- Interested in low-level CPU work: start with `StringZilla`, `NumKong`, `Highway`, `OpenBLAS`, `FFTW`
- Interested in systems and concurrency: start with `jemalloc`, `tcmalloc`, `Abseil`, `folly`, `tokio`, `rayon`
- Interested in data engines: start with `Apache Arrow`, `DuckDB`, `DataFusion`, `RocksDB`
