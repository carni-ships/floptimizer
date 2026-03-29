# Contribution Workflow

Use this workflow when an optimization run produces a reusable idea that might help future systems.

## Goal

Capture reusable tricks without turning one lucky run into public advice too early.

## What Counts As A Good Trick

A good trick card has:

- a clear mechanism, not just a benchmark delta
- a recognizable problem shape or symptom pattern
- prerequisites or enabling conditions
- a `not_for` section so it does not get cargo-culted
- enough evidence that another agent can decide whether to try it

## Contribution Steps

1. Record the idea in the run notes or session report under `Reusable Optimization Trick Candidate`.
2. Keep the fields compact and causal.
3. Harvest those entries into `catalog/candidates/` with `scripts/harvest_trick_candidates.sh`.
4. Review the candidate for duplication, overfitting, and missing constraints.
5. Promote it into `catalog/tricks/` only when the mechanism and scope are clear enough for broader reuse.

## Promotion Heuristics

Promote a candidate when most of these are true:

- the run had trustworthy measurement
- the trick has a portable principle separate from lucky numbers
- the card explains when not to use it
- the evidence level is at least `single-run` with strong mechanism, or stronger
- the candidate does not merely restate a more general curated trick already present

Prefer `replicated` or `curated` status when:

- the trick worked in multiple runs
- the trick survived a different hardware or workload setting
- another agent or case study independently supports it

## Anti-Patterns

- turning machine-specific tuning numbers into global guidance
- promoting tricks with no mechanism
- storing only implementation steps rather than the reusable idea
- keeping cards that cannot answer “when does this backfire?”
- skipping evidence links back to the source run

## Public-Facing Quality Bar

Anything in `catalog/tricks/` should be readable by:

- another agent using this skill
- a human contributor
- a public reader who was not present for the original run

That means the card should stand on its own.
