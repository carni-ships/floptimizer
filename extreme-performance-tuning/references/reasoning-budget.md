# Reasoning Budget

Use this file when you need to decide how much thinking effort the next step deserves. The goal is to spend deep reasoning on real decision points and keep routine execution light.

## Core Idea

Do not tie reasoning effort only to whether the machine is busy or idle.

Better rule:

- use higher reasoning effort when the next move needs judgment, synthesis, or causal explanation
- use lower reasoning effort when the next move is mostly procedural, repetitive, or already decided

If the agent platform supports explicit reasoning-effort controls, raise or lower them deliberately. If it does not, simulate the same behavior by slowing down, writing the decision frame explicitly, and checking assumptions only for the hard steps.

## Use High Effort For

- refining a fuzzy goal or acceptance criteria
- choosing between several plausible optimization branches
- generating new hypotheses
- explaining why an experiment worked, failed, or stayed inconclusive
- reconciling profiler output with wall-clock behavior
- deciding whether a path is blocked, dead, or merely waiting on prerequisites
- reasoning about path dependence or enabling work
- planning a stack descent or architecture change
- synthesizing literature, exemplar repos, and local measurements into one next move

## Use Medium Effort For

- ranking ideas after the bottleneck is already clear
- interpreting a mostly clean before/after result
- designing a narrow benchmark or ablation
- deciding whether a change is robust enough to keep
- preparing the next short batch of experiments

## Use Low Effort For

- rerunning an already-defined benchmark
- capturing artifacts with the bundled helpers
- polling or waiting on a long job with no new decision to make yet
- filling in templates from already-known results
- harvesting feedback or tuning notes
- applying a routine comparison or cleanup check
- executing a known next step whose reasoning was already done

If the platform supports explicit reasoning-effort controls, this is the right zone for a lower-effort mode.

## Procedure Offloading Rule

If the next steps are deterministic and likely to repeat, do not just lower reasoning effort. Offload the routine itself.

Good candidates for scripting or helper reuse:

- the same benchmark plus capture plus compare loop
- repeated session bootstrap or telemetry collection
- routine artifact harvesting or note aggregation
- fixed sweep grids that do not need fresh judgment at each point
- known process-launch sequences with the same flags and fixtures

Benefits:

- less reasoning spent on mechanics
- less orchestration drift between runs
- easier handoff to another agent
- more reproducible evidence

Guardrails:

- do not script unstable logic too early; wait until the sequence is already understood
- keep the decision points outside the script when they still need judgment
- prefer small composable helpers over one giant opaque automation blob

## Waiting-Time Reframe

Waiting time is not automatically low-effort time.

Use the waiting window this way:

- if the next decision is hard, spend the waiting time on higher-effort work such as hypothesis generation, branch ranking, causal explanation, literature review, or planning the next spike
- if the next decision is already clear, keep the waiting-time work lightweight: artifact review, notes cleanup, harvesting, or simple comparison prep
- if the waiting window is filled with a repeated procedural loop, consider turning that loop into a helper before running it again

The point is to match effort to the cognitive difficulty of the next useful move, not to the CPU usage of the current command.

## Guardrails

- Do not spend high effort trying to explain results from an obviously noisy or contaminated run before fixing the measurement conditions.
- Do not use high-effort analysis as an excuse to avoid making the next bounded experiment.
- After a hard decision is made, step back down to lighter execution mode for the mechanical work.
- If multiple agents are sharing one machine, combine this with the compute-slot rule: one agent may hold the heavy run while another spends higher effort on analysis or planning.
