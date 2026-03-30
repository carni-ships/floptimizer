# Rewrite Decomposition

Use this file when a promising optimization path looks "too major," "too invasive," or "too large to attempt" and the risk is that the agent will halt instead of decomposing it.

## Core Idea

"This rewrite is too big" is not a sufficient stopping reason by itself.

Before parking a rewrite-heavy branch, decompose it into:

- the smallest slice worth rewriting
- the boundary that isolates that slice
- the oracle that proves behavior stayed acceptable
- the fallback or rollback path

Only after that decomposition can the branch be honestly judged too costly, too risky, or too low-value.

## Required Questions

For a rewrite-heavy branch, answer these before halting:

1. What exact hotspot or boundary would the rewrite target first?
2. What is the smallest bounded spike that can prove or kill the idea?
3. How will behavior be checked: golden outputs, differential run, shadow mode, fixtures, invariants?
4. What containment exists: feature flag, adapter, alternate code path, shadow implementation, isolated benchmark harness?
5. What result would justify expanding the rewrite?
6. What result would park or kill it?

If those questions are unanswered, the branch is still under-specified, not disproven.

## Good Decomposition Patterns

Common ways to shrink a "major rewrite" into an executable spike:

- extract one hot loop or one serializer instead of rewriting the whole pipeline
- add an adapter layer so the new implementation can sit behind the old interface
- rebuild only the missing capability behind the accessible contract instead of treating unavailable code or platform support as a hard stop
- build a shadow implementation and diff outputs before switching traffic
- replace one stage while keeping the rest of the old pipeline intact
- add a benchmark-only implementation to prove the mechanism before integrating fully
- keep the old path as an oracle during rollout

## Good Framing

Bad:

- "This is a major rewrite, so we should not try it."

Better:

- "The full rewrite is large, but the hot parser can be replaced behind the current interface and checked with differential fixtures."
- "The full storage migration is large, but the scheduler hotspot can be isolated and re-implemented behind a feature flag."
- "The full GPU path is large, but the bucket builder can be rewritten first and measured in isolation."

## When To Park It

After decomposition, parking is reasonable when:

- the smallest spike is still too costly for the expected ceiling
- the boundary cannot be isolated cleanly enough to measure
- there is no practical oracle for safe validation
- the current leading branch has much better value right now
- the rewrite depends on missing prerequisites that are not yet credible

## What To Record In The Branch Log

For rewrite-heavy branches, record:

- smallest_slice
- boundary
- oracle
- fallback
- success_threshold
- park_reason if not active

That keeps the branch reusable instead of collapsing into "too hard."
