# Optimization Levels

Use this file when a bottleneck is known but the search is getting trapped at only one abstraction level, such as only rewriting instructions or only brainstorming architecture changes.

## Core Idea

The same hotspot can often be attacked from multiple levels:

- make the same operations cheaper
- reorganize the local structure around those operations
- reduce how many operations are required at all
- move, fuse, or stage work differently in the pipeline
- change subsystem boundaries or hardware placement

Good optimization work deliberately scans multiple levels instead of assuming the answer must live only where the hotspot is currently visible.

## The Level Sweep

For a serious hotspot, inspect at least these levels:

1. Operation level
2. Local structure level
3. Algorithm or formulation level
4. Pipeline or stage-boundary level
5. Subsystem or dependency level
6. Architecture or deployment level
7. System or hardware level

Not every hotspot needs all seven, but the agent should at least ask whether the win is likely to come from:

- cheaper operations
- fewer operations
- better organized operations
- better placed operations

## Questions Per Level

### 1. Operation level

Ask:

- can the same operation be implemented more efficiently?
- are there avoidable branches, shuffles, allocations, or copies?
- is vectorization, batching, or a lower-overhead primitive available?
- is the generated code or memory access worse than it should be?

Examples:

- rewrite a hot loop
- reduce register pressure
- use a better intrinsic sequence
- avoid redundant loads or stores

### 2. Local structure level

Ask:

- is the local data layout fighting cache locality or SIMD?
- are ownership, allocation, or lock boundaries making the hot path expensive?
- would batching, sorting, bucketing, or buffer reuse help?

Examples:

- AoS to SoA
- reuse scratch buffers
- shard a hot map
- compact or canonicalize input once

### 3. Algorithm or formulation level

Ask:

- can we do less total work?
- can we replace repeated scans with indexing or preprocessing?
- can we change the mathematical or algorithmic formulation?
- can we approximate, prune, short-circuit, or precompute safely?

Examples:

- change the query plan
- use a different search strategy
- exploit problem structure
- replace full recomputation with incremental maintenance

### 4. Pipeline or stage-boundary level

Ask:

- are boundaries causing duplicate parsing, validation, serialization, or copying?
- should stages be fused, reordered, streamed, or split?
- should work move off the latency-critical path?

Examples:

- fuse parse plus transform
- move invariant work to preprocessing
- coalesce requests before offload
- add a staging format that simplifies downstream kernels

### 5. Subsystem or dependency level

Ask:

- is the bottleneck really inside a dependency, runtime, database, or driver?
- is configuration disabling a fast path?
- would a different library, protocol, or storage engine change the shape of the cost?

Examples:

- swap serializer
- enable a faster runtime mode
- upgrade a dependency
- add a DB index or different access path

### 6. Architecture or deployment level

Ask:

- is the current service boundary or concurrency model causing the cost?
- should work be moved, replicated, cached, sharded, or colocated differently?
- is the topology creating avoidable hops or synchronization?

Examples:

- move compute closer to data
- reduce fan-out
- change queueing boundaries
- separate coordination from heavy compute

### 7. System or hardware level

Ask:

- is the remaining limit due to the OS, runtime scheduler, driver, device memory, thermal throttling, or accelerator fit?
- should the hotspot use SIMD, GPU, AMX, storage tuning, or network/kernel tuning?
- is the machine shape itself the blocker?

Examples:

- GPU offload after batching lands
- SIMD after layout cleanup
- storage or socket tuning
- different device class for the same kernel

## Good Default Heuristic

For each serious hotspot, generate at least:

- one branch at the current level
- one branch one level above
- one branch one level below

This keeps the search from collapsing into only micro-tuning or only big redesign ideas.

## What Usually Wins

Broadly:

- higher levels remove more total work
- lower levels squeeze more out of unavoidable work

That means:

- if the work itself still looks avoidable, go upward first
- if the work is truly necessary and still dominates, go downward

## Guardrails

- Do not jump to lower-level tuning before asking whether the work can be removed altogether.
- Do not stay purely at the algorithm level if generated code, memory layout, or hardware fit is clearly the limiter.
- Do not assume a hotspot’s visible location is the level where the best fix lives.
- Record the level for each branch so later agents can see whether the search is too concentrated.

## Output Format

```text
Hotspot:
Current dominant level:
Same-level candidate:
One-level-up candidate:
One-level-down candidate:
Most plausible leverage:
```
