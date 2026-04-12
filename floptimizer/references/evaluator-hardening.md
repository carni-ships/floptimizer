# Evaluator Hardening

Use this file when a performance win looks suspiciously large, the benchmark is easy to game, or an agent could accidentally improve the metric by changing the task instead of the implementation.

## Core Idea

The evaluator is part of the system.
If it is weak, the search can optimize the harness instead of the real workload.

Before trusting a dramatic win, ask:

- what work might have been skipped?
- what semantics might have changed?
- what inputs got narrower or easier?
- what cached, warmed, or stale state is being reused without cost accounting?
- what correctness checks were weakened or bypassed?

## Common Fake Wins

- returning cached or stale outputs without counting fill or invalidation cost
- benchmarking a narrowed dataset, easier input distribution, or smaller fixture
- reducing precision, safety checks, durability work, or validation coverage
- skipping edge cases or expensive phases that still exist in production
- reusing precomputed artifacts without charging rebuild cost
- hiding warm-state buildup, copy cost, or synchronization cost outside the measured window
- changing concurrency, queueing, or ordering semantics in a way the benchmark does not notice

## Hardening Moves

- compare outputs against a trusted oracle or golden fixtures
- include holdout cases or less-friendly input distributions
- re-run from a fresh temp directory or fresh process when stale artifacts are plausible
- measure cold, warm, and rewarm separately when warm state matters
- inspect secondary counters such as bytes moved, rows processed, requests served, or work units completed
- verify that expensive phases still ran when they are supposed to
- add a differential test against the previous implementation for representative cases

## When To Escalate

Escalate evaluator hardening when:

- the gain is very large relative to prior headroom
- the optimization changes caching, batching, precompute, or offload boundaries
- the implementation is agent-generated and the harness is narrow
- the result improves one scalar metric while something else feels off

## Output Format

```text
Suspicious win:
Possible loopholes:
Checks added:
What still looks trustworthy:
What remains uncertain:
```
