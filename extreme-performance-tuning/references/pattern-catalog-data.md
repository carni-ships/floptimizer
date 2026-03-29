# Pattern Catalog: Data And Storage

Use this file when the bottleneck is in coordination costs, metadata structures, serialization, specialization, caching, or storage layout.

## Contents

- 9. Eliminate Shared-State Pain
- 10. Probe Metadata First, Payload Later
- 11. Zero-Copy Only When It Really Removes Work
- 12. Replace Generality With Specialization Carefully
- 13. Use Auto-Tuning When The Search Space Is Real
- 14. Cache Results, Not Mistakes
- 15. Trees, LSMs, And Layouts Encode Tradeoffs
- 16. Benchmark Claims Are Inputs, Not Conclusions

## 9. Eliminate Shared-State Pain

Pattern:

- Shorten critical sections.
- Avoid global mutable structures on the hot path.
- Prefer sharding, ownership transfer, or scoped parallelism.

Seen in:

- `ForkUnion`
- `tokio`
- `rayon`
- `crossbeam`

Best for:

- poor multicore scaling
- scheduler contention
- allocator contention
- queue buildup under load

## 10. Probe Metadata First, Payload Later

Pattern:

- Keep compact side metadata to avoid touching full payloads until necessary.
- Use signatures, tags, bitmaps, or probe groups to rule out misses cheaply.
- Treat branch prediction and cache behavior as first-class concerns.

Seen in:

- `Abseil`
- `simdjson`
- `DuckDB`
- `RocksDB`

Best for:

- hash tables
- parsing front-ends
- indexed query execution
- bloom-filter-like prechecks

## 11. Zero-Copy Only When It Really Removes Work

Pattern:

- Avoid encode-decode, copies, and transient buffers only when they are proven costs.
- Align APIs and storage with the target access path.
- Make lifetime and ownership rules explicit.

Seen in:

- `Cap'n Proto`
- `FlatBuffers`
- `Apache Arrow`
- `uWebSockets`

Best for:

- high-throughput messaging
- binary protocols
- parsing-heavy services
- storage engines

## 12. Replace Generality With Specialization Carefully

Pattern:

- Introduce specialized fast paths for common cases.
- Keep the generic path available for correctness and maintainability.
- Specialize only for workloads that matter in practice.

Seen in:

- `ripgrep`
- `ruff`
- `StringZilla`
- `zstd`

Best for:

- dominant common-case inputs
- hot regex or parsing paths
- frequently repeated data shapes

## 13. Use Auto-Tuning When The Search Space Is Real

Pattern:

- Generate or choose from multiple valid execution strategies.
- Benchmark on the target hardware or data shape.
- Persist the winning plan when that makes sense.

Seen in:

- `FFTW`
- `DuckDB`
- `OpenBLAS`

Best for:

- transforms
- kernel selection
- query plans
- workloads that vary sharply by hardware or shape

## 14. Cache Results, Not Mistakes

Pattern:

- Cache expensive work only after confirming recomputation is material.
- Bound cache size, invalidation rules, and cold-start behavior.
- Measure hit rate and tail latency impact.

Seen in:

- `uv`
- `fff.nvim`
- `DuckDB`

Best for:

- dependency resolution
- file search
- repeated plans or parsed artifacts

## 15. Trees, LSMs, And Layouts Encode Tradeoffs

Pattern:

- Storage structures are performance policies: reads, writes, amplification, and memory overhead all move together.
- Choose B-trees, LSMs, columnar buffers, or append logs based on measured access patterns.
- Tune compaction, indexing, and caching only after identifying the dominant workload.

Seen in:

- `SQLite`
- `RocksDB`
- `Apache Arrow`
- `DuckDB`

Best for:

- embedded databases
- key-value stores
- analytics engines
- storage-layer bottlenecks

## 16. Benchmark Claims Are Inputs, Not Conclusions

Pattern:

- Treat README benchmark tables as idea generators.
- Reproduce the workload on the target machine with target data.
- Keep the optimization only if the win survives realistic validation.

Seen in:

- every serious performance project

Best for:

- avoiding cargo-cult tuning
- resisting premature rewrites
- keeping the skill honest
