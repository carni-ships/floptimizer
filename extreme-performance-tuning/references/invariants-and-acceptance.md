# Invariants And Acceptance

Use this file before a serious optimization pass and before declaring the work done. The goal is to define what must stay true, what minimum win counts as real, and what evidence is required before keeping the change.

## Contents

- Invariants
- Acceptance Criteria
- Minimum Effect Size
- Evidence Required
- Keep Or Reject
- Output Format

## Invariants

Write down the properties that must not break:

- correctness of outputs
- precision or numerical tolerance
- ordering or determinism requirements
- durability or transactional guarantees
- memory ceiling or resource cap
- startup or recovery behavior
- debuggability and observability
- security and privacy constraints

This is stronger than "run tests." It tells the agent what a fast-but-bad change would violate.

## Acceptance Criteria

Before running a serious experiment, define:

- the primary metric that must improve
- the operating region where it must improve
- the guardrails that must not regress
- the rollback trigger if it ships

Example:

- p99 latency improves by at least 10 percent
- holds at production-like concurrency
- RSS does not grow by more than 5 percent
- error rate and timeout rate do not worsen

## Minimum Effect Size

Do not let tiny wins create large complexity by default.

Choose a threshold such as:

- at least 5 percent end-to-end improvement
- or enough absolute gain to matter to the user or budget

Smaller wins can still be kept, but only when:

- the cost is almost zero
- the change is a clear enabler
- or multiple small wins are intentionally stacking toward a larger target

## Evidence Required

Before calling a change accepted, prefer:

- a trustworthy control baseline
- repeated measurement or a clear enough effect size
- correctness or invariant checks
- ablation when a bundle is doing the winning
- sensitivity checks when the result may be narrow

If the evidence is weaker than that, label the result provisional instead of settled.

## Keep Or Reject

Keep the change when:

- it meets the acceptance threshold
- it preserves the invariants
- the evidence is strong enough for the intended risk level

Reject or defer it when:

- the gain is below the minimum meaningful threshold
- the invariants are not proven
- the win is too fragile for the intended operating region
- the complexity or operational risk outweighs the expected value

## Output Format

```text
Invariants:
Primary acceptance target:
Guardrails:
Minimum meaningful win:
Evidence required:
Decision:
```
