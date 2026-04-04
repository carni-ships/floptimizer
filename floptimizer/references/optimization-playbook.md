# Optimization Playbook

Use this file after identifying the bottleneck class. The goal is to expand the option set without encouraging unsafe shortcuts.

## Contents

- Cross-Level Search
- Application and Algorithm Layer
- Unlocking Work And Path Dependence
- Language and Runtime Layer
- Dependencies And Third-Party Surfaces
- Database and Storage Layer
- Network and Distributed Systems Layer
- Operating System and Hardware Layer
- Build and CI Layer
- Safety Checks Before Keeping an Optimization

## Cross-Level Search

Before picking from the rest of this playbook, ask what level the current ideas are operating on.

Common failure modes:

- only rewriting inner operations when the total work is still avoidable
- only proposing architectural changes when a local layout or batching fix would unlock a large win
- only tuning dependencies when the pipeline shape is the real issue

For a serious hotspot, try to produce candidates from at least three nearby levels:

- current level
- one level above
- one level below

For a more explicit sweep, use [`optimization-levels.md`](optimization-levels.md).

## Application and Algorithm Layer

Highest-yield changes:

- Replace `O(n^2)` or repeated scans with indexed or hashed lookups.
- Eliminate duplicate work across requests, iterations, and pipeline stages.
- Look explicitly for duplicate parsing, validation, serialization, compression, copying, and fan-out between layers.
- Batch operations to reduce per-call overhead.
- Shrink payloads and parsing cost.
- Cache only when invalidation and memory limits are explicit.
- Move invariant work to startup, compile time, or background jobs.

Aggressive but acceptable:

- Precompute lookup tables
- Special-case the hottest input shapes
- Add preprocessing or normalization stages that make the hot path simpler: canonicalize formats, sort or bucket records, compact payloads, strip unused fields, prefilter obvious misses, or convert data into accelerator-friendly layouts
- Use arena or slab allocation when lifetime patterns are clear
- Fuse stages to avoid intermediate materialization

Guardrail:

- Count the full cost of preprocessing, including rebuild, invalidation, and memory overhead. Keep it when the downstream savings amortize the added stage in the real operating region.

## Unlocking Work And Path Dependence

Some optimization paths need preparatory work before the visible win appears.

Common cases:

- batching requests before GPU offload
- reducing copies before zero-copy or accelerator paths matter
- reshaping memory before SIMD becomes effective
- adding a preprocessing stage before indexing, vectorization, offload, or caching pays off
- removing global ownership bottlenecks before multicore scaling improves
- simplifying stage boundaries before fusion or prefetching becomes practical

Treat this as a dependency graph:

- target win
- required preconditions
- cheapest enabling changes
- validation plan for the full path

Do not reject enabling work just because its isolated local win is modest. Reject it when the downstream path is no longer credible, too expensive, or no longer needed.

## Language and Runtime Layer

Common wins:

- Reduce allocations and copies.
- Reuse buffers and builders.
- Prefer contiguous data access.
- Collapse redundant transforms, especially parse -> validate -> reshape -> re-encode chains that touch the same data multiple times.
- Replace regex or reflection on hot paths when cheaper primitives exist.
- Tune GC and thread pools only after fixing avoidable churn.

Tooling by ecosystem:

- Python: vectorize, move hotspots to C/Rust extensions only when profiling justifies it, prefer `orjson`, `msgspec`, `numpy`, `polars`, or compiled loops for the right workload.
- Node.js: reduce object churn, avoid sync fs on hot paths, inspect event-loop blocking, switch expensive JSON or crypto operations off the main thread when needed.
- Go: inspect allocations with `-benchmem`, lower interface churn, avoid map growth surprises, tune pooling carefully, use `pprof` before touching `GOGC`.
- Rust: prefer algorithmic wins first, then inspect allocation, clone frequency, lock scope, and cache behavior; use `cargo flamegraph` or `perf`.
- JVM/.NET: use production-like benchmarks, inspect object lifetime and GC pauses, tune heap and collectors only after locating churn sources.
- C/C++: validate compiler flags, inlining, vectorization, aliasing assumptions, and allocator choice; use sanitizers to keep aggressive changes safe.

If the real question is whether the hotspot should stay in the current language at all, consult [`lower-level-language-choice.md`](lower-level-language-choice.md). Prefer a narrow native core or kernel spike before discussing a wholesale migration.

## Dependencies And Third-Party Surfaces

Do not assume all remaining wins must come from first-party code.

Look for:

- profiles dominated by a library or framework boundary
- slow default settings in a dependency
- disabled fast paths due to configuration or feature flags
- an older dependency version missing known performance work
- abstraction layers that hide repeated copies, retries, parsing, or synchronization

Common wins:

