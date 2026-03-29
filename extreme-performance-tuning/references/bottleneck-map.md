# Bottleneck Map

Use this file when the slowdown source is not obvious. Start from the symptom, then run the narrowest diagnostic that can confirm or disprove the suspected class.

## Contents

- Symptom To Diagnostic Map
- CPU Hot Path
- Contention
- Memory and GC
- IO and Serialization
- Tail Latency

## Symptom to Diagnostic Map

| Symptom | Likely class | First diagnostics |
|---|---|---|
| One core pegged, low system time | CPU hot path | CPU profiler, flamegraph, instruction-level hotspots |
| High CPU with many runnable threads, low throughput scaling | Locking or contention | Mutex/block profiler, scheduler trace, goroutine/thread dump |
| Latency spikes during allocation bursts or GC pauses | Memory / GC / allocator | Heap profiler, allocation profiler, GC logs, RSS tracking |
| High system time, many syscalls, low compute | IO or syscall overhead | `strace -c`, `dtrace`, `perf`, fs tracing |
| Good local timing but poor remote latency | Network / topology | RTT traces, connection reuse, DNS/TLS timing, packet loss |
| CPU low, DB time high | Query plan / DB | `EXPLAIN ANALYZE`, slow query log, lock table, index usage |
| Large difference between warm and cold runs | Cache / initialization | Startup trace, cache hit rate, dependency loading breakdown |
| Performance collapses only under concurrency | Shared-state bottleneck | Queue depth, lock wait, connection pool saturation |
| Same payload or record appears to be transformed multiple times | Redundant processing | request trace, flamegraph, stage timing, duplicate parse/encode audit |
| Build time grows faster than code size | Toolchain / build graph | Build trace, dependency graph, cache hit stats |
| p99 much worse than p50 | Queueing / tail amplification | End-to-end tracing, per-stage histograms, pool saturation |
| One benchmark point looks great but throughput or latency falls apart as load rises | Saturation / operating-region problem | Concurrency sweep, batch-size sweep, queue depth, pool saturation |
| A hot slice is real but probably too small to hit the target | Ceiling too low | Amdahl-style upper bound, stage timing, likely next bottleneck |
| Throughput decays only after sustained load or on battery power | Thermal / power throttling | thermal telemetry, power-source mode, clock or frequency hints |
| GPU path wins briefly, then stalls or regresses near larger inputs | Device-memory or offload limit | GPU memory telemetry, copy volume, batch sweep, host-device sync trace |
| GPU is in use but wall time ≈ sum of individual kernel times | Serial GPU dispatch | Command buffer encoding trace, dispatch pattern audit, pipeline utilization |
| GPU kernel time varies wildly across threadgroups for same workload | Warp/simdgroup divergence | Occupancy profiler, work distribution histogram, data ordering audit |

## CPU Hot Path

Look for:

- expensive algorithms
- repeated parsing or encoding
- redundant work in loops
- duplicate validation or transformation across adjacent layers
- inputs that arrive in a shape that forces repeated cleanup, branching, or scatter-gather work downstream
- virtual dispatch or abstraction in the hottest path
- missed vectorization or low locality

Best moves:

- change the algorithm
- precompute
- normalize or preprocess input once so the hot path stays simple
- fuse loops
- reduce copies
- improve locality
- use a more specialized primitive

## Contention

Look for:

- coarse locks
- over-shared caches
- connection pool starvation
- global allocators or loggers
- scheduler thrash

Best moves:

- shard state
- shorten critical sections
- batch updates
- separate read/write paths
- use async boundaries carefully

## Memory and GC

Look for:

- short-lived allocation storms
- oversized object graphs
- repeated buffer growth
- boxing or serialization churn
- fragmented heaps

Best moves:

- reuse buffers
- reduce object count
- flatten structures
- tune GC thresholds
- replace pathological allocators

## IO and Serialization

Look for:

- tiny writes
- synchronous fsync patterns
- repeated JSON encode/decode
- the same payload being serialized, copied, or compressed more than once
- payloads that could be canonicalized, compacted, bucketed, or filtered earlier
- compression on the hot path
- chatty RPC layers

Best moves:

- batch
- stream
- preprocess or cache a cheaper wire or storage representation when it avoids repeated downstream work
- cache encoded forms
- reduce logging volume
- move slow durability boundaries off the critical path when safe

## Tail Latency

Look for:

- retries piling onto overload
- head-of-line blocking
- cold partitions
- lock convoying
- slow dependency fan-out
- duplicate fallback work or repeated retries doing the same expensive processing

Best moves:

- shed load
- cap concurrency
- isolate slow lanes
- add hedging only when it does not amplify overload
- shorten or parallelize the fan-out
