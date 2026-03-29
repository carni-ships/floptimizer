# Wait Budgets

Use this file when a benchmark, profile, build, compile, or long-running experiment may take minutes or longer. The goal is to avoid both idle waiting and infinite waiting on a run that is stuck, untrustworthy, or no longer worth the time.

## Contents

- Why Set A Wait Budget
- Three Numbers To Define
- Healthy Progress Versus Bad Waiting
- What To Do While Waiting
- When To Terminate
- What To Record

## Why Set A Wait Budget

Before launching a long run, forecast how long it is reasonably allowed to occupy attention.

This helps the agent:

- plan useful non-competing work while the run is active
- know when to re-check progress
- avoid waiting forever on a stuck or heavily throttled process
- stop pretending a contaminated run is still worth salvaging

## Three Numbers To Define

For any multi-minute run, define:

- expected duration: the best current estimate from prior runs, workload size, and machine state
- soft checkpoint: when to inspect progress if the run has not finished
- hard stop: the latest point where the run is still worth continuing

Good defaults:

- soft checkpoint: around 1.5x to 2x the expected duration
- hard stop: around 2x to 3x the expected duration

Use wider ranges only when there is a concrete reason, such as:

- cold first build or cache population
- known high-variance distributed setup
- very large datasets
- intentionally exhaustive sweeps

## Healthy Progress Versus Bad Waiting

Healthy progress signs:

- the process still shows meaningful CPU, IO, or device activity
- logs, stage counters, or output files are still advancing
- telemetry shows the machine is busy for the right reason, not just generally overloaded
- the run is within the expected or slightly extended time window

Bad waiting signs:

- no meaningful activity for a long stretch
- no output or stage advancement when output should be moving
- the machine has become so noisy or throttled that the result will not be trustworthy anyway
- telemetry suggests swap churn, severe throttling, or resource exhaustion has taken over
- the run has passed the hard stop with no new evidence that it is close to completion

## What To Do While Waiting

Prefer non-competing work that improves the next step:

- review earlier captures
- update the experiment log
- rank the next branches
- prepare ablations or sensitivity checks
- tighten acceptance criteria
- do a bounded literature review

If the next decision is difficult, spend that time at a higher reasoning budget. If the next step is already decided, keep the waiting-time work lighter and more procedural. Use [`reasoning-budget.md`](reasoning-budget.md) if that distinction is still fuzzy.

Do not launch competing heavy jobs that would distort the measurement window.

## When To Terminate

Terminate the run when one or more of these are true:

- it has passed the hard stop and there is no strong sign of imminent completion
- it appears stuck or idle
- the machine state has become too contaminated for the result to be trustworthy
- telemetry shows the experiment is now dominated by throttling, swap, or unrelated pressure
- the likely information value of continuing is lower than switching to a better next experiment

Do not terminate just because the run is slower than hoped. Terminate when the remaining wait is no longer justified by the expected insight.

## What To Record

If a run is stopped early, record:

- expected duration
- soft checkpoint and hard stop used
- what progress signals were checked
- why the run was allowed to continue or why it was terminated
- whether the problem was likely a real workload cost, a stuck process, or a contaminated environment

That helps later agents decide whether to retry, widen the budget, or abandon the path.

The bundled capture and session helpers now have dedicated wait-budget fields. Prefer recording the budget there instead of leaving it only in free-form notes.
