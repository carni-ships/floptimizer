---
name: floptimizer
description: |
  Aggressive but safe performance optimization skill for any software stack. Use when the user wants to cut latency, raise throughput, reduce CPU, memory, disk, network, GC, cold-start, binary-size, or build-time costs; profile an application or service; remove hot paths; tune databases, caches, queues, kernels, runtimes, compilers, or deployment topology; or squeeze substantial speedups from code or infrastructure without unsafe changes.
---

# Floptimizer

Portable skill for Codex, Claude, Grok, and other agents. Keep the workflow agent-agnostic: prefer plain shell commands, standard profilers, reproducible benchmarks, and evidence from the target system over platform-specific magic.

Some bundled helpers were built and tested primarily for local macOS workstation use, then generalized where practical. On Linux, containers, CI runners, remote hosts, or unusual filesystems, treat local-machine helpers such as cleanup, noise checks, and platform probes as best-effort guidance: prefer audit modes first, inspect what the script is about to do, and adjust commands to the host environment before applying cleanup or system-level changes.

> **One Rule:** Measure first. Prove behavior unchanged. Change one major lever at a time. Re-profile after every real win.

## Fast Loop

1. Baseline the real workload.
2. Profile the dominant hotspot.
3. Prove the behavior you must preserve.
4. Pick one lever with strong upside.
5. Implement and measure again.
6. Re-profile because bottlenecks shift.

## Fast Scorecard

For a quick next-step choice, score each idea informally:

| Idea | Impact (1-5) | Confidence (1-5) | Next-step cost (1-5) | Quick score |
|---|---:|---:|---:|---:|
| Example hotspot fix | 4 | 4 | 2 | 8.0 |

Use `impact * confidence / next-step cost` only as a fast triage aid. For real tradeoffs, fall back to [`references/idea-ranking.md`](references/idea-ranking.md).

## Behavior Proof Checklist

Before keeping a change, write down what stayed true:

- ordering preserved?
- tie-breaking preserved?
- precision or numerical tolerance unchanged?
- randomness or seed behavior unchanged?
- golden outputs, fixtures, or differential checks still pass?

Use [`references/invariants-and-acceptance.md`](references/invariants-and-acceptance.md) when the proof needs to be more explicit.

## Top-Level Anti-Patterns

- optimizing before profiling
- bundling unrelated performance changes together
- trusting a one-off noisy win
- changing behavior "while we're here"
- keeping a result without correctness or invariant proof
- overfitting to one machine or one benchmark point

## Core Operating Mode

- Optimize for measurable outcomes, not aesthetic code changes.
- Get aggressive only after identifying the bottleneck with data.
- Prefer big wins before micro-optimizations: algorithms, batching, indexing, data layout, contention removal, serialization reduction, cache strategy, and topology changes.
- Consider preprocessing and input shaping as first-class optimization levers. A better-normalized, sorted, packed, canonicalized, or prefiltered input can make downstream code dramatically cheaper.
- Treat redundant processing as a first-class clue: repeated parsing, validation, encoding, copying, fan-out, scans, retries, and recomputation are often signals of removable work.
- Treat dependencies as part of the optimization surface. If profiles point into libraries, runtimes, drivers, or imported packages, include version choice, configuration, replacement, or upstream fixes in the search space.
- Treat some optimizations as path-dependent. A change may be valuable because it unlocks a later win, not because it is the final win by itself.
- Keep the search structured. Track branches of ideas, mark blocked ones explicitly, and revisit them when enabling work changes the prerequisites.
- When a path is blocked or looks dead in the current environment, write down what would unblock it: more memory, a different device class, larger batches, lower temporary memory pressure, a dependency upgrade, cleaner ownership, or some other concrete change.
- When the blocker is missing access or missing implementation support, ask whether the missing capability can be recreated locally as the smallest bounded shim, adapter, port, or replacement. Do not try to bypass access controls or private code boundaries; build around the missing surface if the contract can be inferred safely enough to measure.
- Do not reject a direction only because the full rollout sounds like a major human project. First scope the smallest bounded spike that could falsify or validate it, and estimate that effort separately from the eventual production implementation.
- Keep refactor-heavy directions alive when the upside is real. A large eventual rewrite is not a reason to discard a branch if a narrow hot-slice spike or staged rewrite could still teach something important.
- Do not halt a promising rewrite-heavy direction with "too major of a lift" until you have written the smallest slice, boundary, oracle, and fallback. Use [`references/rewrite-decomposition.md`](references/rewrite-decomposition.md) when that decomposition is not obvious.
- Write down the reasoning behind serious attempts so later agents can tell why an idea won, failed, or is merely blocked.
- Preserve correctness, security, durability, privacy, and debuggability. Do not introduce undefined behavior, benchmark-only hacks, silent precision loss, unbounded memory growth, or durability regressions.
- Change one performance variable at a time whenever possible so gains remain attributable.

