# Subagent Orchestration

Use this file when one lead agent wants to split an optimization campaign into parallel sub-tasks such as research, implementation, testing, and review without creating duplicate work or self-inflicted machine contention.

## Contents

- Core Model
- Pattern Selection
- When To Split Work
- How Many Subagents
- Branching And Integration
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

## Pattern Selection

Before spawning subagents, choose the orchestration shape on purpose.

Use [`multi-agent-patterns.md`](multi-agent-patterns.md) to decide whether the task is best handled as:

- independent exploration
- disjoint parallel implementation
- phased waves
- sequential handoff
- builder plus verifier overlay

Do not default to a swarm when the dependency graph is still fuzzy or the write scopes overlap.

## When To Split Work

Subagents help when:

- the directions are genuinely distinct
- the write scopes can stay disjoint
- some tasks are low-load research while one task holds the compute slot
- the lead agent can continue making progress without waiting on all branches

Do not split work just because there are many ideas. Split when the work can be cleanly partitioned.

## How Many Subagents

Good default on one shared machine:

- 1 lead agent
- 1 or 2 light-lane subagents
- optionally 1 implementation or testing subagent

That usually means:

- 2 total agents for small or medium work
- 3 total agents as the best default
- 4 total agents when the branches are clearly distinct and coordination is still cheap

Avoid going past 4 or 5 total agents on one shared machine unless:

- most extra agents are read-only research or review agents
- write scopes stay cleanly separated
- heavy compute is still serialized
- the lead agent can still integrate results quickly

Stop adding agents when coordination overhead starts competing with the likely gain.

## Branching And Integration

If a subagent is allowed to edit code, it should usually work on its own git branch or worktree.

Good default:

- one branch or worktree per write-enabled subagent
- one narrow task per branch
- one lead agent reviewing the resulting branch before integration

Integration should usually happen like this:

1. subagent finishes its bounded task on its own branch
2. subagent freezes the review target as an exact commit or checkpoint, and pushes the branch if remote durability or later review depends on it
3. lead agent or assigned heavy-lane verifier validates that exact revision and returns a keep or reject recommendation
4. lead agent reviews the diff, notes, and validation evidence
5. lead agent merges, cherry-picks, or manually ports the branch only if it looks safe
6. lead agent updates the branch log, checkpoint state, and campaign state

Do not let write-enabled subagents commit directly onto the lead agent's working branch.
Do not auto-merge subagent branches just because they completed. Completion is not the same as integration approval.

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

For nontrivial branches, treat `implementation` and `testing/review` as separate responsibilities by default.
One builder writes the branch.
Independent verifiers inspect correctness, regressions, and measurement quality before the lead agent integrates it.

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
6. review subagent branches before merging, cherry-picking, or porting them
7. merge results back into one branch log and campaign ledger
8. make the final keep, park, discard, or preserve decision

The lead agent should not outsource the whole search blindly. It should reconcile the evidence.

## Subagent Contract

Each subagent should receive:

- role
- exact task
- why this pattern was chosen
- success condition
- branch or worktree to use if write-enabled
- allowed write scope
- whether it is read-only or write-enabled
- whether it may launch heavy compute
- acceptance criteria
- validation plan
- exact handoff revision expected for review
- whether the review-ready branch should be pushed
- handoff target
- stop or return condition
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

Use this compact rule:

- parallelize search
- serialize shared-machine measurement
- one heavy lane, many light lanes

The heavy lane is for:

- long builds
- benchmarks
- profiles
- sweeps
- detached or background heavy jobs

The light lanes are for:

- literature review
- exemplar review
- branch ranking
- source inspection
- review
- disjoint editing and bounded code generation on isolated branches
- local cleanup of notes and contracts
- note cleanup and handoff preparation

Good division of labor:

- light-lane agents may research, generate ideas, write code in their owned scope, and commit that work on their own branch or worktree
- the lead agent, or an explicitly assigned heavy-lane verifier, picks up the committed branch for expensive testing, benchmarking, and profiling against the exact handed-off revision
- the heavy-lane verifier returns a keep or reject recommendation
- merge should happen only after the lead agent reviews that evidence and approves integration

This keeps creative and coding throughput high without letting every builder compete for the shared measurement lane.

Rules:

- only one subagent holds the heavy compute slot per shared machine unless interference is known to be negligible
- background or detached jobs still hold the compute slot
- research and review subagents should prefer non-competing mode by default
- before a heavy run, the assigned subagent should check the shared ledger and latest resource gate
- if the machine is saturated or the user requested no fresh heavy compute, subagents should continue with coding, review, planning, or literature work only
- if a light-lane subagent finishes a meaningful code branch, it should checkpoint or commit it before handing it back for heavy-lane validation
- if losing that review target would be costly, or another agent may need to review it later, push the branch and record the remote ref before handoff

## Recommended Task Graph

Good default sequence:

1. lead agent defines the branch frontier
2. research subagent expands or sharpens the hypothesis set
3. implementation subagent changes one bounded path, freezes an exact review target, and commits the branch when ready for review
4. implementation subagent pushes the branch if remote durability is needed and records the branch plus exact revision in the ledger
5. testing subagent or lead agent validates correctness and runs captures while holding the heavy lane
6. review subagent checks invariants and regression risk
7. lead agent integrates the evidence and updates the frontier

Not every branch needs all four roles. Small branches may only need implementation plus testing, or research plus testing.

## Handoff Template

Use a compact handoff like:

```text
agent:
role:
pattern:
branch:
branch_or_worktree:
task:
write_scope:
compute_permission: none | claim-required
acceptance_criteria:
- 
validation_plan:
- 
handoff_commit_or_checkpoint:
- 
handoff_commit_ref:
- 
handoff_remote_ref:
- 
expected_outputs:
- 
handoff_to:
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
- Do not let multiple write-enabled subagents share one active working branch.
- Do not let multiple subagents edit the same file set without serialization.
- Do not let subagents make independent keep or discard decisions without lead-agent reconciliation.
- Do not merge a subagent branch without lead-agent review of the code and the attached evidence.
- Do not allow every subagent to spawn heavy jobs just because they are independent.
- Do not let the builder act as the sole verifier on a risky branch.
- Do not let uncommitted or half-described builder work become the handoff artifact for heavy validation when a clean commit or checkpoint would make review safer.
- Do not let a moving branch head stand in for the review target when an exact commit ref can be recorded.
- Do not assume local-only branch state is durable enough for later review if the branch is costly to recreate or another agent may need it.
- Do not treat “more agents” as a substitute for good branch ranking.
- If the overhead of coordination exceeds the likely gain, collapse back to one lead agent.
