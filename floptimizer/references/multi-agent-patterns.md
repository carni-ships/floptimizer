# Multi-Agent Patterns

Use this file when the work clearly benefits from subagents but it is not obvious which orchestration shape fits the task.

## Core Idea

Do not default to one generic swarm.
Pick the pattern that matches the dependency graph, write-scope overlap, and verification needs.

The best default for `floptimizer` is still:

- one lead agent
- one builder at a time per branch
- one or more independent verifiers as needed
- serialized shared-machine measurement

## Pattern 1: Prep Line

Many agents explore the same brief independently.
The lead agent or human then selects what is worth keeping.

Best for:

- design or hypothesis exploration
- literature review from multiple angles
- speculative branch generation
- test or fixture generation variants

Avoid when:

- the agents need to edit the same files
- results must compose automatically

## Pattern 2: Dinner Rush

Many agents implement distinct, disjoint tasks in parallel.
Each one owns a separate file set or module set.

Best for:

- independent components
- disjoint test modules
- page-by-page ports
- separate subsystems with clean ownership

Requirements:

- deeply specific scope
- disjoint write scope
- explicit dependencies
- no shared hot files

The moment two builders need the same files, stop using this pattern.

## Pattern 3: Courses In Sequence

The work is split into waves.
Each wave depends on the outputs of the previous one, but tasks within a wave may run in parallel.

Best for:

- larger refactors
- staged migrations
- dependency-heavy projects
- codebase-wide rebuilds where discovery must come first

This is often the best fit for real project-scale optimization campaigns.

## Pattern 4: Prep-To-Plate Assembly

Different agents handle different phases in sequence.
State lives in files, captures, ledgers, and explicit handoffs, not in one giant conversation.

Best for:

- research-heavy work
- multi-step pipelines
- hardware bring-up
- tasks where one phase materially changes what the next phase should do

Good phases:

- explore
- implement
- validate
- document and checkpoint

## Pattern 5: Builder Plus Verifiers

One builder writes.
Independent verifiers review correctness, regression risk, and measured behavior.

This is not an alternative to the other patterns.
It is a layer you should add on top of them for nontrivial branches.

Best for:

- almost always

Especially important when:

- the branch is risky
- correctness is subtle
- the benchmark could be gamed
- the change is about to be merged or promoted

## How To Choose

Ask:

1. Are the tasks independent enough to run in parallel?
2. Do any builders need the same files?
3. Do results depend on earlier phases?
4. Is the work mostly exploration, implementation, or verification?
5. How much shared-machine compute will the pattern consume?

Practical defaults:

- independent idea generation: prep line
- disjoint implementation: dinner rush
- dependency waves: courses in sequence
- phase-by-phase pipeline: prep-to-plate assembly
- nontrivial branch safety: always add builder-plus-verifiers

## Guardrails

- Do not use dinner-rush parallelism when write scopes overlap.
- Do not let verification collapse back into the builder role for risky branches.
- Do not treat more subagents as better architecture.
- Do not let orchestration shape outrun the quality of the task decomposition.

## Output Format

```text
Chosen pattern:
Why it fits:
Lead agent:
Builder roles:
Verifier roles:
Heavy-lane owner:
Handoff points:
```
