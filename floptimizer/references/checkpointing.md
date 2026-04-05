# Checkpointing

Use this file when the optimization work is multi-step, risky, or exploratory enough that later agents may need to resume, compare, or revert without reconstructing the whole path from memory.

## Core Idea

Use two kinds of checkpoints:

- knowledge checkpoints
- code checkpoints

Knowledge checkpoints preserve what was learned.
Code checkpoints preserve a meaningful implementation state.

Do both after serious results. A negative result is still checkpoint-worthy if it changes the search.
Also checkpoint before risky changes when the last known-good state would otherwise be easy to lose.

## Knowledge Checkpoints

After any serious positive, negative, blocked, or surprising result, record:

- what was tried
- what happened
- why it likely happened
- whether the branch is won, lost, blocked, or parked
- what would justify revisiting it
- what code or branch state captures the current implementation

## Code Checkpoints

Create a code checkpoint when the current implementation is meaningfully valuable even if it is not the final winner yet.

Good candidates:

- a real kept win
- a promising spike that may become a fallback or oracle
- an expensive refactor that would be painful to recreate
- a platform-specific prototype worth revisiting later
- an enabler branch that unblocks several later directions
- a negative result that required substantial engineering and may become a future comparison point
- a correct but non-winning build that may become useful again with another pass or different prerequisites

Good code checkpoints are usually:

- a dedicated git branch or worktree
- one or more intentional commits
- a note in the branch log or coordination ledger pointing to that branch

When subagents are involved:

- preserve their meaningful implementation state on the subagent's own branch or worktree
- have the lead agent review that branch before integrating it
- treat reviewed integration as a separate step from simply preserving the branch

## Pre-Risk Rollback Checkpoints

Before a risky refactor, invasive optimization, or boundary change:

- checkpoint the last known-good implementation if losing it would make rollback slow or uncertain
- record where that rollback point lives
- treat that preserved state as the recovery point if the new branch regresses performance, correctness, or operability

This is different from preserving the new branch. One checkpoint protects the stable baseline; the other preserves an exploratory implementation state.

## Default Rule

Checkpoint progress after:

- a serious benchmark or profile result
- a branch status change such as `won`, `lost`, `blocked`, or `parked`
- finishing a significant refactor slice
- before switching away from a risky or hard-to-recreate implementation
- before starting another major direction that may overwrite or destabilize the current one

## When A Build Deserves Preservation

Preserve the current build on its own branch or worktree when:

- the build is expensive or awkward to recreate
- it demonstrates a real mechanism worth keeping
- it may serve as a rollback point
- it may serve as a correctness oracle
- it may become useful again if prerequisites change
- it is correct but not a net improvement yet, and a later pass may still unlock it
- it demonstrates a useful mechanism even if the current surrounding code prevents the full win

Do not throw away a meaningful build just because it is not today’s winner.

Correct-but-non-winning builds should usually be marked as parked, not discarded.
They are especially worth preserving when:

- the implementation is expensive to recreate
- the code is clean enough to iterate on later
- the idea is still believable but not yet amortized, integrated, or tuned
- another branch may later remove the blocker that kept it from winning

## When Notes Are Enough

Notes alone are usually enough when:

- the change was tiny and trivial to recreate
- the result was obviously bad and low-cost
- the branch never got beyond a small local probe

The rule is not "commit every edit." The rule is "do not lose expensive learning or hard-won state."

## Suggested Fields

When checkpointing, record:

- checkpoint_type: knowledge | code | both
- branch_status
- checkpoint_reason
- preservation_class: rollback-baseline | winner | fallback | oracle | non-winning-correct | enabler | comparison-point
- previous_good_branch_or_worktree
- previous_good_commit_ref
- preserved_branch_or_worktree
- commit_ref if any
- rerun_or_rebuild_hint
- revisit_trigger