## Quick Start

1. Pin the target metric and success threshold.
2. Reproduce the slow path with a stable workload.
3. Reuse or build the smallest representative benchmark and correctness checks for the hot path before changing it.
4. For a one-command kickoff, run [`scripts/perf_session_bootstrap.sh`](scripts/perf_session_bootstrap.sh) to gather machine context, scout tools, optionally capture a baseline, and create a starter report.
5. Capture the environment with [`scripts/system_snapshot.sh`](scripts/system_snapshot.sh) when you are not using the bootstrap helper.
6. Check for competing local work with [`scripts/machine_noise_check.sh`](scripts/machine_noise_check.sh) when you are not using the bootstrap helper.
7. When machine-level limits may matter, capture broad telemetry with [`scripts/profile_telemetry.sh`](scripts/profile_telemetry.sh) or let the benchmark capture helper do it for you.
8. If multiple agents share the workspace or machine, bootstrap a live claim ledger with [`scripts/coordination_bootstrap.sh`](scripts/coordination_bootstrap.sh) before parallel edits or heavy runs.
9. Wrap baseline and candidate runs with [`scripts/bench_capture.sh`](scripts/bench_capture.sh) so the exact command, git state, wait budget, coordination context, noise report, telemetry, and raw output are preserved.
10. Compare captured baseline and candidate runs with [`scripts/bench_compare.sh`](scripts/bench_compare.sh) before trusting a claimed win.
11. Audit cleanup opportunities with [`scripts/safe_cleanup.sh`](scripts/safe_cleanup.sh) if disk pressure, swap pressure, or stale caches are likely to contaminate measurements.
12. Discover available profilers, cleanup opportunities, and benchmark tools with [`scripts/tool_scout.sh`](scripts/tool_scout.sh).
13. Refine the goal with [`references/goal-refinement.md`](references/goal-refinement.md) if the success criteria or operating region are still fuzzy.
14. Profile the dominant bottleneck before changing code.
15. Rank hypotheses with [`references/idea-ranking.md`](references/idea-ranking.md) instead of following novelty or intuition.
16. Keep a small branch log of active, blocked, won, lost, and parked ideas.
17. Keep an experiment journal with hypothesis, mechanism, result, and revisit conditions for serious attempts.
18. Implement, measure, and keep only changes that survive re-benchmarking and correctness checks.

