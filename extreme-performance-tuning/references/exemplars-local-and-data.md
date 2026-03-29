# Exemplars: Local And Data

Use this file when the bottleneck is in local compute, traversal, parsing, data layout, analytics, or storage. Treat these repos as pattern sources, not as templates to copy blindly.

## Contents

- Search, Traversal, and Developer Tooling
- Memory Allocators and Allocation Strategy
- Data Layout, SIMD, and Numeric Kernels
- Parsing, Serialization, and Zero-Copy Data Movement
- Search, Indexes, and Compact Data Structures
- Columnar Data and Analytics
- Databases and Storage Engines

## Search, Traversal, and Developer Tooling

### fff.nvim

- Repo: `https://github.com/dmtrKovalenko/fff.nvim`
- Consult when: file search, fuzzy matching, AI-agent repo navigation, low-latency indexing, or a hybrid Rust plus higher-level frontend architecture is relevant.
- Learn from it: aggressive search-path specialization, ranking heuristics, memory-backed search context, and moving performance-critical logic into a native core while preserving a good user-facing shell.
- Watch out for: optimizing the UX layer before confirming that traversal, ranking, or IO is the real bottleneck.

### uv

- Repo: `https://github.com/astral-sh/uv`
- Consult when: package resolution, artifact caching, CLI startup, dependency graph work, or replacing a slow scripting toolchain with a fast native binary.
- Learn from it: cache-centric design, high-throughput dependency operations, careful end-to-end latency focus, and Rust as a drop-in accelerator for a widely used workflow.
- Watch out for: assuming a native rewrite is justified before profiling the original bottleneck.

### ruff

- Repo: `https://github.com/astral-sh/ruff`
- Consult when: static analysis, formatter/linter performance, AST-heavy pipelines, or "replace many Python passes with one native pass" is the pattern.
- Learn from it: tight parser and visitor pipelines, fast path coverage across many rules, and product-level focus on total wall-clock savings rather than microbenchmarks alone.
- Watch out for: trading maintainability for speed in rule systems that are not actually hot.

### ripgrep

- Repo: `https://github.com/BurntSushi/ripgrep`
- Consult when: recursive filesystem traversal, text search, ignore matching, regex-heavy workloads, or command-line search UX is relevant.
- Learn from it: smart defaults, IO-aware traversal, regex engine selection, work partitioning, and avoiding unnecessary reads.
- Watch out for: overfitting to one dataset or assuming mmap always wins.

### fd

- Repo: `https://github.com/sharkdp/fd`
- Consult when: directory walking, ignore-aware traversal, or replacing slower legacy tooling with a better traversal pipeline.
- Learn from it: low-friction UX combined with fast walking, pruning, and filtering.
- Watch out for: copying traversal tricks without measuring filesystem behavior on the target OS.

## Memory Allocators and Allocation Strategy

### jemalloc

- Repo: `https://github.com/jemalloc/jemalloc`
- Consult when: fragmentation, allocator contention, page reuse, or multithreaded allocation behavior show up in profiles.
- Learn from it: arenas, thread-local caching, slab-style size classes, and tuning around fragmentation versus throughput.
- Watch out for: swapping allocators without measuring tail latency, RSS, and fragmentation after the change.

### mimalloc

- Repo: `https://github.com/microsoft/mimalloc`
- Consult when: allocator overhead, fragmentation, multithreaded allocation, or memory-locality issues are visible in profiles.
- Learn from it: allocator design, thread-local fast paths, and fragmentation-aware memory handling.
- Watch out for: allocator swapping before proving allocation behavior is actually dominant.

### tcmalloc

- Repo: `https://github.com/google/tcmalloc`
- Consult when: per-thread allocation cost, size-class behavior, or allocator scalability under heavy concurrency matter.
- Learn from it: fast-path allocation, size-class design, and per-thread or per-CPU caching strategies.
- Watch out for: assuming the allocator is the bottleneck when object churn or poor lifetime design is the real issue.

