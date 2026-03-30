# Apple Silicon CPU

Use this file when the workload runs on Apple Silicon and the likely optimization path is CPU-side rather than GPU-first. This is the right reference for NEON-friendly kernels, matrix-oriented CPU acceleration, compiler-inspection workflow, and deciding between Accelerate, custom intrinsics, and Metal.

## Contents

- Decision Tree
- Which Abstraction To Prefer
- Intrinsic-Refactoring Workflow
- What To Look For In Assembly
- Apple-Specific Tactics
- Accelerate vs Custom Intrinsics vs Metal
- Study References
- Practical Takeaways

## Decision Tree

Start with the simplest layer that can plausibly hit the target:

1. Algorithm and data-layout fixes
2. Vendor or standard abstractions that already lower well
3. Portable SIMD or target-specific intrinsics
4. Matrix-oriented Apple CPU paths or lower-level specialization
5. Metal only if the kernel is large and parallel enough that GPU dispatch and synchronization costs are justified

Choose CPU first when:

- latency matters more than peak batch throughput
- the kernel is hot but not large enough to amortize GPU dispatch
- scalar control flow remains important around the vector work
- debugging complexity matters
- the working set is cache-resident or close to it

Choose Metal first when:

- the kernel is embarrassingly parallel
- batches are large
- threadgroup-oriented decomposition fits naturally
- CPU-side synchronization can stay infrequent

## Which Abstraction To Prefer

### Prefer Accelerate or another optimized framework when

- the problem is already a BLAS, LAPACK, FFT, vDSP, or similar library-shaped workload
- you need a strong baseline quickly
- the abstraction overhead is negligible relative to the compute
- maintainability is a priority

This is often the best first benchmark, even if you expect a custom kernel to win later.

### Prefer portable SIMD or standard abstractions when

- the workload is custom but still vector-friendly
- you want one code path across multiple CPUs
- you can get most of the gain without platform-specific maintenance

Examples:

- `std::simd`
- Rust `portable_simd`
- portable vector helper libraries

### Prefer explicit NEON intrinsics when

- the kernel is a true hot loop
- you need control over lane operations, shuffles, saturating math, or instruction selection
- the compiler’s auto-vectorization is close, but not quite right

Examples:

- `arm_neon.h`
- Rust `core::arch::aarch64`

### Prefer matrix-oriented Apple CPU paths when

- the workload is tileable and matrix-shaped
- the main cost is dense numeric work
- you can profit from careful layout and scheduling around matrix units

Treat this as a more specialized path than ordinary SIMD. Use it only after proving the shape of the workload warrants it.

## Intrinsic-Refactoring Workflow

The main lesson: the intrinsic call is not the whole optimization. A large share of the gain comes from refactoring the code around the intrinsic so the compiler emits a better instruction stream.

Use this loop:

1. Profile and isolate the kernel.
2. Build a tiny benchmark that reproduces the hot path.
3. Compile for the actual target CPU with full optimization.
4. Inspect the generated assembly.
5. Rewrite the source around the intrinsic layer.
6. Recheck assembly and rerun the benchmark.
7. Keep only the changes that survive on representative data.

Source rewrites worth trying:

- reorder independent operations for better instruction-level parallelism
- change packing order to avoid later shuffles
- reshape constants so they fold into better instructions
- reduce temporary vectors that cause spills
- use by-element forms when they reduce constant traffic
- adjust unrolling only if it lowers loop overhead without exploding register pressure
- split Apple-specific fast paths from portable paths after the gain is proven

## What To Look For In Assembly

Signs the compiler is doing well:

- vector ops dominate the hot loop
- few redundant moves
- low spill and reload traffic
- minimal lane-shuffle overhead
- clean addressing and load-store cadence

Signs you should keep iterating:

- repeated `mov` chains around vector code
- scalar work feeding every vector step
- spills caused by over-aggressive unrolling or too many live temporaries
- expensive permutations that could be removed with a layout change
- constant loads dominating a supposedly arithmetic-heavy loop

Use whichever tools fit the project:

- Compiler Explorer for fast source-to-assembly iteration
- Xcode-generated assembly views
- `cargo asm` or similar Rust tooling if available
- normal disassembly tools for built binaries

## Apple-Specific Tactics

### NEON-friendly tactics

- Prefer structure-of-arrays when lane-wise operations dominate.
- Keep data aligned and contiguous.
- Batch work so vector setup is amortized.
- Use saturating, widening, or narrowing operations only when they map directly to the needed math.
- Revisit bit-reversal, lane-reversal, and shuffle-heavy code; these are often layout problems in disguise.

### Matrix-oriented CPU tactics

- Tile explicitly around the unit of reuse.
- Minimize scratch buffers unless they demonstrably help locality.
- Separate setup from the repeated inner kernel.
- Be cautious about formats that look mathematically natural but underutilize the underlying units.

### Apple-specific fast paths

Platform-specific kernels are reasonable when:

- the gain is material
- the fallback path remains correct
- the maintenance cost is bounded

Use compile-time or runtime dispatch only after measuring the benefit. Avoid fragmenting the codebase into many near-duplicate kernels for marginal wins.

## Accelerate vs Custom Intrinsics vs Metal

Use this quick rule:

- Accelerate first for standard math kernels
- Custom intrinsics for hot, regular, CPU-sized kernels that the compiler almost handles well
- Metal for large, massively parallel kernels where batching and synchronization overhead stay small

In practice:

- If Accelerate is already close to target, keep it.
- If Accelerate misses and the hot loop is still CPU-scale, try intrinsics next.
- If the kernel is too large, too parallel, or too bandwidth-oriented for CPU tuning alone, evaluate Metal.

## Study References

- [Apple Silicon CPU Optimization Guide](https://developer.apple.com/documentation/apple-silicon/cpu-optimization-guide)
- [Dougall J: Neon SIMD on the Apple M1](https://dougallj.wordpress.com/2022/04/01/converting-integers-to-fixed-width-strings-faster-with-neon-simd-on-the-apple-m1/)
- [simdjson discussion: Apple M1 optimization ideas](https://github.com/simdjson/simdjson/discussions/1658)
- [amx-benchmarks](https://github.com/philipturner/amx-benchmarks)

## Practical Takeaways

- Benchmark CPU SIMD before assuming GPU offload is necessary.
- Use high-level optimized libraries as the baseline, not as the enemy.
- Treat small source rewrites around intrinsics as first-class optimization moves.
- Inspect emitted code whenever the compiler seems "almost" optimal.
- Keep Apple-specific code paths only when the gain is real and repeatable.
