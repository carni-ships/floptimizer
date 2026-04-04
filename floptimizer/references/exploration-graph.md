# Exploration Graph

Use this file when the optimization process has multiple plausible directions and you do not want to lose good ideas just because they are blocked right now. This adapts the useful part of autonomous research loops: keep iterating, but keep the search structured.

## Contents

- Core Idea
- Why This Helps
- What To Record Per Branch
- Good Status Meanings
- Revisit Rule
- Practical Loop
- Example
- Guardrails
- Output Format

## Core Idea

Treat the optimization search as a small branching graph, not one linear thread.

Each branch is a hypothesis or direction such as:

- batch requests before GPU offload
- replace JSON with a binary format
- shard the hot map per core
- switch allocator
- move one kernel to Metal

At any point, each branch should be in one of a few simple states:

- active
- won
- lost
- blocked
- parked

## Why This Helps

- good ideas are not forgotten just because they are blocked now
- dead ends are less likely to be rediscovered later
- path-dependent work becomes easier to reason about
- multiple related experiments stay connected to the same parent idea

## What To Record Per Branch

Keep it compact:

- branch name
- parent idea if any
- current status
- expected upside
- blocker or prerequisite
- smallest_slice if the branch is rewrite-heavy
- oracle and fallback if the branch changes a risky boundary
- concrete unblockers such as more GPU memory, lower temp memory pressure, larger batches, or a dependency/runtime change
- missing_capability and smallest_substitute when the path is blocked by unavailable repo access, missing bindings, or unsupported platform support
- source type such as literature-derived, exemplar-derived, or first-principles speculative
- evidence so far
- link or pointer to detailed experiment notes when they exist
- preserved_branch_or_worktree when the implementation state is worth keeping
- checkpoint_ref if a meaningful commit or checkpoint exists
- next trigger for revisiting it

## Good Status Meanings

### active

You are testing this now.

### won

The idea produced a real kept improvement.

### lost

The idea was tested fairly and did not pay off.

### blocked

The idea might work later, but a prerequisite is missing right now.

Examples:

- GPU path blocked on batching
- multicore path blocked on shared ownership
- SIMD path blocked on memory layout
- GPU path blocked on 8 GB VRAM but potentially viable on 24 GB cards
- accelerator path blocked because no backend exists for this runtime yet, but the hot kernel could be ported locally behind the current API
- refactor-heavy fast path parked while the current abstractions or layout still fight the optimization, but worth revisiting because the hot slice is small enough to rewrite incrementally

### parked

The idea may be valid, but it is not worth immediate attention because a larger or cheaper path is better right now.

## Revisit Rule

Do not revisit blocked branches at random. Revisit them when one of these happens:

- a prerequisite has been satisfied
- a nearby branch changed the cost model
- the dominant bottleneck moved
- the current leading path failed

This keeps the process persistent without becoming endless wandering.

## Practical Loop

1. Pick one active branch.
2. Run the smallest fair experiment.
3. Update the branch state.
4. If the current implementation is valuable, checkpoint or preserve it before moving on.
5. If blocked, write the unblock condition explicitly.
6. Periodically scan blocked branches to see whether recent work changed their prerequisites.

If multiple agents are working in parallel:

- assign one owner per active branch
- if roles are specialized, assign one lead agent and explicit research, implementation, testing, or review sub-roles
- avoid overlapping write scopes unless the work is explicitly serialized
- keep heavy compute work behind a shared compute-slot claim
- use a shared coordination ledger so two agents do not accidentally chase the same branch at once

## Example

```text
branch: GPU offload for scoring kernel
status: blocked
expected_upside: high
blocker: batches are too small and copies dominate
unblockers: larger batches, lower temp memory pressure, or a GPU with more memory
evidence: kernel alone is faster, end-to-end is worse
revisit_when: batch coalescing lands and temp buffers shrink
```

Later:

```text
branch: request coalescing
status: won
expected_upside: medium alone, high as enabler
evidence: batch size rose 6x, copy count fell 4x
next: revisit GPU offload branch
```

## Guardrails

- Do not keep dozens of active branches; keep the frontier small.
- Do not use branching as an excuse to avoid pruning.
- A blocked branch is not a win; it is deferred uncertainty.
- Periodic revisiting is good. Circular rediscovery is not.
- In multi-agent mode, branch ownership should be explicit, not implied.

## Output Format

```text
Active branch:
Other branches:
- name / status / blocker-or-result / revisit trigger
```
