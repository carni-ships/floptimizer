# Search Diversity

Use this file when the optimization effort is getting stuck in one family of ideas and needs a healthier frontier.

## Core Idea

A search can fail even when every local step is reasonable.
One common failure mode is premature convergence: too many branches explore tiny variants of the same idea family, so the campaign never discovers a different level or mechanism that would have unlocked the real win.

Keep the active frontier small, but not monolithic.

## Good Branch Families

Examples of distinct families:

- local operation rewrite
- data layout or memory-shape change
- algorithm or representation change
- pipeline or boundary reorganization
- dependency or runtime change
- hardware, offload, or accelerator path

These families can still share a bottleneck target, but they attack it from different levels.

## Good Default

When the answer is still uncertain, keep:

- one leading family
- one alternative family at a nearby level
- optionally one more speculative or enabling family

In practice, two or three distinct families are usually enough.
Five variants of the same local tweak are not a diverse frontier.

## When To Widen The Search

Widen when:

- the leading family has produced several flat or noisy runs
- each new branch sounds too similar to the last failed one
- the hotspot remains material but local headroom looks small
- the team is arguing about details inside one family instead of questioning the family itself

## When To Collapse The Search

It is fine to narrow to one family when:

- that family has produced repeated, validated wins
- competing families have been tested fairly and lost
- the remaining work is mostly implementation detail inside an already-proven direction

## Feed Forward Failure

Search diversity does not mean forgetting failed work.

Before trying a successor branch:

1. read the nearest failed or blocked attempts
2. say what this branch changes relative to them
3. record what future branches should avoid if this one also fails

That keeps the search exploratory without becoming repetitive.

## Output Format

```text
Leading family:
Alternative family:
Speculative or enabling family:
Why each one is meaningfully different:
What the next branch learned from prior failures:
```