Load these references as needed:
- [`references/benchmarking.md`](references/benchmarking.md) for workload design, noise control, and before/after reporting.
- [`references/system-telemetry.md`](references/system-telemetry.md) for broader machine-level signals such as thermal pressure, swap churn, storage saturation, device-memory cliffs, and other unconventional bottlenecks.
- [`references/resource-gating.md`](references/resource-gating.md) for deciding whether the machine is healthy enough to launch another heavy run and how to label that run for other agents.
- [`references/non-competing-mode.md`](references/non-competing-mode.md) for analysis-only or low-load operation when the user requests no fresh heavy computation or the machine is too busy for more load.
- [`references/reasoning-budget.md`](references/reasoning-budget.md) for matching deeper thinking effort to hard decision points and keeping routine execution lighter.
- [`references/wait-budgets.md`](references/wait-budgets.md) for forecasting how long long-running benchmarks, builds, or profiles are worth waiting on before re-checking or terminating them.
- [`references/bottleneck-map.md`](references/bottleneck-map.md) for bottleneck classification and the fastest next diagnostic move.
- [`references/goal-refinement.md`](references/goal-refinement.md) for turning vague speed goals into a concrete primary metric, operating region, and stop rule.
- [`references/invariants-and-acceptance.md`](references/invariants-and-acceptance.md) for defining what must stay true, what minimum effect size counts as a real win, and what evidence is required before keeping a change.
- [`references/ceiling-analysis.md`](references/ceiling-analysis.md) for estimating maximum plausible upside before deep tuning.
- [`references/idea-ranking.md`](references/idea-ranking.md) for ordering candidate ideas by impact, ceiling, validation speed, enablement value, and risk.
- [`references/ablation-and-controls.md`](references/ablation-and-controls.md) for keeping a true baseline, running ablations after bundled wins, and distinguishing direct wins from enabling work.
- [`references/uncertainty-and-sensitivity.md`](references/uncertainty-and-sensitivity.md) for deciding whether a gain is robust, fragile, noisy, or too narrowly tuned to trust.
- [`references/agent-coordination.md`](references/agent-coordination.md) for parallel multi-agent experiment work, disjoint write ownership, and compute-slot coordination on shared machines.
- [`references/iteration-strategy.md`](references/iteration-strategy.md) for what to do when optimization progress stalls, how to change abstraction levels, and how to distrust noisy profiling runs.
- [`references/exploration-graph.md`](references/exploration-graph.md) for keeping a branching hypothesis log, marking blocked directions, and revisiting them when prerequisites change.
- [`references/experiment-log.md`](references/experiment-log.md) for recording why a serious experiment worked, failed, or stayed blocked so later agents can reuse the reasoning.
- [`references/checkpointing.md`](references/checkpointing.md) for deciding when to checkpoint learning, when to preserve a build on its own branch or worktree, and how not to lose expensive intermediate states.
- [`references/scaling-analysis.md`](references/scaling-analysis.md) for concurrency, batch-size, and saturation sweeps that reveal the real operating region.
- [`references/tuning-matrix.md`](references/tuning-matrix.md) for preserving per-environment parameter wins when hardware, firmware, driver, or runtime differences move the optimum.
- [`references/research-strategy.md`](references/research-strategy.md) for bounded literature review when the bottleneck class is known and recent work may expand the hypothesis set.
- [`references/novel-hypothesis-generation.md`](references/novel-hypothesis-generation.md) for generating speculative first-principles branches after known patterns and literature have already been mined.
- [`references/rewrite-decomposition.md`](references/rewrite-decomposition.md) for breaking a "too major" rewrite into a bounded spike, containment boundary, oracle, and fallback path.
- [`references/self-supplied-capabilities.md`](references/self-supplied-capabilities.md) for what to do when the blocker is missing repo access, unavailable architecture support, a missing backend, or some other absent capability that may be worth rebuilding locally.
- [`references/language-quickstart.md`](references/language-quickstart.md) for a fast first profiler command and common hotspot-grep ideas by language.
- [`references/lower-level-language-choice.md`](references/lower-level-language-choice.md) for deciding when a hotspot should stay in the current language, move into a native core, and which target language is usually the best fit.
- [`references/hardware-acceleration.md`](references/hardware-acceleration.md) for SIMD, GPU, Metal, accelerator, and heterogeneous-compute decisions.
- [`references/apple-silicon-cpu.md`](references/apple-silicon-cpu.md) for deeper Apple Silicon CPU tuning with NEON, matrix-oriented CPU paths, compiler-inspection workflow, and choosing between Accelerate, intrinsics, and Metal.
- [`references/optimization-playbook.md`](references/optimization-playbook.md) for aggressive but safe tuning ideas across application, runtime, database, network, OS, and build layers.
- [`references/rollout-and-regression.md`](references/rollout-and-regression.md) for shipping the win safely and preventing silent performance regressions later.
- [`references/self-improvement.md`](references/self-improvement.md) for turning repeated execution friction into evidence-backed skill updates instead of ad hoc rewrites.
- [`references/trick-catalog.md`](references/trick-catalog.md) for consulting and contributing to the reusable trick repository built from prior runs.
- [`references/paper-ready-findings.md`](references/paper-ready-findings.md) for capturing novel or publication-worthy findings in a form that can be assembled into a paper later.
- [`references/exemplars.md`](references/exemplars.md) for a navigation index to high-performance open-source repos worth studying once the bottleneck class is known.
- [`references/pattern-catalog.md`](references/pattern-catalog.md) for a navigation index to reusable optimization patterns distilled from those exemplars.

For small or local hotspot tasks, start with the minimum useful set:

- [`references/benchmarking.md`](references/benchmarking.md)
- [`references/bottleneck-map.md`](references/bottleneck-map.md)
- [`references/idea-ranking.md`](references/idea-ranking.md)

Load the rest only when the situation clearly calls for them.

Fast routes:

