# Pattern Catalog: Core

Use this file when the bottleneck is in local code shape, data movement, vectorization, or pipeline design.

## Contents

- 1. Native Core, Thin Shell
- 2. Batch More, Cross Boundaries Less
- 3. Data Layout Beats Clever Code
- 4. Specialize Allocation and Ownership
- 5. Multi-Version The Hot Path
- 6. Refactor For Better Instruction Selection
- 7. Let The Planner Or Compiler Fuse Work
- 8. Optimize The Whole Pipeline, Not Just The Kernel

## 1. Native Core, Thin Shell

Pattern:

- Keep the UX, API glue, and orchestration ergonomic.
- Move the hottest logic into a compact native core.
- Cross the language boundary sparingly and in coarse batches.

Seen in:

- `fff.nvim`
- `uv`
- `ruff`
- `USearch`
- `Polars`

Best for:

- tools written in slow startup or interpreter-heavy environments
- repeated parsing, scanning, or indexing
- large user-visible latency gaps caused by hot loops

## 2. Batch More, Cross Boundaries Less

Pattern:

- Turn many small calls into fewer larger calls.
- Reduce syscalls, RPCs, DB round-trips, lock acquisitions, and allocator traffic.
- Prefer streaming and chunked processing over row-at-a-time work.

Seen in:

- `DuckDB`
- `DataFusion`
- `uWebSockets`
- `zstd`

Best for:

- DB-bound paths
- chatty microservices
- filesystem-heavy tools
- serialization-heavy request paths

## 3. Data Layout Beats Clever Code

Pattern:

- Favor contiguous memory, predictable iteration, and fewer pointer indirections.
- Organize data around access patterns, not around idealized object models.
- Keep the hot working set small.

Seen in:

- `DuckDB`
- `Polars`
- `simdjson`
- `Apache Arrow`

Best for:

- CPU cache misses
- analytical pipelines
- parsing and transformation
- high-allocation object graphs

## 4. Specialize Allocation and Ownership

Pattern:

- Build fast paths around common object sizes and lifetimes.
- Keep metadata local to the allocation strategy.
- Separate allocator scalability from application-level churn problems.

Seen in:

- `jemalloc`
- `mimalloc`
- `tcmalloc`
- `folly`

Best for:

- allocator contention
- fragmentation
- short-lived object storms
- poor locality from generic ownership models

## 5. Multi-Version The Hot Path

Pattern:

- Provide multiple implementations for different CPU capabilities or input shapes.
- Select the fast path at runtime or compile time.
- Keep a clean fallback path.

Seen in:

- `StringZilla`
- `NumKong`
- `Highway`
- `simdjson`

Best for:

- numeric kernels
- parsing
- string processing
- workloads with clear ISA-dependent speedups

## 6. Refactor For Better Instruction Selection

Pattern:

- Keep the intrinsic, but rewrite the code around it so the compiler chooses better instructions.
- Reshape constants, loop structure, and lane arrangement to reduce shuffles, moves, and spills.
- Recheck emitted machine code after every small rewrite.

Seen in:

- `simdjson`
- `StringZilla`
- `amx-benchmarks`

Best for:

- NEON or SIMD hot loops
- Apple-specific fast paths
- modular arithmetic kernels
- code where the compiler is "almost right" but still emits waste

## 7. Let The Planner Or Compiler Fuse Work

Pattern:

- Delay materialization until the engine knows enough to combine operations.
- Use query planning, lazy execution, or expression templates to avoid intermediates.
- Push filters and projections closer to the source.

Seen in:

- `DuckDB`
- `Polars`
- `DataFusion`
- `Eigen`

Best for:

- dataframe pipelines
- query engines
- expression-heavy numeric code
- multi-stage transformations with many temporary values

## 8. Optimize The Whole Pipeline, Not Just The Kernel

Pattern:

- A 10x faster inner loop may not matter if setup, IO, parsing, or queueing dominates.
- Measure parsing, scheduling, memory movement, and result formatting around the hot kernel.
- Co-design ingress, compute, and egress.

Seen in:

- `uv`
- `ruff`
- `fff.nvim`
- `uWebSockets`

Best for:

- CLI tools
- request handlers
- search/indexing
- mixed-language pipelines
