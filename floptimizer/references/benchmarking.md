# Benchmarking Reference

Use this file when the task needs a trustworthy benchmark, a fair before/after comparison, or a way to explain why a measured win is believable.

## Contents

- Benchmark Design Checklist
- Noise Control
- Metrics To Capture
- Broad System Telemetry
- Wait Budgets
- Cold, Warm, And Rewarm
- Scaling And Saturation
- Good Comparison Practice
- Capture Helper
- Common Benchmark Traps
- Sanity Checks Before Trusting A Number
- Report Template

## Benchmark Design Checklist

- Match production shape: input sizes, concurrency, cache warmth, request mix, and dependency behavior.
- Pair the benchmark with a correctness oracle. If needed, create a small representative fixture, regression test, property check, or differential comparison so "faster" does not silently mean "wrong."
- Define the minimum meaningful win and must-hold invariants before a long optimization pass. Use [`invariants-and-acceptance.md`](invariants-and-acceptance.md) when that boundary is still fuzzy.
- Separate warmup from measurement for JITed or cache-sensitive systems.
- If warm state matters, measure at least three phases separately: cold, warming, and steady warm.
- Include the cost to populate, maintain, clear, or rebuild warm state when that work is part of the real system.
- Record hardware, OS, runtime, compiler flags, container limits, background load, and when relevant the driver or firmware version.
- Prefer a repeatable capture wrapper for important runs. [`../scripts/bench_capture.sh`](../scripts/bench_capture.sh) records the exact command, git context, system snapshot, machine-noise report, telemetry, wait-budget fields, coordination context, stdout, stderr, and exit status in a timestamped folder.
- If the same multi-step benchmark workflow will be repeated, script it or use the existing helpers so the agent can stay in a low-effort execution mode and avoid orchestration drift.
- Use stable fixtures. If data generation is random, save the seed.
- Keep the benchmark narrow enough to isolate the hot path, but broad enough to remain representative.
- If the benchmark exercises transformed outputs, compare them against a trusted implementation or saved expected results.
- If performance depends on load shape, sweep concurrency, batch size, input size, or thread count instead of testing only one point.
- If the winning settings may move across hardware sizes or driver versions, keep a per-environment tuning matrix instead of one global "best" parameter set.
- In that matrix, distinguish portable direction from machine-specific fine-tuning so future runs on other hardware know what to trust.
- If the workload is heterogeneous, segment results by dominant cohorts rather than relying only on the aggregate number.
- For serious runs, collect machine-level telemetry too: swap, memory pressure, disk usage, thermal or power state, and accelerator utilization or memory when available.
- Keep a true control baseline and run ablations after bundled wins so you know what actually helped. Use [`ablation-and-controls.md`](ablation-and-controls.md) when attribution is unclear.
- If the result may be fragile or tuned to one narrow point, run sensitivity checks and record uncertainty. Use [`uncertainty-and-sensitivity.md`](uncertainty-and-sensitivity.md).

## Fast Behavior-Proof Checklist

For many optimizations, a quick written proof is enough to prevent accidental semantic drift:

- ordering preserved?
- tie-breaking preserved?
- precision or tolerance still acceptable?
- RNG seeds or nondeterministic behavior unchanged where required?
- golden outputs, fixtures, or differential checks still pass?

If the answer is unclear for any of those, do not wave it through as "probably fine." Use [`invariants-and-acceptance.md`](invariants-and-acceptance.md) and add the smallest targeted proof you need.

Untested implementation is not complete. If the proof or checks could not be run yet, mark the result as `implementation-only` or `blocked-on-validation` instead of calling the task done.

## Noise Control

- Run enough iterations to distinguish signal from noise.
- Prefer medians and percentiles over a single best run.
- Avoid benchmarking while package installs, indexing, Spotlight, backups, or CI neighbors are active.
- Check for unrelated local work before trusting a profiler or benchmark run: other agent sessions, builds, test suites, editors indexing, browser load, sync clients, Docker pulls, or background compilers can invalidate a result. Use [`../scripts/machine_noise_check.sh`](../scripts/machine_noise_check.sh) when working locally.
- If swap use is elevated or disk headroom is low, treat that as benchmark contamination too. Use [`../scripts/safe_cleanup.sh`](../scripts/safe_cleanup.sh) to audit reclaimable caches and stale artifacts before trusting a run.
- If the machine is shared with other active work, record that fact and re-run on a quieter machine state before keeping an optimization.
- On laptops, note thermal throttling and power mode.
- If frequency scaling or noisy neighbors cannot be controlled, disclose that limitation.