- fuzzy goal or tradeoff confusion: [`references/goal-refinement.md`](references/goal-refinement.md), [`references/invariants-and-acceptance.md`](references/invariants-and-acceptance.md)
- noisy, fragile, or hardware-sensitive results: [`references/system-telemetry.md`](references/system-telemetry.md), [`references/uncertainty-and-sensitivity.md`](references/uncertainty-and-sensitivity.md), [`references/tuning-matrix.md`](references/tuning-matrix.md)
- hard next-step judgment or unclear interpretation: [`references/reasoning-budget.md`](references/reasoning-budget.md), [`references/idea-ranking.md`](references/idea-ranking.md), [`references/iteration-strategy.md`](references/iteration-strategy.md)
- bundled changes with unclear attribution: [`references/ablation-and-controls.md`](references/ablation-and-controls.md)
- stuck optimization search: [`references/iteration-strategy.md`](references/iteration-strategy.md), [`references/exploration-graph.md`](references/exploration-graph.md), [`references/research-strategy.md`](references/research-strategy.md), [`references/novel-hypothesis-generation.md`](references/novel-hypothesis-generation.md)
- parallel agent search on one workspace or machine: [`references/agent-coordination.md`](references/agent-coordination.md)
- accelerator, SIMD, or device-specific work: [`references/hardware-acceleration.md`](references/hardware-acceleration.md), [`references/apple-silicon-cpu.md`](references/apple-silicon-cpu.md), [`references/system-telemetry.md`](references/system-telemetry.md)
- productionization and guardrails: [`references/rollout-and-regression.md`](references/rollout-and-regression.md)

If local source inspection would help, clone or refresh the exemplar set with [`scripts/fetch-exemplars.sh`](scripts/fetch-exemplars.sh). For straightforward local hotspot work, the default short loop is: bootstrap a session, check admission with [`scripts/resource_gate.sh`](scripts/resource_gate.sh) when the machine is shared or suspect, capture a baseline, make one change, capture again, compare with [`scripts/bench_compare.sh`](scripts/bench_compare.sh), then open deeper references only if the result is noisy or ambiguous. Use the other helpers only when the situation calls for them: [`scripts/machine_noise_check.sh`](scripts/machine_noise_check.sh) for a shared or suspect machine, [`scripts/resource_gate.sh`](scripts/resource_gate.sh) before starting another heavy run, [`scripts/coordination_bootstrap.sh`](scripts/coordination_bootstrap.sh) when multiple agents are involved, [`scripts/profile_telemetry.sh`](scripts/profile_telemetry.sh) plus [`scripts/telemetry_summary.sh`](scripts/telemetry_summary.sh) when machine-level limits may matter, [`scripts/harvest_tuning_matrix.sh`](scripts/harvest_tuning_matrix.sh) and [`scripts/harvest_skill_feedback.sh`](scripts/harvest_skill_feedback.sh) when you want to preserve reusable learning, and [`scripts/safe_cleanup.sh`](scripts/safe_cleanup.sh) when stale artifacts, disk pressure, or swap pressure may be contaminating measurements.

## Phase 1: Frame the Problem

Before optimizing, capture:

- The exact metric: p50, p95, p99, throughput, CPU time, wall time, RSS, allocator churn, query latency, startup time, build time, cloud cost, or binary size.
- The target: explicit budget or percentage improvement.
- The workload: dataset size, request mix, concurrency, warmup rules, and production similarity.
- The environment: hardware, VM/container limits, OS, runtime version, compiler flags, and relevant service topology.
- The guardrails: what must not regress.

If the user is vague, ask only the missing questions needed to define success. Otherwise proceed and state your assumptions.

If the goal is still too fuzzy to guide tradeoffs, open [`references/goal-refinement.md`](references/goal-refinement.md) before choosing optimization ideas.
If the must-not-break properties or minimum meaningful win are still fuzzy, open [`references/invariants-and-acceptance.md`](references/invariants-and-acceptance.md) before running an expensive experiment campaign.
If the user explicitly wants progress without starting fresh heavy computation, enter non-competing mode and use [`references/non-competing-mode.md`](references/non-competing-mode.md) to choose coding, review, planning, and research work that does not add major load.
If the next move is clearly judgment-heavy, raise the reasoning budget before deciding it. Use [`references/reasoning-budget.md`](references/reasoning-budget.md) when you need a quick rule for when to think harder versus staying procedural.
If the next move is mostly a known sequence of tool calls, captures, comparisons, or process launches, lower the reasoning budget if the platform supports it. If that sequence is likely to repeat, prefer a small script or helper so the agent stops re-solving the same orchestration problem.
When a promising direction feels “too large,” scope the next falsifying spike before parking it. Use [`references/idea-ranking.md`](references/idea-ranking.md) to separate next-step effort from full rollout effort.
If the hesitation comes from rewrite scope rather than true evidence, open [`references/rewrite-decomposition.md`](references/rewrite-decomposition.md) and decompose the path before allowing yourself to park it.

