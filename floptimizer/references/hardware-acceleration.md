# Hardware Acceleration

Use this file when the optimization path may involve SIMD, multicore scheduling, GPUs, Metal, CUDA, NPUs, Core ML, DSPs, or any other heterogeneous-compute decision.

## Contents

- Decision Rule
- Baseline Before Offload
- Refactor Around Intrinsics, Not Just Into Intrinsics
- Apple Silicon CPU Paths: NEON and AMX
- Apple Silicon and Metal
- ANE and Other Fixed-Function Accelerators
- Consumer-Hardware Study Targets
- What To Measure
- Keep Or Reject The Offload

## Decision Rule

Do not jump to hardware offload just because the workload is "compute heavy." Use this order unless measurements clearly point elsewhere:

1. Fix obvious algorithmic waste.
2. Improve data layout and eliminate copies.
3. Use CPU SIMD and multicore parallelism.
4. Offload to GPU or another accelerator only if the kernel is massively parallel, synchronization is limited, and the data movement cost does not erase the gain.

Offload is most promising when all of these are true:

- The hot path is dominated by dense arithmetic, transforms, scans, reductions, or other data-parallel kernels.
- Work can be batched into large chunks.
- Control flow divergence is limited.
- Memory layout can be made contiguous and accelerator-friendly.
- CPU and accelerator synchronization can be kept infrequent.

Accelerator work is often path-dependent. The eventual GPU or accelerator win may require prerequisite work first:

- larger batches
- fewer copies and intermediate buffers
- flatter or more contiguous memory layout
- cleaner stage boundaries
- reduced synchronization frequency

If those preconditions are missing, the next move may be to build them rather than to write the kernel immediately.

Do not reject a hardware-specific path only because the surrounding refactor sounds large. The full production path may require broad changes to layout, dispatch boundaries, ownership, copy behavior, or kernel structure, but a narrow rewrite of the hottest slice is often still cheap enough to spike first.

Good framing:

- full accelerator-aware refactor may be large
- narrow rewrite of the hot kernel, data layout, or dispatch boundary may still be cheap to test
- if the spike wins, keep the branch alive even if broader rollout is deferred

Offload is usually a bad first move when any of these dominate:

- tiny per-request work
- branch-heavy logic
- pointer chasing
- lock contention
- database latency
- serialization and RPC overhead
- irregular graph traversals

## Baseline Before Offload

Before writing custom kernels:

- Capture a trustworthy CPU baseline.
- Measure the best CPU SIMD and multicore version you can reasonably achieve first.
- Compare against vendor-provided optimized primitives before rolling your own.
- Measure end-to-end time, not just kernel time.

For Apple platforms, compare against:

- Metal Performance Shaders
- MPSGraph
- Core ML for ML-shaped workloads

For general GPU environments, compare against:

- BLAS or FFT libraries
- vendor tensor libraries
- existing query, image, or numeric kernels in the target stack

## Refactor Around Intrinsics, Not Just Into Intrinsics

The intrinsic itself is fixed. The surrounding code is not. A large share of SIMD and matrix-acceleration wins come from rewriting the code that feeds the intrinsic layer so the compiler emits a better instruction stream.

Common wins:

- reorder independent operations to improve instruction-level parallelism
- reduce register pressure and unnecessary moves
- remove avoidable shuffles and lane permutations
- change data layout from array-of-structs to struct-of-arrays when it improves vector access
- align buffers and tile sizes to cache and vector widths
- embed constants or restructure arithmetic when the compiler picks poor instruction sequences
- isolate Apple-specific fast paths behind `#ifdef __APPLE__` or runtime dispatch only after proving a real benefit

Treat the compiler as a collaborator that sometimes needs help:

- inspect generated assembly
- compare small source rewrites, not just algorithm changes
- verify that a "cleaner" abstraction still emits the desired instructions

Higher-level abstractions are still valid if they lower to good code:

- Apple Accelerate
- `std::simd`
- Rust `core::arch::aarch64`
- carefully wrapped `extern "C"` or inline-assembly boundaries for hot kernels