## Metrics To Capture

- Wall-clock latency: p50, p95, p99
- Throughput: requests/sec, jobs/sec, rows/sec
- CPU: total time, user/sys split, scheduler wait
- Memory: RSS, heap, allocation rate, GC pause time
- IO: bytes read/written, IOPS, queue depth
- Network: RTT, bandwidth, retransmits, handshake overhead
- Build/CI: compile time, test time, cache hit rate, artifact size
- Warm-state economics when relevant: cache-fill time, rewarm time, invalidation cost, extra memory retained, and background work needed to stay warm
- Thermal and power: temperature when available, thermal pressure, power-source mode, clock or frequency caps
- Accelerator pressure: GPU or device utilization, device memory used vs total, copy volume, throttle or power state
- Machine-level counters that may explain weird results: swapins, swapouts, page pressure, IO utilization, queue depth, and storage headroom

## Broad System Telemetry

Sometimes the machine is part of the bottleneck.

Collect broader telemetry when:

- flamegraphs and wall-clock behavior disagree
- long runs flatten or regress after a warm start
- GPU or accelerator work looks promising but does not scale
- throughput changes with no obvious source-code explanation
- swap, thermal throttling, disk saturation, or device-memory cliffs are plausible

Use the bundled helper for a best-effort snapshot or repeated sampling:

```bash
scripts/profile_telemetry.sh --once --target-path .
scripts/profile_telemetry.sh --interval 5 --samples 6 --target-path .
```

Or rely on [`../scripts/bench_capture.sh`](../scripts/bench_capture.sh), which now records `telemetry.txt` alongside the benchmark output and generates a smaller `telemetry_summary.txt` for comparisons and handoff.

Use [`system-telemetry.md`](system-telemetry.md) when you need help interpreting those signals.

## Wait Budgets

For multi-minute benchmarks, profiles, builds, or sweep steps, forecast how long the run is reasonably worth waiting on.

Before launching the run, define:

- expected duration
- soft checkpoint for progress review
- hard stop for likely termination

Use [`wait-budgets.md`](wait-budgets.md) when the expected runtime is fuzzy or when the process may get stuck or heavily throttled.

If you already know the budget, record it in the capture or session helper up front so later agents do not have to infer why the run was killed or allowed to continue.

A long run should not create passive waiting. It should create a bounded window for non-competing work while the run stays isolated. Use [`wait-budgets.md`](wait-budgets.md) for the detailed waiting policy and [`reasoning-budget.md`](reasoning-budget.md) if you need help choosing between deeper analysis and lighter execution work during that window.

If the run is non-interactive and expected to last more than a few minutes, prefer background or detached supervision when the environment supports reliable logs and termination. Keep the compute slot claimed and revisit the run at the soft checkpoint instead of hovering on it continuously.

## Cold, Warm, And Rewarm

Warm is often faster, but it is not automatically better.

Measure these separately when cache state, precomputation, or warm buffers matter:

- cold: first-hit behavior with nothing populated
- warming: the period where state is being built or caches are being filled
- steady warm: the stable warmed state
- rewarm or reset: the cost to clear, invalidate, rotate, or rebuild that state

Watch for false wins:

- lower latency only because memory use grew sharply
- great warm numbers with very expensive invalidation or rebuild
- background warming work shifting cost off the measured path
- warm-state gains that disappear during deploys, failover, rebalancing, or dataset changes

Keep a warm optimization only if the real workload amortizes its population and reset costs.

## Scaling And Saturation

When the system is load-sensitive, capture a small sweep rather than one point:

- low, medium, and near-saturation concurrency
- small, medium, and large batch sizes
- representative input-size buckets
- different thread or worker counts when those are tunable

Record where:

- throughput stops improving much
- tails begin to degrade sharply
- queue depth starts growing
- retries, timeouts, or lock wait appear

Use [`scaling-analysis.md`](scaling-analysis.md) when the sweep is a first-class part of the investigation.

## Good Comparison Practice

- Use the same workload, dataset, and environment before and after.
- Use the same correctness checks before and after, especially when changing concurrency, cache behavior, precision, serialization, or offload boundaries.
- Change one major performance lever at a time unless a batch is inseparable.
- When comparing different machines, preserve the best region and cliff points for each environment rather than flattening them into one winner.
- Save the exact commands used for both baseline and candidate runs.
- Keep benchmark artifacts together. A baseline capture and a candidate capture should each have their own timestamped folder with raw outputs preserved.
- When using sampled profilers, compare both the profile and the wall-clock outcome.
- Report both absolute values and percentage deltas.