## Phase 2: Build a Trustworthy Measurement Harness

- Reuse existing tests, benchmarks, traces, dashboards, and production samples when they are representative.
- If nothing usable exists, create the smallest faithful harness possible.
- If correctness coverage is weak around the optimized behavior, add the smallest targeted tests, fixtures, property checks, or differential checks needed to catch semantic drift.
- When a benchmark command is likely to be reused, run it through [`scripts/bench_capture.sh`](scripts/bench_capture.sh) so the exact command line, environment, git state, wait budget, coordination context, and raw output stay attached to the result.
- For non-interactive multi-minute runs, prefer [`scripts/bench_capture.sh`](scripts/bench_capture.sh) with `--detach` so the run stays supervised while the agent uses the waiting window for non-competing work.
- When a multi-step measurement or capture sequence becomes routine, script it or reuse a bundled helper instead of re-orchestrating it from scratch each time.
- Measure both central tendency and tails. Median-only wins can still worsen p99.
- Keep a real control baseline. If a bundled change wins, use [`references/ablation-and-controls.md`](references/ablation-and-controls.md) to determine which part mattered and which part was only enabling work.
- Separate cold, warming, steady warm, and rewarm or reset costs when cache state or precomputation changes the result.
- Sweep concurrency, batch size, input size, or thread count when the workload is shape-dependent; do not trust one operating point if saturation behavior matters.
- When the best parameters may move across hardware or firmware environments, preserve a tuning matrix per environment instead of one global magic number.
- In that tuning matrix, separate portable conceptual direction from machine-specific fine-tuning so later agents on different hardware know what to reuse and what to re-sweep.
- Segment the workload when aggregate metrics might hide the dominant cohort.
- Control noise: warm caches intentionally, stabilize input size, avoid mixed workloads unless that is the real production case, check for competing local work such as other agents, builds, indexing, or background services before trusting a run, and audit swap or storage pressure with [`scripts/safe_cleanup.sh`](scripts/safe_cleanup.sh) when the box looks resource-constrained.
- Before launching a new compute-heavy run on a shared or suspect machine, run [`scripts/resource_gate.sh`](scripts/resource_gate.sh) and obey it. If the gate is not `READY`, or if the user asked for no fresh heavy jobs, switch into non-competing mode and use [`references/non-competing-mode.md`](references/non-competing-mode.md) until conditions change.
- For serious or ambiguous runs, collect broad system telemetry such as swap, memory pressure, disk usage, thermal or power signals, IO behavior, and accelerator utilization or memory where available. Use [`references/system-telemetry.md`](references/system-telemetry.md) and [`scripts/profile_telemetry.sh`](scripts/profile_telemetry.sh) when the machine itself may be part of the bottleneck.
- When a long-running run has a meaningful wait budget, record the expected duration, soft checkpoint, and hard stop directly in the capture or session helper instead of leaving them only in free-form notes.
- When multiple agents are sharing one machine or repository, record the coordination ledger path, write scope, and compute-slot context in the session or capture metadata so handoff does not rely on memory.
- If the result may be narrow, noisy, or hardware-sensitive, use [`references/uncertainty-and-sensitivity.md`](references/uncertainty-and-sensitivity.md) before declaring it robust.
- If telemetry or noise checks say the machine is currently throttled, saturated, or busy with other work, stop launching new compute-heavy jobs for a while and switch into non-competing mode. Use that time for code review, low-risk refactoring, harness preparation, reviewing prior findings, tightening hypotheses, ranking branches, literature review, or planning the next spike.
- If a benchmark, profile, or build will run for minutes or longer, set an expected duration, a soft checkpoint, and a hard stop. Use [`references/wait-budgets.md`](references/wait-budgets.md) if that budget is unclear.
- If the run is non-interactive and the platform supports reliable supervision, prefer launching it in the background or a detached session with logs, PID or session handle, and a clean termination path captured. Free the agent's attention; do not free the compute slot.
- Label heavy spawned jobs in capture and coordination metadata, and let process-list visibility be a best-effort bonus where the platform honors it. Prefer short stable labels tied to the agent and experiment branch.
- Use that waiting time for non-competing work, and match the reasoning budget to the task: deeper effort for hypothesis generation, causal explanation, or branch selection; lighter effort for capture review, note cleanup, and other routine execution. Use [`references/reasoning-budget.md`](references/reasoning-budget.md) if that choice is unclear. Use [`references/wait-budgets.md`](references/wait-budgets.md) for the detailed waiting policy. Do not invalidate the run by starting competing heavy jobs.
- Preserve commands and fixtures so the benchmark can be rerun after each change.
- For serious experiments, record the hypothesis, expected mechanism, result, and revisit condition in the capture notes or a compact experiment journal.
- After serious positive, negative, blocked, or surprising results, checkpoint what was learned immediately. If the current implementation is costly to recreate, strategically important, or a plausible fallback, preserve it on its own branch or worktree before moving on. Use [`references/checkpointing.md`](references/checkpointing.md) when the preservation decision is unclear.
- Update the branch log after serious experiments so blocked directions can be revisited when later work changes their prerequisites.
- If a serious run teaches a generally reusable trick, fill in the `Reusable Optimization Trick Candidate` section in the notes or starter report and periodically harvest it with [`scripts/harvest_trick_candidates.sh`](scripts/harvest_trick_candidates.sh).
- If a run produces a novel, mixed, negative, or otherwise paper-worthy result, fill in the `Paper-Ready Finding` section and periodically harvest it with [`scripts/harvest_paper_findings.sh`](scripts/harvest_paper_findings.sh).
- If multiple agents are exploring in parallel, use [`references/agent-coordination.md`](references/agent-coordination.md) so edit ownership, experiment branches, and compute-heavy jobs are coordinated explicitly. Prefer git branches or worktrees plus a live shared claim ledger rather than git alone.
- If a path failed because of current constraints rather than a bad underlying idea, capture the concrete unblockers so a future agent on different hardware or after other improvements can retry it intelligently.

