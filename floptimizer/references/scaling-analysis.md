# Scaling Analysis

Use this file when performance changes with concurrency, batch size, input size, shard count, or machine size. The goal is to find the knee of the curve and the real saturation point instead of optimizing a single benchmark point.

## What To Sweep

Pick only the dimensions that matter for the workload:

- concurrency
- request rate
- batch size
- input size or dataset size
- thread count
- worker count
- shard count or partition count
- connection-pool size
- queue depth
- cache state or warm-state phase when relevant
- hardware, firmware, driver, or runtime environment when the optimum may move across machines

For accelerators, also sweep:

- transfer size
- kernel batch size
- synchronization frequency

## What To Measure

At each point on the sweep, capture:

- throughput
- p50, p95, p99 latency
- CPU and memory usage
- environment identifier and relevant firmware, driver, or runtime version when comparing machines
- queue depth or backlog
- error rate, retries, and timeouts
- saturation signals such as lock wait, pool exhaustion, or bandwidth caps
- whether the point is cold, warming, steady warm, or rewarm after reset

## What To Look For

- the knee where throughput stops improving much
- the point where tails begin to explode
- the point where queueing starts dominating
- the point where memory or bandwidth becomes the limiter
- the point where more threads or bigger batches hurt instead of help

## Segment The Workload

Aggregate metrics often hide the real opportunity. Break out:

- hot endpoint or query type
- cold vs warm path
- cache hit vs miss
- small vs large inputs
- specific tenants, tables, or partitions
- specific circuit sizes, transforms, or kernels

If one cohort dominates the pain, optimize that cohort first.

## Practical Sweep Rules

- Start coarse, then zoom in near the knee.
- Keep the environment fixed while sweeping.
- Use the same dataset and warmup rules for comparable runs.
- If the environment itself changes the optimum, keep a small per-environment tuning matrix instead of collapsing everything into one winner.
- Record whether each result reflects a portable direction or just a local optimum on that machine.
- Prefer a few good sweep points over a huge noisy matrix.
- If the machine is noisy, rerun only the important points after it quiets down.

## Common Findings

- A path looks fast at one concurrency level but collapses under load.
- A GPU path loses at small batches and wins only after batching crosses a threshold.
- The best batch size, stream count, or queue depth shifts materially with memory size, bandwidth, or driver behavior.
- A change improves median latency but reduces saturation throughput.
- A lock or pool size creates an artificial ceiling long before hardware is full.
- A warm-state optimization wins only after long cache buildup and loses badly after invalidation or failover.

## Output Format

```text
Dimensions swept:
Environment matrix:
Conceptual direction vs local tuning:
Knee of curve:
Saturation point:
Dominant cohort:
Best operating region:
Implication for next optimization:
```
