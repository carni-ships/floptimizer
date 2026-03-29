# Iteration Strategy

Use this file when optimization progress stalls, measurements disagree, or the process starts devolving into random tweaks. The goal is to turn "stuck" into a structured state transition instead of more guesswork.

## Contents

- First Rule
- Stuck-State Loop
- What Kind Of Stuck Is This
- Change Levels, Not Just Tactics
- Path Dependence And Unlock Work
- Keep A Bottleneck Budget
- Use Short Spike Experiments
- Measurement Skepticism
- A Good Default Escalation Rule
- Stop Rules
- Reject Log
- Experiment Journal
- Branch Log

## First Rule

Treat a stalled optimization as evidence that either:

- the bottleneck model is wrong
- the benchmark is noisy
- the current abstraction level is exhausted

Do not respond by piling on more tweaks of the same kind without re-checking those assumptions.

## Stuck-State Loop

When progress stalls:

1. Reconfirm the target metric and success threshold.
2. Re-run the benchmark or profile once on a quieter machine state.
3. Re-check the bottleneck budget.
4. Re-check the ceiling and operating region.
5. Decide whether to keep working at the same layer or change layers.
6. Write down the rejected idea so it does not come back later disguised as something new.

## What Kind Of Stuck Is This

### Case 1: Several tweaks, no measurable improvement

Likely cause:

- wrong bottleneck

Do this:

- re-profile
- rebuild the time budget
- stop touching sub-5 percent slices while larger slices remain

### Case 2: Microbenchmark improves, end-to-end does not

Likely cause:

- the optimized kernel is not dominant
- the gain is being erased elsewhere

Do this:

- trace the whole pipeline again
- inspect stage boundaries, queueing, and data movement
- assume Amdahl's law is winning until proven otherwise

### Case 3: Profiler results bounce around or contradict wall-clock numbers

Likely cause:

- noisy machine
- sampling the wrong phase
- unstable workload

Do this:

- rerun after checking for competing local work
- stabilize workload and warmup rules
- compare profiler output against simple wall-clock timing

### Case 4: Code complexity rises but gains are tiny

Likely cause:

- diminishing returns at the current layer

Do this:

- define a stop rule
- step up one abstraction level
- prefer cleaner structural changes over heroic local tricks

## Change Levels, Not Just Tactics

If the current layer is exhausted, switch layers deliberately.

Move upward when low-level tuning stalls:

- algorithm
- batching
- data layout
- contention or ownership model
- query plan
- pipeline or architecture boundaries
- hardware offload

Move downward when high-level redesign stalls:

- emitted assembly
- allocator behavior
- syscall mix
- cache misses
- vectorization quality
- lock scope

Also change ownership of the problem when needed:

- inspect whether the hot path is actually inside a dependency
- check library configuration and feature flags
- compare the current dependency version against newer releases
- consider a better-fit library or a narrow upstream patch if the dependency is the limiter

## Path Dependence And Unlock Work

Some optimizations are dependency chains, not isolated tricks.

Typical examples:

- batching enough work to amortize GPU dispatch
- reducing copies so offload stops losing to data movement
- tightening memory layout so SIMD or vectorized kernels become viable
- simplifying ownership so parallel execution can scale
- shrinking intermediate state so a fused pipeline fits cache

When you suspect path dependence:

1. Name the downstream win explicitly.
2. List the prerequisites that must be true for that win to materialize.
3. Check which prerequisites are currently missing.
4. Treat the prerequisite work as part of one optimization path, not as random standalone tweaks.
5. Re-measure after the enabling step and again after the downstream step.
6. If the path is still blocked, write down the concrete unblockers before you park it.

Example:

- Goal: move a kernel from CPU to GPU.
- Prerequisites: larger batches, fewer host-device round-trips, tighter layout, lower temporary memory pressure.
- Wrong evaluation: reject batching because it only gives a small CPU-side win.
- Better evaluation: keep batching if it materially improves the eventual end-to-end GPU path.

This is still not a license for speculative rewrites. The downstream path needs a believable hypothesis and a measurable target.

## Keep A Bottleneck Budget

At any point, write down the current estimated budget:

```text
DB time: 35%
Lock wait: 22%
Parsing: 18%
Serialization: 10%
Other: 15%
```

Then optimize only the largest remaining contributors. Once a slice becomes small, move on.

## Use Short Spike Experiments

Do not fully implement every idea. Run narrow experiments first:

- "What if this path were batched?"
- "What if data were SoA instead of AoS?"
- "What if this used Accelerate or a vendor primitive?"
- "What if this stage were parallel?"
- "What if this queue boundary disappeared?"
- "What prerequisite is blocking the optimization I actually want?"

Spikes are for falsifying or validating a direction quickly, not for polishing.

## Measurement Skepticism

Do not trust one run if the machine may be busy.

Before keeping a result, check for:

- other agent sessions running work
- local builds or tests still active
- editor or search indexing
- Docker pulls or container startup
- browser, sync, or backup activity
- another optimization experiment hitting the same machine

Run [`../scripts/machine_noise_check.sh`](../scripts/machine_noise_check.sh) when the local machine state is unclear.

If any of those are active:

- label the result as provisional
- rerun on a quieter machine state
- prefer repeated measurements over one "great" number