Default command families:

```bash
# CLI or local program timing
hyperfine '<command>'
/usr/bin/time -l <command>
time -v <command>

# HTTP load
wrk -t4 -c64 -d30s http://127.0.0.1:8080/endpoint
vegeta attack -duration=30s -rate=200 | vegeta report
hey -n 10000 -c 64 http://127.0.0.1:8080/endpoint

# Tracing and syscall visibility
strace -c <command>
ltrace <command>
```

On macOS, substitute `dtrace`, Instruments, `sample`, `spindump`, and Activity Monitor as available. On Linux, prefer `perf`, eBPF tools, `pidstat`, `iostat`, `vmstat`, `sar`, and `bpftrace`.

## Phase 3: Find the Real Bottleneck

Do not start with "common optimizations." Start with the narrowest measurement that can disprove a hypothesis.

As part of triage, make a short note of obvious duplicate work in the current path: the same data parsed twice, the same checks repeated at multiple layers, repeated scans over the same structure, duplicate serialization, redundant retries, or unnecessary round-trips. Even when that is not the dominant bottleneck yet, it is often a strong hint about the next high-leverage cut.

Use this triage order:

1. CPU hot path
2. Locking or scheduler contention
3. Allocations, GC, or memory bandwidth
4. Disk, filesystem, or serialization overhead
5. Network latency, round-trips, or packet loss
6. Database planner, indexing, N+1 access, or transaction scope
7. Cache-miss or data-layout issues
8. Cold-start, binary loading, JIT, or dependency initialization
9. Build or compile pipeline overhead
10. Cross-service topology or queueing effects

If the class is unclear, open [`references/bottleneck-map.md`](references/bottleneck-map.md) and use the symptom-to-diagnosis table.

Before committing to a deep optimization path, open [`references/ceiling-analysis.md`](references/ceiling-analysis.md) and estimate the maximum plausible upside. If the realistic ceiling is too small, change direction early.
Then open [`references/idea-ranking.md`](references/idea-ranking.md) so the next experiment is chosen by end-to-end value rather than novelty.

## Phase 4: Attack Order

Apply optimizations in roughly this order unless evidence says otherwise:

