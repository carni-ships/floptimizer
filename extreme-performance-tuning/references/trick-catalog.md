# Trick Catalog

Use this file when you want to turn real optimization runs into reusable public knowledge, or when you want to consult previously learned tricks before inventing everything again.

## Core Idea

Keep three layers separate:

- raw evidence from captures and reports
- candidate trick cards harvested from those runs
- curated trick cards that are safe to reuse more broadly

This prevents one lucky run from becoming doctrine while still letting agents accumulate reusable ideas over time.

## Where Things Live

- `catalog/candidates/`: raw harvested trick candidates
- `catalog/tricks/`: curated trick cards
- `catalog/indexes/candidate-tricks.md`: generated index of candidates
- `catalog/indexes/curated-tricks.md`: generated index of curated cards
- `catalog/schemas/trick-card-template.md`: card structure
- `catalog/docs/contribution-workflow.md`: promotion workflow

## How To Read It

Default order:

1. read curated trick cards first
2. use candidate cards only when researching or looking for speculative directions
3. always check the mechanism, prerequisites, and `not_for` fields before reusing a trick

## How To Contribute

During a serious run, fill in the `Reusable Optimization Trick Candidate` section in `notes.md` or `starter-report.md`.

Good entries capture:

- the trick name
- the symptom pattern
- the mechanism
- prerequisites
- when not to use it
- portable principle versus machine-specific tuning
- evidence level and confidence

Then run:

```bash
scripts/harvest_trick_candidates.sh
```

This will:

- harvest trick candidates from captures and session reports
- emit candidate cards into `catalog/candidates/`
- regenerate the candidate and curated indexes

## Promotion Bar

Promote a trick from `candidate` to `curated` only when:

- the mechanism is clear
- the evidence is believable
- the card explains where it backfires
- it does not merely restate a more general trick already in the catalog

## Guardrails

- keep raw tuning numbers separate from portable direction
- do not promote tricks that only worked because of noisy measurement
- do not treat one hardware-specific lucky point as a general rule
- prefer a smaller number of high-quality cards over a giant noisy list