If the machine itself is the bottleneck right now:

- stop spawning new compute-heavy processes for a while
- do not stack more benchmarks, builds, or profiling jobs onto an already saturated box
- use the pause for non-competing work: read previous captures, update the experiment log, rank branches, generate new hypotheses, inspect dependencies, or do a bounded literature review
- resume heavy measurement only after the machine has cooled down, pressure has dropped, or unrelated work has settled

If multiple agents share the same machine:

- treat heavy compute as a shared slot, not a free-for-all
- let one agent hold the slot for long benchmarks, profiles, or builds
- have the other agents switch to lower-load work until the slot is released

If a long benchmark, profile, or compile is already running and is not being contaminated:

- keep the run isolated
- set an expected duration, a soft checkpoint, and a hard stop before you drift into passive waiting
- use the waiting time for non-competing work that helps the next step
- if the next decision is hard, raise the reasoning budget and use the window for hypothesis generation, branch ranking, causal explanation, or bounded literature review
- if the next decision is already clear, keep the work lighter: compare earlier captures, clean up branch notes, prepare ablations, or update templates
- bad choices: launch another heavy run, start a large build, or do anything likely to distort the measurement window

Use [`wait-budgets.md`](wait-budgets.md) as the canonical waiting-policy reference when you need the detailed rules or defaults.

If the run passes the soft checkpoint:

- check whether output, stage counters, CPU, IO, or device activity still show healthy progress
- continue only if the run is still likely to produce trustworthy information

If the run passes the hard stop:

- terminate it unless there is strong evidence that completion is imminent and the result will still be worth keeping
- record why you killed it or why you chose to let it continue

## A Good Default Escalation Rule

- 2 failed tweaks at the same layer: re-profile
- 3 failed passes at the same layer: change abstraction level
- 1 isolated micro-win with no end-to-end win: trace the whole pipeline again

If the bottleneck is known, the space is evolving quickly, and the hypothesis set is getting stale:

- do a bounded literature review
- prefer recent primary sources and similar high-performance systems
- come back with one to three concrete experiments, not a giant reading list

If known patterns and literature are no longer adding enough ideas:

- generate a few first-principles speculative branches
- use bottleneck physics, not random brainstorming
- label those branches clearly as speculative
- give each one a tiny falsifiable spike

If a promising path keeps getting dismissed as “too big”:

- separate the smallest bounded spike from the imagined full rollout
- estimate the spike in agent-executable terms, not human-project terms
- test the spike if it is cheap enough to produce a strong yes or no
- only park the branch as too large after the spike itself is genuinely too costly or too low-value
- if the spike is promising but the full rewrite is not yet justified, keep the branch parked with explicit revisit conditions instead of dropping it

If the local code keeps getting cleaner or faster in isolation but end-to-end progress is stuck:

- inspect imported libraries, drivers, runtimes, and storage engines in the profile
- verify whether the real bottleneck sits behind an abstraction boundary
- treat dependency replacement, upgrade, reconfiguration, or upstream contribution as legitimate branches
- if a path looks blocked only by the current environment, record the hardware or resource change that would make it worth retrying

If a result looks real but attribution is muddy:

- keep the control baseline stable
- run a quick ablation pass on the winning bundle
- separate direct wins from enabling work before overcommitting to the wrong explanation

If a result looks real but fragile:

- run nearby settings and a couple of representative workload variants
- record whether the gain is robust, narrow, or still provisional
- do not hard-code lucky numbers as general guidance

If the local win looks real but shipping risk remains:

- define rollout and rollback before calling the work done
- add at least one regression guardrail

## Stop Rules

Useful rules:

- stop low-level tuning after 3 attempts in a row produce negligible end-to-end gain
- stop optimizing a slice once it is no longer a dominant fraction of runtime
- stop custom-kernel work if a standard optimized library is already close enough to target
- before declaring a path exhausted, do one final narrowly scoped literature and repo search for that exact process, file, algorithm, or subsystem

The purpose of a stop rule is not to give up early. It is to stop wasting attention after the likely wins have moved elsewhere.

That final outward check should be tight:

- search only the exact hotspot class
- prefer recent primary sources and well-known fast codebases
- extract one to three final ideas, not a new giant queue
- if nothing credible appears, close the branch confidently

## Reject Log

Record:

- hypothesis
- change attempted
- expected win
- observed result
- reason rejected

This prevents circular optimization work and makes later passes much faster.

## Experiment Journal

For serious attempts, go one level deeper than the reject log.

Write down:

- what bottleneck the idea targeted
- why it was expected to help
- what assumptions had to be true
- what measurement or profile was used
- why the result was effective, ineffective, or inconclusive
- what specific change would unblock the idea if it is not truly dead
- what would need to change before the idea is worth revisiting

Use [`experiment-log.md`](experiment-log.md) for a compact template.

## Branch Log

When the search space has multiple plausible directions, keep a compact branch log:

- active branches you are testing now
- blocked branches that need a prerequisite
- blocked branches and the concrete changes that would make them viable again
- parked branches that are lower priority
- won and lost branches so you do not rediscover them blindly

Use [`exploration-graph.md`](exploration-graph.md) for the structure. Revisit blocked branches only when their unblock condition changes.
