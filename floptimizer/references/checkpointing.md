# Checkpointing

Use this file when the optimization work is multi-step, risky, or exploratory enough that later agents may need to resume, compare, or revert without reconstructing the whole path from memory.

## Core Idea

Use two kinds of checkpoints:

- knowledge checkpoints
- code checkpoints

Knowledge checkpoints preserve what was learned.
Code checkpoints preserve a meaningful implementation state.

Do both after serious results. A negative result is still checkpoint-worthy if it changes the search.

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

Good code checkpoints are usually:

- a dedicated git branch or worktree
- one or more intentional commits
- a note in the branch log or coordination ledger pointing to that branch

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

Do not throw away a meaningful build just because it is not today’s winner.

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
- preserved_branch_or_worktree
- commit_ref if any
- rerun_or_rebuild_hint
- revisit_trigger