1. Remove unnecessary work.
2. Replace the algorithm or query plan.
3. Reduce bytes moved: copies, parsing, allocations, marshaling, logging, compression, and round-trips.
4. Improve data locality and input shape: tighter structs, columnar access, cache-friendly iteration, better batching, and preprocessing that makes downstream work cheaper.
5. Eliminate contention: finer-grained locks, lock-free queues where justified, sharding, reduced shared state, and asynchronous boundaries.
6. Rebalance the critical path: move work off the request path, precompute, cache, or stream.
7. Tune runtime and compiler behavior: GC, allocators, thread pools, JIT settings, LTO/PGO, vectorization, and target-specific flags.
8. Tune the system surface: DB indexes, connection pools, kernel buffers, file descriptors, NIC settings, storage layout, and queue parameters.
9. Restructure architecture when local tuning is exhausted.

Prefer reversible changes until a gain is proven. Once a direction is clearly winning, deeper refactors are justified. If a refactor-heavy direction has credible upside but is not the best immediate move, park it explicitly instead of treating it as rejected.
Also account for path dependence: sometimes the right next move is enabling work such as batching, layout cleanup, copy reduction, or queue simplification that makes a later optimization finally pay off.

### Stack Descent

When useful gains still seem available, descend the stack deliberately instead of jumping straight to low-level tricks.

Good default descent order:

1. first-party code and algorithm
2. data layout, batching, ownership, and contention
3. dependency and runtime configuration
4. generated code, vectorization, allocator behavior, and syscall mix
5. OS, kernel, driver, storage, network, or firmware tuning
6. hardware-specific fast paths or custom kernels

Descend only when:

- the hot slice is still large enough to matter
- higher-level changes have clearly plateaued
- the measurement is trustworthy
- there is a believable lower-level mechanism to inspect

Do not skip straight to assembly, kernel tuning, or custom offload work when a simpler higher-level cut is still likely to dominate.

## Phase 5: Domain-Specific Tuning

Use [`references/optimization-playbook.md`](references/optimization-playbook.md) and focus only on the relevant sections:

- Application code and algorithms
- Hardware acceleration and heterogeneous compute
- Language/runtime tuning
- Databases and storage engines
- Distributed systems and networking
- Operating system and hardware behavior
- Build, test, and CI performance

When a toolchain-specific profiler exists, prefer it over generic timing:

- Python: `py-spy`, `scalene`, `cProfile`
- Node.js: `node --prof`, DevTools CPU/heap profilers
- Go: `pprof`, `go test -bench`, `go tool trace`
- Rust: `cargo bench`, `criterion`, `perf`, `cargo flamegraph`
- Java/JVM: JFR, async-profiler, JMH
- .NET: `dotnet-trace`, `dotnet-counters`, BenchmarkDotNet
- C/C++: `perf`, `valgrind`, sanitizers, `heaptrack`
- Databases: `EXPLAIN (ANALYZE, BUFFERS)`, slow query logs, lock views

When SIMD, GPU, Metal, CUDA, Core ML, ANE, or other accelerators might matter, consult [`references/hardware-acceleration.md`](references/hardware-acceleration.md) before offloading work. Prefer CPU SIMD and multicore first unless the kernel is already known to be massively parallel and transfer or synchronization overhead is small. Remember that accelerator wins are often path-dependent: batching, layout cleanup, and memory-traffic reduction may be prerequisites rather than optional polish.
When the optimum may vary across GPU memory sizes, CPU core counts, drivers, firmware, or runtime versions, consult [`references/tuning-matrix.md`](references/tuning-matrix.md) and leave behind per-environment parameter notes instead of pretending one configuration is universal.
When writing those notes, mark whether the result is a conceptual direction, a machine-specific lucky number, or a mix. Future agents should trust the principle more than the exact constant.
When the question is whether the hotspot should remain in the current language at all, consult [`references/lower-level-language-choice.md`](references/lower-level-language-choice.md) and choose a narrow native-core spike before reasoning about a wholesale migration.
If the desired fast path is blocked by unavailable repo access, missing bindings, unsupported architecture or accelerator support, or a missing vendor implementation, consult [`references/self-supplied-capabilities.md`](references/self-supplied-capabilities.md) and decide whether to build the smallest local substitute or port instead of halting the direction.

