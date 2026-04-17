# Agent Coordination

Use this file when multiple agents are exploring optimization ideas in parallel on the same codebase or machine. The goal is to avoid duplicate work, conflicting edits, and self-inflicted compute contention.

## Contents

- Git Is Helpful But Not Enough
- Ownership Model
- Compute Slot Model
- Parallel Search Pattern
- Specialist Subagents
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
- one resource gate check before each new heavy launch
- one explicit non-competing mode when user intent or machine load says "no new heavy jobs"

## Ownership Model

Each active agent should claim:

- agent name
- branch or worktree
- experiment branch or hypothesis
- files or modules currently owned for edits
- current status
- last meaningful checkpoint or preserved branch when relevant

Claims should be:

- narrow
- explicit
- released quickly when the work is done

Do not claim the whole repository when only two files are being edited.

## Compute Slot Model

Code conflicts and compute conflicts are different problems.

Good default slogan on one shared machine:

- parallelize search
- serialize measurement
- one heavy lane, many light lanes

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
- stay in non-competing mode unless the user explicitly reprioritizes

In practice, this usually means:

- light-lane agents can still research, inspect code, generate ideas, and write bounded code changes on their own branches
- the central coordinator, or whichever agent currently owns the heavy lane, is the one who runs the expensive tests, benchmarks, or profiles against the exact committed revision handed off for review
- the heavy-lane reviewer recommends keep or reject based on that evidence
- merge happens only after the lead agent approves integration

A background job still occupies the compute slot until it exits or is terminated. Detached execution frees attention, not machine capacity.
Before starting a new heavy job, run [`resource-gating.md`](resource-gating.md) or [`../scripts/resource_gate.sh`](../scripts/resource_gate.sh). A free compute slot is not enough if the machine itself is already saturated.

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

## Specialist Subagents

When the search benefits from specialized roles, keep the same coordination rules but add explicit role boundaries.

Good pattern:

- one lead agent owns branch ranking and final decisions
- one research subagent expands or sharpens the hypothesis set
- one implementation subagent changes a bounded write scope
- one testing subagent validates correctness and runs captures while holding the compute slot
- one review subagent checks invariants and regression risk
- for nontrivial branches, keep the builder separate from the main verifier roles
- each write-enabled subagent works on its own git branch or worktree
- the lead agent reviews the subagent branch before merge, cherry-pick, or manual porting

Strong operational default:

- light-lane agents do the cheap thinking and branch-local coding
- they commit or checkpoint their branch when it is ready for heavier scrutiny
- they push the branch and record the remote ref when another agent may need to review it later or the state would be costly to lose
- the lead agent or heavy-lane verifier picks up that committed revision, runs the expensive validation, and returns a keep or reject recommendation

Use [`subagent-orchestration.md`](subagent-orchestration.md) when you want a clearer role split, handoff contract, and recommended task graph.

## Minimal Rules

- Prefer one branch or worktree per agent when possible.
- Prefer one branch or worktree per write-enabled subagent, not one shared branch for all active edits.
- Keep a live claim ledger outside of git history assumptions.
- Do not edit files claimed by another active agent without re-coordination.
- Do not launch heavy compute jobs without claiming the compute slot.
- Do not launch a new heavy job if the latest resource gate says `PAUSE`.
- If the user asked for no fresh heavy computation, keep all agents in non-competing mode until that restriction is lifted.
- Record process label, PID or session handle, state path, and latest gate status for heavy jobs. Treat process-list visibility as best-effort; the ledger remains the source of truth.
- Keep the compute slot claimed for background or detached jobs until the process actually ends.
- Record blocked, won, lost, and active experiment branches in one shared place.
- After meaningful results, checkpoint the branch state and, for significant builds, preserve them on a branch or worktree instead of leaving them only in a dirty workspace.
- Record the exact commit ref under review when a branch is handed off for heavy validation, not just the branch name.
- Record the remote ref too when the review target has been pushed.
- Have the lead agent review a subagent's branch before integrating it into the main working line.
- For risky branches, require at least one verifier other than the builder before calling the branch ready for integration.
- If claims overlap, serialize the work rather than hoping merge cleanup will be cheap.
- Release claims quickly when you stop actively working that area.

## Template

Copy or adapt [`coordination-template.md`](coordination-template.md) into the target workspace when multi-agent coordination matters.

If you want a quick starting point instead of hand-copying the template, run:

```bash
scripts/coordination_bootstrap.sh --root .
```
