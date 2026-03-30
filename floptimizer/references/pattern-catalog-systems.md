# Pattern Catalog: Systems

Use this file when the bottleneck is in distributed systems, stage structure, ownership locality, or path-dependent enabling work.

## Contents

- 17. Shard Per Core And Keep Ownership Local
- 18. Stage Ingest, Validation, Execution, And Persistence
- 19. Separate Coordination From Heavy Compute
- 20. Do The Enabling Work First

## 17. Shard Per Core And Keep Ownership Local

Pattern:

- Partition work and data so a core or shard owns its hot state.
- Minimize cross-core handoff and shared mutable structures.
- Design scheduling and APIs around locality, not just correctness.

Seen in:

- `Seastar`
- `ScyllaDB`
- `Redpanda`
- `Firedancer`

Best for:

- very high-throughput servers
- storage engines
- brokers
- validators and packet-processing-style pipelines

## 18. Stage Ingest, Validation, Execution, And Persistence

Pattern:

- Split the end-to-end path into explicit stages with clear ownership and backpressure.
- Let each stage optimize for its own resource bottleneck.
- Measure the stage boundaries, not just the total runtime.

Seen in:

- `Agave`
- `Firedancer`
- `Reth`
- `Erigon`
- `FoundationDB`

Best for:

- validators
- event streams
- distributed databases
- systems where networking, execution, and storage all contend at once

## 19. Separate Coordination From Heavy Compute

Pattern:

- Keep the distributed coordination layer small and explicit.
- Push large arithmetic or embarrassingly parallel work into independent workers or kernels.
- Avoid forcing heavyweight compute through the same path that handles scheduling and consensus.

Seen in:

- `DIZK`
- `Ray`
- `Aptos`
- `Sui`

Best for:

- distributed proving
- actor or task systems
- speculative execution engines
- clusters mixing scheduling overhead with heavy compute

## 20. Do The Enabling Work First

Pattern:

- Treat some optimizations as dependency chains instead of isolated tricks.
- Build the prerequisites that make the target optimization worthwhile.
- Evaluate the full path, not just the first enabling step.

Seen in:

- Metal and GPU offload projects
- `Polars`
- `DuckDB`
- `Firedancer`

Best for:

- GPU or accelerator migrations
- multicore scaling work
- cache-sensitive refactors
- pipeline fusion
- zero-copy adoption
