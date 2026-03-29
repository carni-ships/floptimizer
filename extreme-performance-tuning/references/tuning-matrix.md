# Tuning Matrix

Use this file when the best settings depend on hardware size, firmware or driver version, runtime version, memory capacity, bandwidth, or other environment-specific limits.

## Why This Matters

Many optimizations do not have one universal best configuration.

Examples:

- the best GPU batch size changes with VRAM and compute throughput
- the best number of worker threads changes with core count and cache size
- the best queue depth changes with latency target and device bandwidth
- the best tile size changes with cache, registers, or shared-memory limits

If you only record one winning number from one machine, future tuning work starts over from scratch.

Also remember: some findings are real conceptual direction, while others are just local fine-tuning.

- Conceptual direction: "larger batches help until memory pressure dominates"
- Fine-tuned number: "batch size 80 was best on this exact card and driver"

Future agents on different hardware should trust the conceptual direction first, then re-sweep to find their own local optimum.

## What To Record Per Environment

For each materially different environment, capture:

- hardware profile: CPU, GPU, memory size, storage class, network class, and any relevant thermal or power context
- firmware, driver, runtime, or library version that may affect performance
- parameters swept: batch size, number of batches, tile size, worker count, stream count, queue depth, prefetch distance, cache size, and similar knobs
- best operating region, not just one magic number
- cliff points where latency, memory use, or errors degrade sharply
- final impact on throughput, tails, memory, and stability
- whether the result is mostly a conceptual direction, mostly device-specific fine-tuning, or a mix
- the portable principle the next agent should keep even if the exact numbers move
- portability notes: which settings likely transfer and which are device-specific

## Good Heuristics

- Prefer ranges and thresholds over one exact value.
- Record both the winner and the nearby losing settings.
- Note why the setting moved: memory ceiling, occupancy, bandwidth, thermal throttling, power mode, or scheduler overhead.
- Separate hard constraints from tunable preferences.
- If a ratio or formula travels better than a fixed constant, record that instead.
- Label the result:
  - `conceptual direction` when the lesson is likely to transfer broadly
  - `fine-tuning` when the exact values are highly device-specific
  - `mixed` when the principle transfers but the chosen numbers probably will not

Examples:

- "GPU batch size wins in the 64-96 range on 24 GB cards, but 32-48 on 8 GB cards"
- "Best tile size tracks L2/cache behavior, not core count"
- "Two streams help on device A, but hurt on device B because memory pressure dominates"

## Suggested Template

```text
environment: RTX 4070 / 12 GB / driver 555.xx / CUDA 12.x
parameters_swept: batch_size 16-128, streams 1-4
best_region: batch_size 64-96, streams 2
cliff_points: OOM risk above 112, tails degrade above 96
impact: +38% throughput vs baseline, p99 stable, memory +1.4 GB
why: higher batches improve occupancy until memory pressure starts forcing stalls
direction_type: mixed
portable_principle: increase batches until occupancy improves, then stop before memory pressure pushes up tails
portability_notes: likely transferable to similar 12 GB cards, not to 8 GB cards
```

## Where To Attach It

- add the per-run notes to benchmark captures
- summarize the stable lessons in the final report
- periodically aggregate the notes with [`../scripts/harvest_tuning_matrix.sh`](../scripts/harvest_tuning_matrix.sh)
