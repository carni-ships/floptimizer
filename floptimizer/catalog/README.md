# Performance Trick Catalog

This directory is the reusable knowledge base for optimization ideas learned through real runs.

The key rule is: do not mix raw observations, candidate tricks, and curated public guidance into one bucket.

## Layers

- `cases/`: longer case studies or writeups tied to real optimization runs
- `candidates/`: harvested trick candidates from benchmark captures and session reports
- `tricks/`: curated trick cards that are fit for broader reuse
- `indexes/`: generated navigation pages for candidates and curated tricks
- `papers/`: generated paper-ready findings and draft assembly artifacts
- `schemas/`: templates and structure for trick cards
- `docs/`: contribution workflow and promotion criteria

## Status Model

- `candidate`: one or more runs suggest this trick may generalize
- `replicated`: the same trick worked again in a meaningfully similar or different setting
- `curated`: reviewed and safe to recommend as a reusable idea
- `deprecated`: once-useful guidance that is now misleading or superseded
- `hardware-specific`: useful, but only under clearly bounded environments

## Basic Workflow

1. During a serious run, fill in the `Reusable Optimization Trick Candidate` section in `notes.md` or `starter-report.md`.
2. Periodically run `scripts/harvest_trick_candidates.sh`.
3. Review generated candidate cards in `candidates/`.
4. Promote strong cards into `tricks/` using the template in `schemas/trick-card-template.md`.
5. Rebuild or refresh the indexes so future agents can browse them quickly.

## How Agents Should Use This

- Read `indexes/curated-tricks.md` first when looking for reusable guidance.
- Read `indexes/candidate-tricks.md` only when exploring, researching, or looking for speculative ideas.
- Never treat a candidate card as settled doctrine without checking the evidence and constraints.