## Apple Silicon CPU Paths: NEON and AMX

On Apple Silicon, do not think only in terms of GPU offload. CPU-side refactoring around NEON and Apple's matrix paths can produce large gains while keeping debugging and control-flow integration simpler than a GPU rewrite.

For a deeper Apple-specific CPU workflow, read [`apple-silicon-cpu.md`](apple-silicon-cpu.md).

Focus on CPU intrinsics first when:

- the kernel is hot and regular
- working sets are not large enough to justify GPU dispatch
- latency matters more than batch throughput
- the algorithm benefits from tight scalar and vector cooperation

Good candidates:

- FFT or NTT butterflies
- modular multiply and reduction kernels
- vector math, scan, and reduction pipelines
- mixed scalar plus SIMD pipelines where control remains on CPU

Especially on Apple Silicon:

- benchmark NEON or AMX-friendly CPU kernels before writing Metal
- inspect whether the compiler emits extra `mov`, shuffle, or spill sequences
- try small refactors around constants, unrolling, and inlining before resorting to handwritten assembly
- keep an eye on register pressure and cache behavior, not just nominal instruction count
- treat code shaped around the wrong hardware model as legitimate optimization debt: scalarized layouts, legacy packing, alignment assumptions, or dispatch structure that prevents a clean fast path are all fair targets if the hotspot still matters

## Apple Silicon and Metal

Apple Silicon changes the offload tradeoff because unified memory removes the classic discrete-GPU PCIe copy boundary. That does not make GPU offload free, but it lowers one common barrier.

Use Metal as the primary path for general GPU compute on Apple platforms when:

- the kernel is embarrassingly parallel
- working sets are large enough to amortize dispatch overhead
- you can batch operations
- threadgroup memory and barrier structure map cleanly to the algorithm

Good Apple-Silicon candidates:

- FFT or NTT-like transforms
- matrix and tensor operations
- vectorized search kernels
- hash, compare, scan, and reduction pipelines
- large batched image or signal transforms

Less suitable Apple-Silicon GPU candidates:

- fine-grained request handlers
- highly branchy business logic
- pointer-heavy data structures
- queueing, locking, and scheduler bottlenecks

In practice, many "GPU lost to CPU" results on Apple Silicon are really "the path was not ready yet" results. Batching, layout cleanup, and copy reduction often need to happen before Metal has a fair chance.

### Metal-Specific Guidelines

- Minimize CPU and GPU round-trips.
- Batch dispatches; avoid many tiny kernels.
- Use threadgroup memory only when it clearly reduces global-memory traffic.
- Watch barrier count and divergence.
- Prefer structure-of-arrays style layouts when they improve coalescing and vector access.
- Validate occupancy, memory bandwidth, and synchronization behavior with Xcode tools instead of guessing.

### GPU Command Buffer Pipelining

Serial GPU dispatches are a common hidden bottleneck. When multiple independent GPU operations execute sequentially (each waiting for the previous to complete before dispatching), the total time is the sum of individual times plus dispatch overhead.

Optimization strategies:

- **Single command buffer, multiple dispatches**: Encode multiple independent compute passes into one command buffer. The GPU scheduler can overlap execution and hide latency between passes.
- **Double/triple buffering**: Use multiple command buffers in flight. While one executes, encode the next. Keeps the GPU pipeline fed.
- **Async CPU+GPU overlap**: After dispatching GPU work, do useful CPU work before waiting for results. Structure the algorithm so CPU and GPU phases interleave.
- **Batch kernel submission**: Instead of N separate dispatches for N independent problems, encode all N into one command buffer when they share the same pipeline state.

Caution: merging independent dispatches into a single command buffer only helps if the individual kernels are truly independent. If merging forces you to skip essential preprocessing (like data reordering for warp uniformity), the regression from increased divergence can outweigh the dispatch savings.

### Data Ordering for GPU Warp Uniformity

GPU SIMT execution is most efficient when threads in a warp/simdgroup follow the same control flow. When workload varies across threads (e.g., some buckets have many items, others have few), warp divergence wastes cycles.

