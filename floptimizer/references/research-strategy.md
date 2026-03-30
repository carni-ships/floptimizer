# Research Strategy

Use this file when the bottleneck class is already known and a targeted literature review could expand the hypothesis set. This is especially useful in fast-moving areas such as GPU kernels, SIMD, compilers, databases, distributed systems, storage engines, ML runtimes, and ZK proving.

## Contents

- When To Do This
- Scope It Tightly
- Source Priority
- Recency And Relevance
- Review Workflow
- Last-Chance Outward Check
- What To Extract
- Maturity Filter
- Guardrails
- Output Format

## When To Do This

Do a bounded literature review when one or more of these are true:

- the bottleneck is clear but local ideas are thinning out
- the domain changes quickly and recent work may matter
- you are considering a major rewrite and want better option coverage first
- exemplar repos show the broad pattern but not the newest techniques

Do not make this the default first step. Measure first, classify the bottleneck, and inspect local code before searching outward.

## Scope It Tightly

Keep the review bounded:

- one bottleneck class at a time
- one concrete question at a time
- a small source set rather than open-ended browsing

Good questions:

- "What recent techniques improved NTT or FFT throughput on Apple Silicon?"
- "What current approaches reduce lock contention in shard-per-core services?"
- "What recent query-engine work improved vectorized execution under skew?"

Bad questions:

- "What are the latest optimization ideas?"
- "How do I make this whole system faster?"

## Source Priority

Prefer primary sources:

1. official documentation
2. maintainer blogs, design docs, postmortems, and architecture notes
3. papers or technical reports
4. benchmark methodology write-ups
5. code or PRs in high-quality exemplar repos

Use aggregator posts only as discovery aids. Do not treat them as evidence by themselves.

## Recency And Relevance

Prefer recent sources when the area is evolving quickly, but do not ignore older seminal work if it still anchors current practice.

For each source, capture:

- publication date
- implementation date if different
- target hardware or environment
- workload shape
- whether the result is production-proven, prototype-only, or purely research

## Review Workflow

1. State the bottleneck and the concrete question.
2. Gather a small set of recent primary sources and closely related codebases.
3. Extract candidate techniques, not conclusions.
4. Record the prerequisites for each idea.
5. Record the likely upside, risks, and portability limits.
6. Pick one to three spike experiments for local validation.

## Last-Chance Outward Check

Before you give up on a process, file, algorithm, subsystem, or dependency hotspot as "fully tuned," do one final focused outward scan.

Use it when:

- several local ideas have already been tried fairly
- the hotspot is still material enough to matter
- you are about to close the branch and move on

How to run it:

1. Name the exact hotspot, not the whole system.
2. Search for newer or unusually fast implementations of that exact thing.
3. Prefer maintainer notes, recent papers, implementation PRs, and code in high-quality repos.
4. Extract at most one to three additional ideas worth spiking.
5. If nothing credible appears, mark the branch exhausted with confidence.

Good examples:

- "recent SIMD hash-table lookup tricks for open-addressed maps"
- "new Apple Silicon NTT implementations with better batching or layout"
- "recent RocksDB-style compaction scheduling ideas for write-heavy LSM workloads"

Bad examples:

- "what else could make this app faster?"
- "search more performance ideas"

## What To Extract

For each promising idea, write down:

- the technique
- why it might apply here
- what must already be true for it to work
- what it could break or complicate
- what measurement would validate it

The prerequisite list matters. Many good ideas are path-dependent and only pay off after batching, layout cleanup, copy reduction, or stage simplification.

## Maturity Filter

Before acting on an idea, classify it:

- production-proven
- plausible but environment-specific
- research-only or speculative

Prefer production-proven ideas first. Use speculative ideas only when the expected payoff is large and the experiment can be kept narrow.

## Guardrails

- Treat benchmark claims as inputs, not conclusions.
- Do not cargo-cult papers or repos into the codebase.
- Do not let literature review replace measurement on the target system.
- Stop the review once you have enough ideas to run the next experiments.
- Return to benchmarking quickly.

## Output Format

Keep the research output compact:

```text
Question:
Sources reviewed:
Candidate directions:
Prerequisites:
Best next spikes:
What to ignore for now:
```
