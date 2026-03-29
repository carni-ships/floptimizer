# Experiment Log

Use this file when the optimization is non-trivial enough that another agent, or your future self, may need to understand what was tried and why it did or did not work.

## Why Keep This

- prevents the same bad idea from being rediscovered later
- preserves surprising wins that only make sense with the surrounding context
- makes path-dependent work easier to revisit after prerequisites change
- helps another agent tell the difference between `failed idea` and `not ready yet`

## What To Record

For each serious attempt, capture:

- hypothesis
- expected mechanism of improvement
- prerequisite assumptions
- exact benchmark or profile used
- result summary
- why the result was effective, ineffective, or inconclusive
- confounders or machine-noise concerns
- concrete unblockers if the idea failed only because of the current environment or prerequisites
- revisit condition if the idea is blocked rather than dead

Keep lightweight tweaks lightweight. Use detailed notes for expensive, surprising, risky, or path-dependent experiments.

## Good Questions To Answer

- What bottleneck did this change target?
- Why did we think it would help?
- What had to be true for the idea to pay off?
- What actually changed in the numbers?
- If it failed, what invalidated the hypothesis?
- If it partly worked, what is still blocking the full win?
- What hardware, resource, dependency, or prerequisite change would make this worth trying again?
- What would make this worth revisiting later?

## Suggested Template

```text
experiment: shorten serialization path
status: won | lost | blocked | inconclusive
target_bottleneck: CPU hot path in request encoding
hypothesis: fewer copies and smaller intermediate buffers will reduce CPU and p99
expected_mechanism: less allocator churn and less memory traffic in the encode stage
prerequisites: request shape is stable enough to reuse buffers
setup: bench_capture run 20260328T...
result: CPU -11%, p99 -7%, RSS unchanged
why: buffer reuse cut allocation churn, but JSON formatting still dominates total encode time
confounders: machine was quiet, warm-state only
unblockers: binary wire format or pre-serialized cache on the hot path
revisit_when: if binary wire format is introduced, rerun this path
```

## Heuristics

- prefer cause-and-effect language over change logs
- write enough that a different agent can decide whether to revive the idea
- distinguish `lost` from `blocked`
- if the result was noisy, say so explicitly
- if the win depended on warm state, say so explicitly

## Where To Attach It

- keep short summaries in the branch log
- keep run-specific reasoning next to the measurement capture
- if the idea looks reusable beyond the current project, also fill in the `Reusable Optimization Trick Candidate` section so it can be harvested into the catalog
- include the highest-signal kept and rejected ideas in the final report
