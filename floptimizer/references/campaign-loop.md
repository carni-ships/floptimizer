# Campaign Loop

Use this file when the optimization effort is no longer a single local tuning pass, but a multi-run campaign with many branches, retries, and keep-or-discard decisions.

## Core Idea

Keep two layers of records:

- rich capture artifacts for detailed evidence
- a compact campaign directive and ledger for quick orientation

The rich captures stay the source of truth.
The campaign files make it easy for another agent to understand the current objective, the keep or discard rule, and the history of serious runs without rereading every capture directory.
They should also make it clear which branch families are active, which failure patterns have already been learned, and whether the current campaign is evaluating a steering variant of the skill or prompt itself.

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
- branch families to keep alive
- recent failure families to avoid repeating blindly
- known blockers
- evaluator risks
- prompt or skill steering variant under test, if any
- incumbent stop or convergence rule
- independent validation plan for high-stakes keeps
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
If a richer ledger is not yet worth the overhead, use the `description` field to note the branch family and the distinctive change from the nearest failed attempt.

## Keep / Discard Guidance

Good default rules:

- if the unchanged incumbent still wins under fair comparison, keep it and say so explicitly
- if the primary metric improves without violating invariants, keep
- if the primary metric is flat and the implementation is simpler, safer, or more maintainable, keep
- if the result is correct but not yet winning, park and preserve it if it is still a believable future branch
- if the result is noisy or invalid, mark it clearly instead of pretending it settled anything

Do not force change just because another pass ran.
The incumbent remaining best is a legitimate outcome and often the right stopping signal.

## Fresh Validation

When a keep decision is important, or a win feels suspiciously narrative-dependent, add one fresh validation pass:

- a reviewer or evaluator that did not author the branch
- a minimally labeled comparison against the incumbent
- a separate correctness or differential check

This is especially useful when:

- a branch is about to be merged or promoted into the skill
- the change is large, risky, or hard to prove semantically
- the benchmark is easy to game through hidden work shifting

Use [`independent-validation.md`](independent-validation.md) when that second look needs stronger guardrails.

## Resumability

Long campaigns should be resumable, not fragile.

Prefer campaign structure that makes it easy to resume after interruption:

- keep the current leader explicit
- keep the ledger append status current
- checkpoint intermediate branch states worth preserving
- let a later agent pick up from artifacts instead of recomputing everything

If a pass or branch already produced enough evidence to orient the next move, save it in a form that another agent can reuse directly.

## Strategy-Level Evidence

When a campaign is comparing strategies across many tasks, problems, or datasets, do not rely only on anecdotes.

Prefer:

- paired comparisons where possible
- confidence intervals for the aggregate win rate or metric delta
- task-level or cohort-level breakdowns
- a clear note when the sample is still too small to settle the question

This matters most for campaign-level claims like "strategy X is now better than strategy Y," not just for one local benchmark.

## Workflow

1. Bootstrap `campaign.md` and `results.tsv`.
2. Record the baseline.
3. Keep two or three distinct branch families alive while the bottleneck search is still uncertain.
4. Before trying a successor branch, skim the nearest failed or blocked notes and state what this branch changes relative to them.
5. If the incumbent is still best, record that outcome explicitly instead of inventing another forced revision.
6. After each serious run, append one compact ledger row.
7. Keep rich evidence in capture folders and link to it from the ledger.
8. When a branch is kept, discarded, parked, or preserved, say so explicitly in the ledger.
9. Keep `campaign_append_status` current in the capture notes so handoffs do not silently skip the ledger update.
10. If the campaign is testing a skill or prompt framing change, record that variant in `campaign.md` and treat it like any other intervention.
11. For high-stakes keeps, schedule one fresh validation pass before declaring the campaign settled.

## Why This Helps

- another agent can understand the campaign quickly
- repeated work is less likely
- discarded runs still leave learning signal
- the search is less likely to collapse into one local optimum too early
- campaign interruptions are less likely to destroy the current state
- the team is less likely to force change when the incumbent is still best
- simpler but equal-performance wins stay visible
- correct but non-winning branches do not disappear

This is the same spirit as a benchmark score ledger in meta-agent work, but adapted for multi-objective performance engineering.
