# Goal Refinement

Use this file before ranking optimization ideas. The goal is to turn "make it faster" into a concrete target with a clear operating region and explicit non-goals.

## What To Define

Refine the optimization goal into these parts:

- primary metric
- secondary guardrails
- dominant cohort or workload
- operating region that matters most
- target improvement
- stop rule

## Primary Metric

Pick one primary metric to optimize first:

- p99 latency
- median latency
- throughput
- CPU time
- wall time
- memory
- startup time
- build time
- cloud cost

If everything matters, nothing is prioritized. Choose the one that decides success.

## Secondary Guardrails

Write down what must not regress:

- correctness
- error rate
- memory growth
- tail latency
- durability
- debuggability
- observability
- cloud cost

## Dominant Cohort

Specify which workload matters most:

- a specific endpoint
- a specific query
- cold start
- steady-state hot path
- small inputs
- large inputs
- saturated operation
- one tenant or partition

This prevents optimizing the wrong average.

## Operating Region

State the region where the win must hold:

- at what concurrency
- at what batch size
- at what input size range
- on what hardware
- under what cache warmth

An optimization that only wins outside the real operating region is not a real win.

## Target Improvement

Choose an explicit target:

- "cut p99 from 120 ms to 80 ms"
- "raise throughput by 25 percent at the current error rate"
- "reduce peak RSS by 30 percent"

## Stop Rule

Decide what is good enough:

- stop after hitting the target
- stop when the realistic ceiling is too small
- stop when added complexity outweighs likely gain
- stop when the dominant bottleneck moves elsewhere

## Output Format

```text
Primary metric:
Guardrails:
Dominant cohort:
Operating region:
Target:
Stop rule:
```
