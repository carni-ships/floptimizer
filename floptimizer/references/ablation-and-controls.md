# Ablation And Controls

Use this file when a candidate optimization looks real but it is unclear which part of the change actually caused the win. This is especially useful after bundled changes, path-dependent work, or surprising results.

## Contents

- True Control
- Common Ablation Patterns
- Enablers Versus Direct Wins
- Counterfactual Checks
- Claim Discipline
- Output Format

## True Control

Keep one trustworthy control:

- same workload
- same correctness checks
- same machine or equivalent environment
- same warmup rules
- same benchmark command

Do not let the baseline drift while you are trying to attribute a win.

## Common Ablation Patterns

After the full bundle wins, strip pieces back out:

- full bundle versus baseline
- bundle minus one change
- enabling work only versus baseline
- downstream optimization only versus baseline
- vendor primitive versus custom code
- new algorithm with old layout versus new algorithm with new layout

The goal is not perfect academic purity. The goal is to learn which lever is worth keeping.

## Enablers Versus Direct Wins

Some changes are worth keeping because they unlock a later gain, not because they dominate on their own.

Typical pattern:

- batching alone gives a small win
- GPU offload alone still loses
- batching plus GPU offload wins clearly

In that case:

- do not mislabel batching as a failed idea
- record it as enabling work
- keep the path-level explanation with the result

## Counterfactual Checks

When the result is surprising, ask what else could explain it:

- a quieter machine
- warmer caches
- different input mix
- reduced logging or tracing
- a dependency cache hit
- less contention from unrelated work

Useful checks:

- rerun the baseline after the candidate
- rerun the candidate after the baseline
- test nearby settings to see whether the gain is stable
- remove one component at a time from the winning bundle

## Claim Discipline

Only claim what the controls support.

- If one component survives ablation, attribute the win to that component.
- If only the bundle wins, say the bundle wins and the individual contributions are unresolved.
- If a change matters only as an enabler, say so explicitly.
- If the result disappears under control checks, downgrade it to provisional.

## Output Format

```text
Control:
Winning bundle:
Ablations run:
What survived:
What was only enabling:
Confounders checked:
Attribution claim:
```
