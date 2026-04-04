# Idea Ranking

Use this file after the bottleneck is known and the goal has been refined. The goal is to order candidate ideas so the agent tackles the best next move instead of the most interesting one.

## Ranking Factors

Score each idea informally across these dimensions:

- expected end-to-end impact
- ceiling size
- remaining headroom to the practical floor
- level leverage
- confidence
- validation speed
- enablement value
- implementation cost
- operational risk
- reversibility

## What Each Factor Means

### Expected end-to-end impact

How much could this move the real primary metric in the target operating region?

### Ceiling size

Even if the idea works, is the upside large enough to matter?

### Remaining headroom to the practical floor

How much plausible room is actually left in this slice before you hit the fastest believable version of the required work?

This keeps the agent from over-investing in a slice that still looks hot but is already close to its practical floor.

### Level leverage

At what level is this idea operating, and is that the level most likely to matter?

Good questions:

- does this remove work at a higher level?
- does this reorganize the work so later wins become possible?
- does this squeeze unavoidable work that higher-level changes have already failed to remove?

Use [`optimization-levels.md`](optimization-levels.md) when the current branch set is too concentrated at one abstraction level.

### Confidence

How strongly do profiles, traces, exemplars, or prior experiments support it?

### Validation speed

How quickly can the idea be tested fairly?

### Enablement value

Does this unlock a blocked higher-upside branch later?

### Implementation cost

How much code, migration effort, or coordination will it take?

Score this in two layers:

- next-step cost: the smallest fair spike needed to learn whether the direction is real
- rollout cost: the cost of productionizing the idea if the spike wins

Do not collapse those into one number. A direction may be expensive to ship but cheap to test.

### Operational risk

Could this create correctness, rollout, durability, or debugging problems?

### Reversibility

Can the change be isolated and reverted easily if it fails?

## Good Default Ordering

Prefer ideas that are:

1. on a dominant slice
2. high-upside relative to the goal
3. fast to validate
4. low blast radius
5. enablers for blocked high-upside branches

All else equal, prefer the highest level that plausibly removes meaningful work, then descend when the work is genuinely necessary and still dominant.

Delay ideas that are:

- expensive rewrites with low ceiling
- local tuning on slices that are already near their practical floor
- beautiful micro-optimizations on tiny slices
- risky infrastructure changes without strong evidence
- speculative tricks that are hard to measure fairly

Do not delay an idea just because the full end-state sounds large if the next meaningful spike is still cheap and informative. Refactor-heavy directions belong in the queue when they have high ceiling or unblock other strong branches.

## Effort Calibration Rule

Before dismissing an idea as “weeks or months of work,” ask:

1. What is the smallest bounded experiment that would tell us whether this direction is real?
2. How much agent effort does that spike actually take, as opposed to full human rollout effort?
3. If the spike wins, what part of the remaining cost is real implementation versus optional polish, rollout, or cleanup?

Bad framing:

- “This rewrite is a major project, skip it.”

Better framing:

- “The full production refactor may be large, but a narrow spike on the hot loop, data boundary, or ownership bottleneck is cheap enough to test this week.”

Use this especially when agents underestimate their own execution ability and accidentally reason in human-project terms instead of next-experiment terms.

## Rewrite Decomposition Rule

Do not park a rewrite-heavy idea until you can say:

- what smallest slice gets rewritten first
- what boundary isolates it
- what oracle checks behavior
- what fallback contains the risk

If those are still vague, the problem is under-decomposition, not necessarily high effort.

Use [`rewrite-decomposition.md`](rewrite-decomposition.md) when the branch sounds large but the ceiling is still attractive.

## Stack Descent Rule

Lower-level ideas can be very valuable, but rank them explicitly instead of treating them as automatic next steps.

Promote a lower-level idea when:

- the hotspot still owns a meaningful share of end-to-end cost
- higher-level options have already been tested or plausibly exhausted
- profiles or telemetry point to a concrete lower-level mechanism such as vectorization quality, allocator churn, syscall mix, lock scope, driver behavior, or kernel overhead
- the likely ceiling is still worth the complexity

Delay a lower-level idea when:

- the dominant win is probably still higher in the stack
- the slice is already too small to matter
- the mechanism is vague
- the measurement is too noisy to trust

## A Simple Ranking Shortcut

When you need a quick decision, use this order:

1. Big and cheap
2. Big and enabling
3. Big but expensive
4. Small but nearly free
5. Small and risky

## Tie-Breakers

If two ideas look similar, prefer the one that:

- tests the core bottleneck more directly
- teaches you more if it fails
- leaves behind reusable measurement or benchmark infrastructure
- keeps blocked branches visible instead of closing options
- attacks the hotspot from a different level when the current search is too concentrated
- descends the stack only as far as the current evidence justifies
- separates spike cost from rollout cost more cleanly

## Output Format

```text
Idea:
Expected impact:
Ceiling:
Confidence:
Validation speed:
Enablement value:
Cost and risk:
Decision:
```
