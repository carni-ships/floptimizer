# Campaign Loop

Use this file when the optimization effort is no longer a single local tuning pass, but a multi-run campaign with many branches, retries, and keep-or-discard decisions.

## Core Idea

Keep two layers of records:

- rich capture artifacts for detailed evidence
- a compact campaign directive and ledger for quick orientation

The rich captures stay the source of truth.
The campaign files make it easy for another agent to understand the current objective, the keep or discard rule, and the history of serious runs without rereading every capture directory.

## Recommended Files

For a campaign workspace, keep:

- `campaign.md`: human-editable directive for the whole effort
- `results.tsv`: one compact row per serious run or decision

Use [`../scripts/campaign_bootstrap.sh`](../scripts/campaign_bootstrap.sh) to create both.

## What `campaign.md` Should Hold

Keep the directive short and stable:

- objective
- primary metric
- target or budget
- benchmark command or evaluation path
- keep or discard rule
- must-not-regress invariants
- operating region that matters
- current leader
- known blockers
- stop rule

This is the meta-level steering document for the campaign.

## What `results.tsv` Should Hold

Use the ledger for compact cross-run comparison, not detailed storytelling.

Recommended columns:

- `timestamp_utc`
- `git_branch`
- `git_head`
- `label`
- `status`
- `decision`
- `description`
- `primary_metric_before`
- `primary_metric_after`
- `delta_pct`
- `noise_status`
- `preservation_class`
- `artifact_path`
- `notes_path`

Use [`../scripts/append_campaign_result.sh`](../scripts/append_campaign_result.sh) to append rows from a capture directory.
When a capture is campaign-aware, its `notes.md`, `capture.env`, `summary.txt`, and `campaign-entry.env` should all reflect whether the run has already been appended or is still pending.

## Keep / Discard Guidance

Good default rules:

- if the primary metric improves without violating invariants, keep
- if the primary metric is flat and the implementation is simpler, safer, or more maintainable, keep
- if the result is correct but not yet winning, park and preserve it if it is still a believable future branch
- if the result is noisy or invalid, mark it clearly instead of pretending it settled anything

## Workflow

1. Bootstrap `campaign.md` and `results.tsv`.
2. Record the baseline.
3. After each serious run, append one compact ledger row.
4. Keep rich evidence in capture folders and link to it from the ledger.
5. When a branch is kept, discarded, parked, or preserved, say so explicitly in the ledger.
6. Keep `campaign_append_status` current in the capture notes so handoffs do not silently skip the ledger update.

## Why This Helps

- another agent can understand the campaign quickly
- repeated work is less likely
- discarded runs still leave learning signal
- simpler but equal-performance wins stay visible
- correct but non-winning branches do not disappear

This is the same spirit as a benchmark score ledger in meta-agent work, but adapted for multi-objective performance engineering.