After the bottleneck class is clear, consult [`references/exemplars.md`](references/exemplars.md) and open the domain file that matches the problem. Borrow patterns, validation strategy, and architecture shape; do not cargo-cult code or unverified benchmark claims.
When progress in first-party code stalls, inspect whether the hot path actually lives in a dependency, runtime, driver, or database layer. Consider dependency configuration, version upgrades, alternate implementations, or narrowly scoped upstream patches before assuming the remaining wins must come from local code.
If saturation behavior, batch thresholds, or workload shape matter, consult [`references/scaling-analysis.md`](references/scaling-analysis.md) and sweep the important dimensions before declaring a winner.
When the area is moving quickly and local ideas are running thin, consult [`references/research-strategy.md`](references/research-strategy.md) and do a bounded literature review of recent primary sources before committing to a major direction.
When known approaches are understood but the search space still feels too narrow, consult [`references/novel-hypothesis-generation.md`](references/novel-hypothesis-generation.md) and generate a few first-principles speculative branches. Label them clearly and validate them with small spikes before investing deeply.
Before declaring a process, file, algorithm, or subsystem effectively exhausted, do one last tightly scoped outward check for that exact hotspot in recent papers, maintainer writeups, high-performance repos, and newer implementations. Use it to find one or two final ideas to test, not to restart the search from scratch.
When progress stalls or measurements start disagreeing, consult [`references/iteration-strategy.md`](references/iteration-strategy.md) and re-check that the machine is not being perturbed by unrelated local work.
When there are multiple plausible directions, consult [`references/exploration-graph.md`](references/exploration-graph.md) so blocked ideas stay visible and can be revisited when enabling work lands.
When the reasoning behind a serious attempt is likely to matter later, consult [`references/experiment-log.md`](references/experiment-log.md) and write down why it worked, failed, or remained blocked.
When a run produces a reusable optimization idea, consult [`references/trick-catalog.md`](references/trick-catalog.md), harvest the candidate into `catalog/candidates/`, and prefer `catalog/indexes/curated-tricks.md` over raw candidate cards when reusing prior advice.
When a run yields a paper-worthy finding, consult [`references/paper-ready-findings.md`](references/paper-ready-findings.md) and harvest it into `catalog/papers/arxiv-findings.md` so future agents can assemble a research-style writeup without reconstructing the evidence from scratch.
If multiple paper-ready findings have accumulated, use [`scripts/generate_paper_skeleton.sh`](scripts/generate_paper_skeleton.sh) to draft an arXiv-style paper skeleton with sections, table candidates, and reproducibility notes.

## Phase 6: Validate Side Effects

After each serious optimization pass:

- Rerun functional tests and high-risk edge cases.
- Add or strengthen targeted regression tests when the change touches batching, concurrency, caching, precision, memory layout, serialization, or hardware-offload boundaries.
- Compare memory, CPU, latency tails, and failure behavior.
- Check observability, logging volume, retry behavior, and backpressure.
- Watch for cache invalidation mistakes, stale reads, priority inversion, and queue buildup.
- Confirm the optimization still wins on realistic data sizes, not just toy benchmarks.

If a change only wins under an unrealistic harness, revert it or mark it as experimental.

## Phase 7: Roll Out And Lock In The Win

Before calling the work done:

- consult [`references/rollout-and-regression.md`](references/rollout-and-regression.md) if the change will ship beyond a local benchmark
- define rollout, rollback, and comparison metrics
- confirm the win survives production-like or real traffic
- leave behind at least one regression guardrail such as a benchmark harness, CI perf check, dashboard, or alert
- if the run exposed a missing instruction, trigger gap, script gap, or repeated user correction, capture it as skill feedback and periodically review it with [`references/self-improvement.md`](references/self-improvement.md)

## Deliverable

End with a concise report containing:

- Baseline metric and measurement command
- Top bottleneck found and evidence
- Redundant work found, removed, or left for later
- Dependency or library bottlenecks found, changed, or deferred
- Changes tried, kept, and rejected
- Novel speculative branches considered and what happened to them
- Why the important kept, rejected, or blocked directions behaved the way they did
- Benchmarks and correctness checks used or added
- Branches that remain blocked or parked, and what would unblock them
- Resource, environment, or enabling changes that could revive currently blocked paths
- Final before/after numbers with percentage deltas
- Environment-specific tuning matrix or portability notes when parameters vary across hardware or firmware
- Portable direction versus device-specific fine-tuning when parameters vary across environments
- Tradeoffs, residual risks, and next best opportunities
- Ceiling estimate, saturation notes, or key operating-region assumptions when they matter
- Rollout or regression guardrails for any optimization that should survive beyond this session
- Skill-improvement candidates when the workflow itself was missing something important

When the user wants code changes, implement them instead of only describing them. When the user wants investigation, keep the report tight and evidence-heavy.
