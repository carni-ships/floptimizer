# Non-Competing Mode

Use this file when the goal is to keep making progress without adding fresh heavy machine load. This can be triggered either by user request or because the machine is already too busy, throttled, or resource-constrained for another serious benchmark, build, profile, or sweep.

## Core Idea

Non-competing mode is an operating mode, not a pause.

The rule is:

- keep making progress
- do not launch fresh heavy jobs
- choose work that helps the next experiment, the next handoff, or the next keep-or-kill decision without materially increasing machine pressure

This mode is about machine load, not mental effort. You can still do high-effort thinking in non-competing mode when the next decision is hard.

## Typical Triggers

Enter non-competing mode when one or more of these are true:

- the user explicitly asks for analysis-only work or asks you not to start fresh heavy jobs
- [`../scripts/resource_gate.sh`](../scripts/resource_gate.sh) returns `PAUSE`
- [`../scripts/resource_gate.sh`](../scripts/resource_gate.sh) returns `REVIEW` and there is no strong reason to spend the remaining machine budget right now
- another agent already holds the heavy compute slot
- a detached or background heavy run is already active and should stay isolated
- telemetry shows thermal throttling, swap churn, high memory pressure, storage saturation, or heavy unrelated work

## Good Work In This Mode

Useful non-competing work includes:

- code review and source inspection
- low-risk code edits or refactors that do not require immediate heavy validation
- harness cleanup, fixture preparation, and test-oracle design
- experiment-log updates, branch-log updates, and checkpointing
- result interpretation and causal explanation
- hypothesis generation and branch ranking
- dependency inspection and configuration review
- bounded literature review or exemplar study
- drafting the next experiment batch
- writing or improving small helper scripts that remove repeated orchestration

## Avoid In This Mode

Do not start fresh heavy work such as:

- new benchmark campaigns
- new profiling sessions
- large builds or rebuild-heavy toolchains
- broad sweeps
- full heavy test suites
- multiple concurrent container or VM tasks
- anything likely to distort the machine state for the currently running experiment

Small targeted checks are still fine when they are genuinely light and do not fight the current machine state.

## Reasoning Budget

Non-competing mode does not imply low-effort thinking.

- If the next decision is hard, spend the quiet window on higher-effort work: hypothesis generation, branch ranking, design reasoning, or literature synthesis.
- If the next decision is already clear, keep the work lighter: note cleanup, capture review, ledger updates, or script preparation.

Use [`reasoning-budget.md`](reasoning-budget.md) if the cognitive side of that choice is unclear.

## Coordination Rule

If multiple agents share one machine:

- one agent may hold the heavy compute slot
- the others should default to non-competing mode until the slot is released or the resource gate becomes healthy again
- record the current work mode in the coordination ledger so another agent does not mistake quiet analysis for idle capacity

## Exit Conditions

Leave non-competing mode when:

- the user explicitly wants fresh heavy measurement again
- the active detached or background heavy run ends or is terminated
- the compute slot is free
- the resource gate returns `READY`
- telemetry and noise checks no longer show meaningful contention

Until then, prefer steady progress over fresh machine contention.
