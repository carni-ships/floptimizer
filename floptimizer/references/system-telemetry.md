# System Telemetry

Use this file when a benchmark or profile may be distorted by machine-level limits rather than just code-level hotspots. Broad telemetry is especially useful when results flatten unexpectedly, regress only under sustained load, vary by machine, or look inconsistent with the flamegraph.

## Contents

- When To Collect Broad Telemetry
- Signals Worth Capturing
- What The Signals Often Mean
- How To Capture Them
- Guardrails

## When To Collect Broad Telemetry

Collect broad telemetry when:

- the bottleneck class is unclear
- profiler output and wall-clock behavior disagree
- a run slows down only after sustained load
- GPU offload looks promising but does not pay off
- memory usage, swap, or IO pressure may be distorting the result
- the same benchmark behaves differently across machines or firmware versions
- you suspect power mode, thermal throttling, storage saturation, or device-memory cliffs

Do not make it mandatory for every tiny microbenchmark. Use it for serious or ambiguous runs.

## Signals Worth Capturing

- CPU and scheduler: load averages, runnable pressure, user/sys split, wait time
- Memory: RSS, heap, allocation rate, free pages, swap use, swapins, swapouts, GC pauses
- Storage and filesystem: bytes read and written, IOPS, queue depth, utilization, free space
- Thermal and power: temperature when available, thermal pressure, battery vs AC power, power-limit warnings, clock throttling
- GPU or accelerator: utilization, memory used vs total, temperature, clocks, power state
- Network when relevant: RTT, retransmits, drops, handshake cost, bandwidth saturation

The point is not to capture everything forever. The point is to notice when the machine itself is telling you why the run is failing.

## What The Signals Often Mean

- Rising swap use or swapouts: memory pressure is contaminating the run
- Throughput falls after a few seconds while CPU work looks similar: thermal or power throttling may be taking over
- GPU utilization stays low while GPU memory is near full: the offload path may be memory-bound or over-batched
- IO throughput is flat while queue depth or wait climbs: storage is saturated
- Load average rises but useful throughput does not: contention, scheduler pressure, or throttling may be dominating
- Great short-run numbers with worse long-run numbers: warm-state cost, thermal limits, fragmentation, or background work may be hiding underneath

## How To Capture Them

For a one-off snapshot:

```bash
scripts/profile_telemetry.sh --once --target-path .
```

For repeated sampling during a longer run:

```bash
scripts/profile_telemetry.sh --interval 5 --samples 6 --target-path .
```

For preserved benchmark artifacts, prefer the capture wrapper:

```bash
scripts/bench_capture.sh --label baseline -- hyperfine 'cargo run --release -- input.json'
```

That wrapper records `telemetry.txt` alongside the benchmark output so later agents can correlate performance with machine pressure.

For a smaller handoff artifact or a quick comparison warning pass:

```bash
scripts/telemetry_summary.sh .bench-captures/20260329T000000Z_baseline/telemetry.txt
```

## Guardrails

- Keep sampling lightweight and the interval conservative. Telemetry should explain the run, not become the bottleneck.
- Treat platform-specific signals as best-effort. Some temperature or clock metrics require optional tools, vendor utilities, or elevated privileges.
- Correlate telemetry with the benchmark window. A hot machine from an earlier task can mislead the interpretation.
- Prefer conceptual conclusions over machine-specific numbers. "Batches help until GPU memory pressure dominates" is more portable than "batch size 384 is best."
- When a path is blocked by the current machine, record the unblocker clearly: more VRAM, better cooling, AC power, lower background IO, larger RAM, or a different storage class.
- If telemetry shows throttling, swap churn, storage saturation, or heavy unrelated work, do not answer by launching even more compute-heavy jobs. Pause measurement, let the machine recover, and spend that time on lower-load work such as reviewing captures, pruning hypotheses, or literature review.
- Prefer [`resource-gating.md`](resource-gating.md) and [`../scripts/resource_gate.sh`](../scripts/resource_gate.sh) as the admission check before a new heavy run when the machine is shared or already under visible pressure.