## Data Layout, SIMD, and Numeric Kernels

### StringZilla

- Repo: `https://github.com/ashvardanian/StringZilla`
- Consult when: string search, hashing, edit distance, sorting, memory operations, Unicode-heavy text, or bioinformatics-style workloads are hot.
- Learn from it: multi-versioned SIMD dispatch, tight hand-tuned kernels, CPU/GPU split thinking, and treating text processing as a data-parallel problem.
- Watch out for: architecture-specific kernels that complicate portability or debuggability without enough payoff.

### NumKong

- Repo: `https://github.com/ashvardanian/NumKong`
- Consult when: dot products, distances, mixed-precision vector math, ANN preprocessing, or numeric kernels dominate runtime.
- Learn from it: explicit SIMD-first API design, mixed-precision tradeoffs, and portable acceleration across x86, Arm, RISC-V, and WASM.
- Watch out for: hidden numerical stability costs or precision regressions.

### simdjson

- Repo: `https://github.com/simdjson/simdjson`
- Consult when: parsing dominates, branches are unpredictable, or you need staged pipelines that turn irregular text into structured data quickly.
- Learn from it: staged parsing, branch reduction, data-parallel token discovery, and cache-friendly scanning.
- Watch out for: heroic parsing work on a path where transport, allocation, or downstream processing dominates.

### Highway

- Repo: `https://github.com/google/highway`
- Consult when: you need SIMD but also need portability across multiple instruction sets.
- Learn from it: performance-portable vector abstractions, runtime dispatch, and keeping SIMD code maintainable.
- Watch out for: choosing a portability layer when a scalar algorithmic fix would dwarf SIMD gains.

### FFTW

- Repo: `https://github.com/FFTW/fftw3`
- Consult when: transform-heavy workloads, auto-tuned kernels, or hardware-specific planning decisions matter.
- Learn from it: runtime planning, cache-aware decomposition, and selecting kernels for the target hardware and input shapes.
- Watch out for: benchmarking only one input shape when transform performance can vary sharply by size.

### Eigen

- Repo: `https://gitlab.com/libeigen/eigen`
- Consult when: linear algebra, expression fusion, temporary elimination, or compile-time shape knowledge matter.
- Learn from it: expression templates, lazy evaluation, and compile-time specialization that removes needless intermediate work.
- Watch out for: template complexity that obscures whether the algorithm itself is the main problem.

### OpenBLAS

- Repo: `https://github.com/OpenMathLib/OpenBLAS`
- Consult when: dense linear algebra dominates and you need a reference for architecture-specific kernels and threading.
- Learn from it: hand-tuned assembly kernels, SIMD specialization, and balancing parallelism with memory bandwidth.
- Watch out for: comparing BLAS kernels unfairly with mismatched matrix shapes, layouts, or thread counts.

### amx-benchmarks

- Repo: `https://github.com/philipturner/amx-benchmarks`
- Consult when: Apple Silicon matrix acceleration, tiling strategy, AMX-oriented kernel structure, or CPU-side alternatives to GPU offload are relevant.
- Learn from it: tile sizing, matrix-oriented refactors, and how layout and scheduling changes around matrix operations can outperform more generic kernels.
- Watch out for: assuming AMX-style wins transfer directly to non-matrix-shaped workloads.

## Parsing, Serialization, and Zero-Copy Data Movement

### FlatBuffers

- Repo: `https://github.com/google/flatbuffers`
- Consult when: serialization cost, copy avoidance, schema-driven binary layouts, or memory-mapped access is central.
- Learn from it: zero-copy reads, direct buffer access, and balancing schema constraints against runtime overhead.
- Watch out for: migrating wire formats before proving serialization and deserialization are material costs.

### serde

- Repo: `https://github.com/serde-rs/serde`
- Consult when: Rust serialization, zero-copy deserialization, generic format abstraction, or compile-time code generation matters.
- Learn from it: trait-driven specialization, derived code generation, and keeping high-level APIs while producing efficient serialization paths.
- Watch out for: generic abstraction layers that seem expensive in theory but are not actually hot in measurements.

