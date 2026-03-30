# Agent Coordination

Use this file when multiple agents are exploring optimization ideas in parallel on the same codebase or machine. The goal is to avoid duplicate work, conflicting edits, and self-inflicted compute contention.

## Contents

- Git Is Helpful But Not Enough
- Ownership Model
- Compute Slot Model
- Parallel Search Pattern
- Minimal Rules
- Template

## Git Is Helpful But Not Enough

Git helps with:

- isolation
- diff review
- rollback
- merge visibility

But git alone is not enough for live coordination.

Git tells you what changed after the fact. It does not reliably tell another agent:

- what files are currently being edited
- which experiment branch is actively owned
- who is about to run a heavy benchmark
- whether a compute-heavy slot is already occupied

Best default: use git for source control and a shared coordination ledger for live intent.

The bundled helper [`../scripts/coordination_bootstrap.sh`](../scripts/coordination_bootstrap.sh) can create a ready-to-edit ledger under `.perf-coordination/coordination-ledger.md` so coordination does not stay theoretical.

Good setup when available:

- one branch or worktree per agent
- a narrow write-ownership claim
- one shared compute slot for heavy builds, profiles, or benchmarks

## Ownership Model

Each active agent should claim:

- agent name
- branch or worktree
- experiment branch or hypothesis
- files or modules currently owned for edits
- current status

Claims should be:

- narrow
- explicit
- released quickly when the work is done

Do not claim the whole repository when only two files are being edited.

## Compute Slot Model

Code conflicts and compute conflicts are different problems.

One agent may own:

- `src/encoder.rs`

while another agent owns:

- `src/runtime/queue.rs`

but only one of them should hold the heavy compute slot for:

- long benchmarks
- profiling sessions
- large builds
- sweep runs
- detached or background heavy jobs

When the compute slot is occupied:

- other agents should prefer low-load work
- prepare next experiments
- review earlier findings
- update coordination notes

A background job still occupies the compute slot until it exits or is terminated. Detached execution frees attention, not machine capacity.

## Parallel Search Pattern

A good parallel pattern is:

1. Split the search into distinct hypothesis branches.
2. Assign one owner per branch.
3. Assign disjoint write scopes whenever possible.
4. Use one shared ledger for write claims and compute-slot claims.
5. Require agents to check the ledger before editing or launching heavy jobs.
6. Require agents to release claims when the branch is paused, blocked, or complete.

Good candidate split:

- Agent A: batch/coalescing path
- Agent B: dependency/runtime configuration path
- Agent C: SIMD or lower-stack inspection path

Bad candidate split:

- Agent A and B both editing the same hot module without explicit serialization
- multiple agents launching independent heavy benchmarks on the same shared machine

## Minimal Rules

- Prefer one branch or worktree per agent when possible.
- Keep a live claim ledger outside of git history assumptions.
- Do not edit files claimed by another active agent without re-coordination.
- Do not launch heavy compute jobs without claiming the compute slot.
- Keep the compute slot claimed for background or detached jobs until the process actually ends.
- Record blocked, won, lost, and active experiment branches in one shared place.
- If claims overlap, serialize the work rather than hoping merge cleanup will be cheap.
- Release claims quickly when you stop actively working that area.

## Template

Copy or adapt [`coordination-template.md`](coordination-template.md) into the target workspace when multi-agent coordination matters.

If you want a quick starting point instead of hand-copying the template, run:

```bash
scripts/coordination_bootstrap.sh --root .
```
