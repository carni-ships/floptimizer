# Exemplars: Apple And Hardware-Oriented Paths

Use this file when the optimization path is close to Apple Silicon CPU tuning, Metal GPU offload, or low-level teaching material about hardware-conscious optimization.

## Contents

- Apple Silicon, Metal, and Consumer GPU Offload
- Apple Silicon CPU Intrinsics and Matrix Paths
- Teaching Repos and Mindset Refs

## Apple Silicon, Metal, and Consumer GPU Offload

### metal-msm-gpu-acceleration

- Repo: `https://github.com/zkonduit/metal-msm-gpu-acceleration`
- Consult when: Apple Silicon GPU offload, Metal compute kernels, or large arithmetic kernels are under consideration.
- Learn from it: Metal compute pipelines, Rust-to-Metal integration, and how unified memory changes the cost model for GPU acceleration on Apple devices.
- Watch out for: borrowing a GPU architecture before confirming the kernel is large and parallel enough to justify dispatch overhead.

### node-zk-accelerate

- Repo: `https://github.com/Digital-Defiance/node-zk-accelerate`
- Consult when: Node-based systems need hardware-aware acceleration or when you want an example of capability detection across Apple Silicon features.
- Learn from it: hardware feature detection, Apple-Silicon-aware acceleration selection, and exposing lower-level acceleration behind a high-level runtime.
- Watch out for: mistaking platform detection for proof that offload is a net end-to-end win.

### metal-poc

- Repo: `https://github.com/ingonyama-zk/metal-poc`
- Consult when: translating CUDA-style or GPU-heavy arithmetic kernels into Metal is relevant.
- Learn from it: portability tradeoffs between GPU stacks and how parallel arithmetic kernels can be reorganized for Metal.
- Watch out for: assuming a direct CUDA-to-Metal translation is enough without re-measuring occupancy, memory traffic, and synchronization.

### metal-fft

- Repo: `https://github.com/philipturner/metal-fft`
- Consult when: FFT-like workloads or general Metal compute layout choices are relevant.
- Learn from it: Metal compute structure for transform-heavy kernels, buffer management, and threadgroup-oriented decomposition.
- Watch out for: transplanting FFT-specific structure into unrelated workloads.

## Apple Silicon CPU Intrinsics and Matrix Paths

### simdjson on Apple Silicon

- Repo: `https://github.com/simdjson/simdjson`
- Consult when: NEON refactors, branch elimination, popcount-style vector tricks, or Apple-specific SIMD fast paths are relevant.
- Learn from it: how small rewrites around intrinsics can change emitted instructions substantially and produce real end-to-end wins in production code.
- Watch out for: copying a clever intrinsic sequence without checking whether the compiler still emits the same machine code on your target chip and compiler version.

### Dougall J NEON integer-formatting write-up

- Reference: `https://dougallj.wordpress.com/2022/04/01/converting-integers-to-fixed-width-strings-faster-with-neon-simd-on-the-apple-m1/`
- Consult when: you want a concrete example of iterative intrinsic refactoring on Apple Silicon.
- Learn from it: constant reshaping, instruction selection nudges, and how tiny arithmetic rewrites can remove poor compiler choices and improve throughput.
- Watch out for: treating a highly specialized SIMD trick as a universal optimization template.

### Apple Silicon CPU Optimization Guide

- Reference: `https://developer.apple.com/documentation/apple-silicon/cpu-optimization-guide`
- Consult when: you need Apple’s official guidance on CPU tuning, vector usage, and platform-specific optimization constraints.
- Learn from it: the platform-level framing for using CPU acceleration well before dropping into more exotic paths.
- Watch out for: assuming the guide replaces local profiling or workload-specific tuning.

## Teaching Repos and Mindset Refs

### less_slow.cpp

- Repo: `https://github.com/ashvardanian/less_slow.cpp`
- Consult when: you want a concentrated tutorial-style performance mindset for C++, CUDA, PTX, and assembly-adjacent thinking.
- Learn from it: mechanical sympathy, instruction-level awareness, and how to reason about where cycles actually go.
- Watch out for: reaching for low-level heroics before proving simpler architectural wins are exhausted.
