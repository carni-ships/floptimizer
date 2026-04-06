# Rollout And Regression

Use this file after a local win looks real and before declaring the optimization finished. The goal is to ship the change safely, confirm it survives production traffic, and leave behind guardrails so the win does not quietly disappear later.

## Local Win Is Not The End

A benchmark or staging win can still fail in production because of:

- different traffic mix
- different input sizes
- colder caches
- background load
- different dependency behavior
- safety or observability regressions under real traffic

Untested implementation is not finished local work either. Before calling the optimization complete, run the relevant correctness or invariant checks or explicitly report that validation is still blocked.

## Rollout Plan

Prefer a reversible rollout:

- feature flag
- canary or small cohort
- staged traffic ramp
- easy rollback path

Before rollout, define:

- the metrics that must improve
- the metrics that must not regress
- the rollback trigger
- the comparison cohort or baseline
- the correctness checks or invariants that prove the optimization did not change required behavior

Use [`invariants-and-acceptance.md`](invariants-and-acceptance.md) if those invariants or minimum keep criteria are still not explicit enough.

## Metrics To Watch In Rollout

- throughput and p50, p95, p99 latency
- error rate and timeout rate
- CPU, memory, GC, and allocator behavior
- queue depth, backlog, and retry volume
- dependency load such as DB, cache, or downstream service pressure
- cloud cost or energy if that matters to the goal

## Regression-Proof The Win

Every accepted optimization should leave behind at least one guardrail:

- a reproducible benchmark harness
- a targeted functional regression test, property test, or differential check for the optimized path
- a benchmark or perf smoke test in CI
- a dashboard or alert on the key metric
- a workload fixture that reproduces the hot case
- a note about the critical assumption or operating region

If the win depends on a narrow operating region, document that explicitly.

## Good Rollback Discipline

Rollback quickly when:

- the main metric does not improve in production
- tails, errors, or memory regress
- the optimization shifts cost into another tier
- debugging or observability becomes materially worse

Do not defend the optimization just because the local benchmark looked great.

## Output Format

```text
Rollout strategy:
Metrics to watch:
Rollback trigger:
Regression guardrails added:
Production follow-up:
```
