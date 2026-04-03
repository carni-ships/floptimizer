# Ceiling Analysis

Use this file after the bottleneck class is known and before sinking large effort into a specific optimization path. The goal is to estimate the maximum plausible win so you do not spend days chasing a slice that cannot move the user-facing metric enough.

## Questions To Answer

- What fraction of end-to-end time or cost does this slice own right now?
- If this slice became infinitely fast, how much total improvement is even possible?
- What is the practical lower floor for this slice even after very good optimization?
- How much room-to-improve remains between the current state and that floor?
- Is the real limit compute, memory bandwidth, IO, network RTT, queueing, or contention?
- Is there another nearby bottleneck that will take over immediately after this one improves?

## Quick Workflow

1. Identify the slice share from profiles, traces, or stage timing.
2. Compute the simple upper bound: if the slice disappeared entirely, what is the maximum end-to-end improvement?
3. Estimate the practical floor: the irreducible work that still has to happen even in a strong implementation.
4. Measure the remaining headroom from current state to that floor.
5. Identify the resource ceiling: core saturation, memory bandwidth, disk IOPS, network latency, pool size, queue depth, or dependency fan-out.
6. Convert that into a realistic target, not just a theoretical maximum.
7. Decide whether this path is still worth pursuing.

## Amdahl-Style Sanity Check

If a slice is only 20 percent of total time, eliminating it completely can only improve end-to-end time by 20 percent. Realistically the win will be smaller.

Use this to avoid:

- heroic micro-optimization on small slices
- costly rewrites with low upside
- confusing a large local speedup with a meaningful global speedup

## Practical Floor And Remaining Headroom

The theoretical ceiling asks, "what if this slice vanished?"

The practical floor asks, "what is the fastest plausible version of this slice while still doing the required work?"

Ways to estimate the floor:

- mandatory bytes moved, parsed, hashed, written, or transferred
- arithmetic lower bounds from operation count and realistic hardware throughput
- known good implementations in the same repo, a nearby dependency, or a strong exemplar
- protocol, correctness, or data-shape work that cannot be skipped
- proven fast-path numbers on a similar machine or runtime

Then estimate the remaining headroom:

```text
current slice time - practical floor = room left to improve
```

Use that headroom together with slice share:

- large slice + large headroom: strong place to invest
- large slice + small headroom: probably needs a higher-level redesign, not more local tuning
- small slice + large headroom: may still be lower priority because Amdahl limits the end-to-end impact
- small slice + small headroom: move on quickly

This does not need to be perfectly precise. A rough floor estimate is already enough to prevent over-investing in a nearly exhausted path.

## Resource Ceiling Clues

### CPU-bound

- one or more cores are saturated
- instruction retire rate is poor
- time falls as compute work falls

Check:

- single-core vs multicore scaling
- vectorization quality
- instruction mix

### Memory-bandwidth or locality bound

- CPU is busy but added arithmetic optimization barely helps
- cache misses or memory stalls dominate
- throughput plateaus as threads rise

Check:

- cache-miss counters
- bytes moved per operation
- data layout and working-set size

### IO or network bound

- compute is low while waits dominate
- batching helps more than algorithm tweaks
- tails worsen under concurrency

Check:

- syscall mix
- RTT and handshake timing
- queue depth and service fan-out

### Contention or queueing bound

- throughput stops scaling before hardware looks full
- lock wait, pool starvation, or queue depth rises sharply
- p99 degrades much faster than p50

Check:

- stage histograms
- scheduler or mutex traces
- pool saturation and retry behavior

## Good Decisions From Ceiling Analysis

- Continue when the ceiling is large enough, the floor is still far enough away, and the path is still credible.
- Change layers when the local ceiling is too small.
- Change layers when the local headroom is small because the real remaining win now depends on algorithm, topology, batching, or architecture shape rather than more tuning on the same slice.
- Change workload shape when the problem only appears under certain batch sizes, input sizes, or concurrency levels.
- Stop when the best realistic win no longer justifies the complexity.

## Output Format

Keep it short:

```text
Bottleneck:
Current share:
Theoretical max win:
Practical floor:
Remaining headroom:
Likely next ceiling:
Realistic target:
Decision:
```