### Cap'n Proto

- Repo: `https://github.com/capnproto/capnproto`
- Consult when: serialization, zero-copy data access, or RPC overhead is a large part of the request path.
- Learn from it: schema-driven zero-copy design and minimizing encode/decode work.
- Watch out for: changing protocols before measuring whether serialization is dominant.

### zstd

- Repo: `https://github.com/facebook/zstd`
- Consult when: compression cost, decompression speed, dictionary use, or wire-storage tradeoffs dominate.
- Learn from it: flexible speed-ratio tradeoffs, staged compression strategies, and tuning around real deployment constraints.
- Watch out for: compressing tiny payloads or compressing on a latency-critical path where bandwidth is not the bottleneck.

## Search, Indexes, and Compact Data Structures

### USearch

- Repo: `https://github.com/ashvardanian/USearch`
- Consult when: vector search, ANN indexes, distance kernels, compact search structures, or cross-language embeddings and search libraries are involved.
- Learn from it: compact native cores, broad language bindings, and designing high-performance primitives that are easy to embed.
- Watch out for: importing ANN complexity before confirming the current bottleneck is actually search latency or index size.

### Abseil

- Repo: `https://github.com/abseil/abseil-cpp`
- Consult when: hash table performance, utility-layer overhead, or high-load-factor map behavior matters.
- Learn from it: SwissTable-style metadata layouts, SIMD-assisted probing, and pragmatic low-overhead utility design.
- Watch out for: swapping containers without measuring workload-specific key distributions and mutation patterns.

## Columnar Data and Analytics

### Apache Arrow

- Repo: `https://github.com/apache/arrow`
- Consult when: columnar memory layout, zero-copy interchange, vectorized kernels, or dictionary encoding is relevant.
- Learn from it: cache-aligned buffers, language-agnostic data interchange, and making columnar layout pay off across a full stack.
- Watch out for: adopting a columnar format for workloads that are fundamentally point-lookups or mutation-heavy.

### Polars

- Repo: `https://github.com/pola-rs/polars`
- Consult when: vectorized dataframe workloads, Arrow-style memory layout, query optimization, or fast data wrangling pipelines are relevant.
- Learn from it: columnar access, lazy execution, predicate pushdown, and reducing Python overhead with a native engine.
- Watch out for: migrating stacks just for speed when the current workload is too small to benefit.

### DuckDB

- Repo: `https://github.com/duckdb/duckdb`
- Consult when: analytical queries, vectorized execution, in-process data engines, or tight columnar operator pipelines matter.
- Learn from it: vectorized operators, cache-aware batching, and keeping the working set small.
- Watch out for: borrowing analytical-engine patterns for OLTP or latency-sensitive request paths where they do not fit.

### DataFusion

- Repo: `https://github.com/apache/datafusion`
- Consult when: embeddable query engines, Arrow-native execution, or modular query planning is relevant.
- Learn from it: clean separation of planner and executor, columnar execution, and composable performance-aware abstractions.
- Watch out for: framework-building when a focused query fix would solve the problem.

## Databases and Storage Engines

### SQLite

- Repo: `https://github.com/sqlite/sqlite`
- Consult when: embedded databases, B-trees, transaction logging, compact systems engineering, or "small codebase, huge real-world performance" is the lesson.
- Learn from it: WAL tradeoffs, B-tree discipline, careful cache usage, and whole-system engineering rigor.
- Watch out for: cargo-culting page or journaling settings without workload-specific validation.

### RocksDB

- Repo: `https://github.com/facebook/rocksdb`
- Consult when: write-heavy key-value stores, LSM tuning, compaction pressure, or storage-cache tradeoffs dominate.
- Learn from it: bloom filters, compaction strategy, tiered storage, block cache design, and tuning around write amplification.
- Watch out for: enabling many tuning knobs before identifying whether reads, writes, compaction, or amplification is the real problem.
