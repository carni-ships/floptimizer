# Resource Gating

Use this file when multiple agents share one machine and the question is not only who owns the compute slot, but whether the machine is healthy enough for another heavy run at all.

## Core Rule

Do not launch a new heavy benchmark, build, profile, or sweep step just because the compute slot is logically free.

Admission requires both:

- the compute slot is available
- the machine is currently healthy enough for another heavy run

If either condition fails, pause new heavy work and switch to non-competing work.

Use [`non-competing-mode.md`](non-competing-mode.md) as the canonical guide for what that mode allows and when to leave it.

## What To Check Before Launching

Check:

- unrelated CPU-heavy work
- memory pressure and swap churn
- thermal or power limiting signals
- storage saturation or disk pressure
- GPU or accelerator pressure when relevant

The bundled helper [`../scripts/resource_gate.sh`](../scripts/resource_gate.sh) is the default admission check.

## Gate Outcomes

- `READY`: okay to launch the next heavy run
- `REVIEW`: pressure signals deserve caution; prefer non-competing mode unless you have a clear reason to spend the remaining machine budget
- `PAUSE`: do not launch a new heavy run yet; enter non-competing mode

When the gate is not `READY`, do lower-load work instead:

- review earlier captures
- review code and prepare low-risk edits
- refine hypotheses
- update notes
- inspect dependencies
- do bounded literature review
- prepare the next run without starting it

## Process Labels

Label heavy spawned jobs in capture and coordination metadata so other agents can attribute them quickly. If the platform honors custom process names, that label can also help in `ps` or noise checks, but do not rely on OS visibility alone.

Good labels are:

- short
- stable across reruns of the same branch
- descriptive enough to connect process to agent and experiment

Examples:

- `flopt-parser-a`
- `flopt-baseline-json`
- `flopt-sweep-batching`

The label is only a visibility aid. Still record PID, state path, and gate status in the coordination ledger.

## What To Record

For each heavy run, record:

- process label
- PID or session handle
- state path
- gate checked at
- gate status

That lets later agents answer what is running, who owns it, and whether another heavy launch should wait.
