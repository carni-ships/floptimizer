# Subagent Orchestration

Use this file when one lead agent wants to split an optimization campaign into parallel sub-tasks such as research, implementation, testing, and review without creating duplicate work or self-inflicted machine contention.

## Contents

- Core Model
- When To Split Work
- Good Role Split
- Lead Agent Responsibilities
- Subagent Contract
- Compute Discipline
- Recommended Task Graph
- Handoff Template
- Guardrails

## Core Model

Use a lead-agent model, not a peer swarm.

One agent should stay responsible for:

- the campaign goal
- branch selection
- keep or discard decisions
- final integration
- coordination ledger and campaign ledger sanity

Subagents should own narrow bounded tasks and report back with artifacts, not independent strategy drift.

## When To Split Work

Subagents help when:

- the directions are genuinely distinct
- the write scopes can stay disjoint
- some tasks are low-load research while one task holds the compute slot
- the lead agent can continue making progress without waiting on all branches

Do not split work just because there are many ideas. Split when the work can be cleanly partitioned.

## Good Role Split

Strong default pattern:

- research subagent
  - literature review
  - exemplar scan
  - bounded hypothesis generation
  - no heavy compute unless explicitly assigned the slot
- implementation subagent
  - one bounded code path
  - one claimed module or file set
  - correctness hooks left intact
- testing subagent
  - correctness checks
  - ablations
  - benchmark capture
  - only while holding the compute slot
- review subagent
  - logic review
  - invariant review
  - regression risk review
  - read-only unless reassigned

Useful variants:

- dependency/runtime subagent
- lower-stack inspection subagent
- rollout/regression guardrail subagent

## Lead Agent Responsibilities

The lead agent should:

1. define the campaign objective and current bottleneck
2. decompose work into distinct branches
3. assign one owner per active branch
4. assign explicit write scope per implementation task
5. keep one shared compute slot policy
6. merge results back into one branch log and campaign ledger
7. make the final keep, park, discard, or preserve decision

The lead agent should not outsource the whole search blindly. It should reconcile the evidence.

## Subagent Contract

Each subagent should receive:

- role
- exact task
- success condition
- allowed write scope
- whether it is read-only or write-enabled
- whether it may launch heavy compute
- expected outputs
- where to log results

Expected outputs should usually be one or more of:

- code diff
- experiment notes
- capture directory
- campaign ledger update recommendation
- branch status update
- review finding list

## Compute Discipline

Heavy jobs still need serialization even when the thinking work is parallel.

Rules:

- only one subagent holds the heavy compute slot per shared machine unless interference is known to be negligible
- background or detached jobs still hold the compute slot
- research and review subagents should prefer non-competing mode by default
- before a heavy run, the assigned subagent should check the shared ledger and latest resource gate
- if the machine is saturated or the user requested no fresh heavy compute, subagents should continue with coding, review, planning, or literature work only

## Recommended Task Graph

Good default sequence:

1. lead agent defines the branch frontier
2. research subagent expands or sharpens the hypothesis set
3. implementation subagent changes one bounded path
4. testing subagent validates correctness and runs captures
5. review subagent checks invariants and regression risk
6. lead agent integrates the evidence and updates the frontier

Not every branch needs all four roles. Small branches may only need implementation plus testing, or research plus testing.

## Handoff Template

Use a compact handoff like:

```text
agent:
role:
branch:
task:
write_scope:
compute_permission: none | claim-required
expected_outputs:
- 
done_when:
- 
log_to:
- coordination ledger
- experiment log
- campaign ledger recommendation
```

## Guardrails

- Do not assign the same branch to two active subagents unless the split is explicit and non-overlapping.
- Do not let multiple subagents edit the same file set without serialization.
- Do not let subagents make independent keep or discard decisions without lead-agent reconciliation.
- Do not allow every subagent to spawn heavy jobs just because they are independent.
- Do not treat “more agents” as a substitute for good branch ranking.
- If the overhead of coordination exceeds the likely gain, collapse back to one lead agent.