Techniques:

- **Count-sorted mapping (CSM)**: Sort work items by size/count so similarly-sized items execute together. This groups threads with similar workloads into the same warps, minimizing divergence.
- **Compaction**: Remove empty or trivial work items before dispatch so GPU threads don't idle.
- **Padding**: Pad variable-length work to the next multiple of warp size when the padding cost is less than the divergence cost.
- **Two-phase dispatch**: Use a fast GPU pass to classify work items, then a second dispatch with reordered data.

The CSM technique is particularly valuable for bucket-based algorithms (e.g., Pippenger MSM) where bucket sizes follow a distribution. Without sorting, threads processing large and small buckets share warps, causing the entire warp to run at the speed of its slowest thread.

## ANE and Other Fixed-Function Accelerators

Apple Neural Engine is usually the wrong target for arbitrary arithmetic kernels. It is most relevant when the workload is already shaped like Core ML inference.

Treat ANE as promising when:

- the workload is ML inference or close to it
- a Core ML deployment path already exists
- supported tensor shapes and precision modes fit the problem

Treat ANE as a poor fit when:

- you need custom big-integer arithmetic
- you need arbitrary modular arithmetic
- the kernel is not expressible in ML-oriented operators

For ZKML-style pipelines, ANE may help with the model inference portion while GPU or CPU handles proving or non-ML kernels.

## Consumer-Hardware Study Targets

When the workload resembles large, data-parallel kernels on Apple hardware, these references are useful:

- [Apple: Performing calculations on a GPU](https://developer.apple.com/documentation/metal/performing-calculations-on-a-gpu)
- [Apple: Metal Performance Shaders](https://developer.apple.com/documentation/metalperformanceshaders)
- [Apple Research: Deploying Transformers on the Apple Neural Engine](https://machinelearning.apple.com/research/neural-engine-transformers)
- [EZKL Metal MSM acceleration](https://github.com/zkonduit/metal-msm-gpu-acceleration)
- [Mopro / PSE Metal MSM v2 write-up](https://pse.dev/blog/mopro-metal-msm-v2)
- [`zkMetal`](https://github.com/carni-ships/zkMetal)
- [`node-zk-accelerate`](https://github.com/Digital-Defiance/node-zk-accelerate)
- [`metal-poc`](https://github.com/ingonyama-zk/metal-poc)
- [`metal-fft`](https://github.com/philipturner/metal-fft)

These are especially useful for understanding:

- unified-memory tradeoffs
- threadgroup memory tiling
- barrier placement
- host-layer plus shader-layer split design
- Rust or Node interop with Metal
- batching strategies for arithmetic-heavy kernels

## What To Measure

When evaluating an accelerator path, always measure:

- end-to-end latency and throughput
- kernel time
- dispatch overhead
- synchronization frequency
- memory bandwidth and cache behavior
- occupancy or execution width where the platform exposes it
- total energy or thermal behavior if the device is mobile
- the per-device parameter region that actually wins: batch size, transfer size, stream count, tile size, working-set size, and the cliff points where memory or synchronization costs take over
 - whether the result is a portable accelerator strategy or a device-specific lucky tuning point

Do not record only one "best batch size" if the work may run on multiple devices. Leave behind a small tuning matrix keyed by device, memory size, driver or firmware version, and runtime version so later agents can start from informed priors instead of re-discovering the whole surface.
Prefer writing down principles like "batch more until occupancy rises but before memory stalls dominate" over pretending that `batch_size=80` is universal.

On Apple platforms, use Xcode Instruments, Metal counters, and the Metal debugger when available.
For CPU-side intrinsic tuning, also inspect emitted assembly with Compiler Explorer, disassembly tools, or Xcode-generated assembly views when practical.

## Keep Or Reject The Offload

Keep the hardware-accelerated path only if it wins end-to-end and remains maintainable.

Reject or demote it if:

- it only wins in synthetic microbenchmarks
- debugging and correctness become fragile
- thermal throttling erases the gain
- synchronization overhead dominates
- the simpler CPU path stays competitive on real workloads
