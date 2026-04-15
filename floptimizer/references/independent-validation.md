# Independent Validation

Use this file when a claimed win needs a fresh look from an evaluator that is not already committed to the implementation story.

## Core Idea

Optimization work is vulnerable to authorship bias.
The same agent that generated the branch can become overly willing to accept the narrative that the branch "should" have helped.

When the result depends on judgment as well as raw metrics, add at least one fresh validation pass with less anchoring.

## Good Times To Do This

- the metric win is real but the semantic proof still feels squishy
- the gain is suspiciously large or strategically important
- the benchmark harness could be gamed in subtle ways
- the optimization changed caching, preprocessing, batching, offload boundaries, or output shaping
- the team is disagreeing about whether the branch really improved the system
- a branch is about to be kept, merged, or promoted into the skill as doctrine

## What "Independent" Means

Aim for one or more of these:

- fresh reviewer who did not write the implementation
- fresh evaluator prompt that does not describe the intended answer
- blind or minimally labeled comparison against the incumbent
- separate correctness oracle or differential test
- separate machine or rerun context when local contamination is plausible

This does not need to become a heavyweight process.
The goal is to reduce anchoring, not to recreate a full paper review.

## Good Patterns

### Incumbent Versus Candidate

Always allow the incumbent to remain the winner.
Do not force the validation setup to choose the new branch just because it exists.

### Fresh Review Pass

Give the reviewer:

- the task or invariant to preserve
- the old and new artifacts or outputs
- the metric summary
- only the minimum context needed to compare them

Avoid telling the reviewer which one is expected to win.

### Differential Proof

When possible, compare:

- old output versus new output
- old behavior versus new behavior
- old operating region versus new operating region

This is especially useful when the optimization changes representation, caching, concurrency, or offload boundaries.

## Guardrails

- Do not overuse this for tiny local tweaks with obvious proofs.
- Do not let "independent validation" become a vague excuse to stall.
- Use stronger isolation only when the cost of being wrong is meaningful.
- If the fresh pass still cannot decide, keep the result provisional instead of forcing certainty.

## Output Format

```text
Why independent validation was needed:
Fresh validator or evaluator:
What context was withheld:
What was compared:
Independent verdict:
What remains uncertain:
```
