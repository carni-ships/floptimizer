# Uncertainty And Sensitivity

Use this file when a result might be real but fragile, noisy, or overly dependent on one workload point or one lucky parameter setting. The goal is to tell the difference between a robust win and a narrow anecdote.

## Contents

- Uncertainty
- Sensitivity
- DOE-Lite For Many Knobs
- Robust Versus Fragile Wins
- Claim Language
- Output Format

## Uncertainty

Treat a benchmark result as an estimate, not a fact.

Capture at least:

- run count
- central tendency such as median or mean when appropriate
- spread such as percentiles, min/max, or visible variance
- whether the machine was quiet or noisy

Useful rules:

- small gains on noisy machines are provisional
- gains smaller than normal run-to-run variation are not settled
- reruns on a quieter machine matter more than squeezing out more decimal places

## Sensitivity

Test whether the win survives nearby changes:

- nearby batch sizes, thread counts, or tile sizes
- small, medium, and large inputs
- cold, warming, and warm states
- low, medium, and high concurrency
- a second machine or environment when available

The question is not just "what is best?" It is also:

- where does it stop helping?
- where does it break?
- how narrow is the safe operating region?

## DOE-Lite For Many Knobs

When there are many tunable parameters, do not crawl every combination blindly.

Prefer:

1. a coarse screen of the biggest knobs
2. keep the obvious losers out
3. narrow in on the promising region
4. record interactions that clearly matter

This is especially helpful for:

- batch size
- worker count
- queue depth
- tile size
- stream count
- cache or buffer size

## Robust Versus Fragile Wins

A robust win:

- survives reruns
- survives nearby parameter settings
- survives realistic workload variation
- does not vanish when the machine state changes slightly

A fragile win:

- appears only at one point
- disappears under rerun
- depends on one exact constant
- reverses under a nearby load or input shape

Fragile wins may still be useful, but they must be labeled honestly.

## Claim Language

Prefer language like:

- "robust across 64-96 batch size on this device"
- "provisional; effect is near measurement noise"
- "wins in warm steady-state only"
- "sensitive to memory pressure and not yet portable"

Avoid language like:

- "proven best"
- "universally faster"

unless the evidence really supports that claim.

## Output Format

```text
Run count:
Observed spread:
Stable region:
Fragile edges:
Sensitivity checks run:
Confidence statement:
```