- enable a faster library mode or feature flag
- upgrade to a version with relevant performance fixes
- replace a poor-fit dependency with a better one
- reduce crossings into the dependency with batching or different data shapes
- contribute or locally carry a narrow upstream patch when the bottleneck is clearly inside the dependency
- build or port the narrow missing capability locally when the desired fast path is unavailable on the current platform, runtime, or architecture

Guardrails:

- profile the dependency first; do not swap libraries by vibes
- prefer reversible changes such as config or version bumps before long-lived forks
- do not treat missing private access as a reason to bypass boundaries; if the capability matters, replace it through a clean, measurable contract instead
- keep compatibility, correctness, support burden, and upgrade path in the tradeoff analysis

## Database and Storage Layer

Look for:

- missing or low-selectivity indexes
- N+1 query patterns
- unnecessary transaction scope
- row-at-a-time application logic
- bloated serialization and result sets

Common wins:

- add or reshape indexes
- rewrite queries for planner friendliness
- batch writes and reads
- reduce selected columns
- remove repeated queries, re-fetches, and duplicate hydration work
- pre-aggregate or materialize expensive views
- tune pool sizes from measurement, not folklore

Always inspect the query plan before and after.

## Network and Distributed Systems Layer

Look for:

- too many round-trips
- repeated handshakes
- chatty service decomposition
- overloaded retries
- imbalanced partitions
- slow serialization formats

Common wins:

- reuse connections
- coalesce requests
- compress only when payload size justifies it
- move to binary protocols when encoding dominates
- collapse redundant hops or repeated serialization across service boundaries
- reduce dependency fan-out on critical requests
- bound retries and add backpressure

## Operating System and Hardware Layer

Apply only after proving the system surface is the limiter.

Examples:

- raise file descriptor or socket limits
- tune TCP buffer sizes and keepalive behavior
- align storage and filesystem settings with workload
- use huge pages or NUMA pinning only with evidence
- validate container CPU and memory quotas
- enable PGO/LTO and architecture-specific flags where safe

Document every system-level tuning knob changed and make rollback easy.

## Build and CI Layer

Look for:

- poor dependency cache hit rates
- over-serialized build graphs
- debug symbols or heavy linting on the critical path
- unnecessary rebuild triggers

Common wins:

- improve artifact caching
- split targets for better parallelism
- avoid rebuilding unchanged generated code
- separate fast presubmit checks from heavier nightly work

## Cryptographic and Arithmetic-Heavy Workloads

When the hot path is dominated by modular arithmetic, elliptic curve operations, polynomial evaluation, or similar algebraic computation:

### Multi-Scalar Multiplication (MSM)

- Pippenger's algorithm scales as O(n/log n). Bucket count and window size are the primary tuning knobs.
- GPU MSM benefits from sorted bucket indices (count-sorted mapping) to reduce warp divergence in the accumulation phase.
- Batch MSM dispatch: when multiple independent MSMs are needed (e.g., committing multiple polynomials), pipeline them rather than serializing.
- GLV endomorphism decomposition can halve the effective scalar size for curves with efficient endomorphisms.
- Mixed CPU+GPU: dispatch large MSMs to GPU, keep small ones on CPU. Threshold typically 64K-256K points depending on hardware.

### Polynomial Operations

- NTT/FFT butterflies benefit from NEON/SIMD vectorization on CPU and are naturally parallel on GPU.
- Polynomial evaluation (Horner's method) is inherently sequential per polynomial but independent across multiple polynomials.
- Sumcheck compute_univariate is often the CPU bottleneck in modern proving systems. The inner loop evaluates relations across all rows — optimize data layout for cache locality and SIMD.

### Commitment Schemes

- Batch commit multiple polynomials together when the commitment scheme supports it (amortizes setup cost).
- Gemini fold polynomials involve halving operations that are memory-bandwidth bound — optimize for sequential access.
- KZG opening proofs involve single MSMs that can overlap with other CPU work.

### Binary-Level Optimization

When source code is unavailable or corrupted but working object files exist in static libraries:

- Use `objdump -d` and `nm` to understand compiled code paths, parameter passing, and function call chains.
- Use `ar r` to replace individual .o files in .a archives, then relink the binary.
- Trace parameter flow through registers (ARM64: x0-x7 for args, w0-w7 for 32-bit) to understand how configuration flags propagate through call chains.
- Binary-patch specific instructions when a single flag or threshold change is all that's needed and source rebuild is blocked.

## Safety Checks Before Keeping an Optimization

Do not keep a change until you confirm:

- correctness tests still pass
- memory growth is bounded
- tail latency is not worse
- observability and debugging remain adequate
- failure behavior under load is acceptable
- the win survives realistic data sizes and concurrency