## Capture Helper

For a one-command kickoff that gathers machine context, scouting output, an optional baseline capture, and a starter report:

```bash
scripts/perf_session_bootstrap.sh --label baseline-session --root . -- hyperfine 'cargo run --release -- input.json'
```

If you already know the exact run you want to preserve, use the lower-level capture helper directly:

Example baseline capture:

```bash
scripts/bench_capture.sh --label baseline -- hyperfine 'cargo run --release -- input.json'
```

Example candidate capture after a change:

```bash
scripts/bench_capture.sh --label candidate -- hyperfine 'cargo run --release -- input.json'
```

Example detached capture for a long non-interactive run:

```bash
scripts/bench_capture.sh --label nightly-sweep --detach -- hyperfine 'cargo run --release -- input.json'
```

Then compare the two captured runs directly:

```bash
scripts/bench_compare.sh .bench-captures/20260329T000000Z_baseline .bench-captures/20260329T000100Z_candidate
```

Each run directory contains:

- `command.txt`: exact quoted command
- `capture.env`: machine-readable metadata such as git SHA, elapsed time, and noise status
- `summary.txt`: quick human-readable summary
- `run_state.env`: live status for detached or still-running captures
- `stdout.txt` and `stderr.txt`: raw command output
- `system_snapshot.txt`: environment snapshot
- `machine_noise.txt`: local-noise evidence
- `telemetry.txt`: run-time system telemetry captured during the command
- `telemetry_summary.txt`: distilled machine-level warnings derived from the raw telemetry
- `rerun.sh`: convenience script to re-run the command from the same working directory

Keep separate correctness artifacts when the benchmark alone cannot prove semantic equivalence.
If the implementation has not yet gone through those checks, do not treat the benchmark capture as completion evidence by itself.
Keep per-environment tuning notes when the optimum depends on hardware or firmware differences.
Use [`../scripts/bench_compare.sh`](../scripts/bench_compare.sh) to compare elapsed time and capture context before declaring a win.
For recognized harnesses such as `hyperfine`, it prefers the inner benchmark metric when it can parse it; otherwise it falls back to the outer capture elapsed time and warns accordingly.
If the run is part of a shared multi-agent campaign, also capture the coordination-ledger path, write scope, and compute-slot context so another agent can safely continue the work.
For detached runs, use `run_state.env` and `terminate.sh` inside the capture directory to supervise the run and stop it cleanly if it crosses the hard stop.

For a cleanup audit before benchmarking:

```bash
scripts/safe_cleanup.sh --project-root .
```

For the most conservative cleanup pass:

```bash
scripts/safe_cleanup.sh --project-root . --apply
```

That default apply path only removes old skill artifacts. Broader cleanup scopes such as `project-caches` and `package-manager-caches` stay opt-in.

## Common Benchmark Traps

- Measuring a warmed cache against a cold-cache baseline
- Reporting only warm numbers when resets or invalidations are frequent in real operation
- Comparing different input sizes
- Hiding network or database latency with local mocks
- Ignoring tail latency while celebrating median gains
- Benchmarking a micro-path that is not dominant in production
- Benchmarking a "faster" path that changed semantics, precision, ordering guarantees, or durability behavior
- Trading lower latency for unbounded memory growth or durability loss
- Trusting a single profile captured while unrelated work was competing for CPU, memory, disk, or network

## Sanity Checks Before Trusting A Number

- Re-run the same measurement at least once after confirming the machine is relatively quiet.
- Compare wall-clock and profiler evidence; if they disagree sharply, assume the run is contaminated or the profiler is sampling the wrong phase.
- Check whether CPU, memory, disk, or network usage from unrelated processes spiked during the measurement window.
- If multiple agent sessions or local automation are active, note that explicitly and prefer a quieter rerun before keeping a result.
- If a win only appears at one operating point, verify whether it still holds across the real load or batch range before keeping it.
- If a win appears only in steady warm state, verify that cold-start, rewarm, or invalidation costs do not erase it in the real workload.
- If long or sustained runs degrade unexpectedly, inspect telemetry for swap churn, thermal throttling, power-mode limits, storage saturation, or device-memory cliffs before blaming the algorithm.

## Report Template

Use a simple structure:

```text
Goal:
Environment:
Workload:
Correctness checks:
Telemetry notes:
Baseline:
Cold/warm/rewarm notes:
Load sweep:
Environment-specific tuning notes:
Portable direction vs lucky numbers:
Profiler evidence:
Changes attempted:
Final result:
Risks and tradeoffs:
Next moves:
```
