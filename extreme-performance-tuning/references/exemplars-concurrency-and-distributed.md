# Exemplars: Concurrency And Distributed Systems

Use this file when the bottleneck is in concurrency, runtimes, distributed systems, eventing, proving clusters, or high-throughput validator pipelines.

## Contents

- Concurrency, Hashing, and Runtime Structure
- Distributed Systems and Eventing
- Distributed ZK and Proving Systems
- High-Throughput Blockchains and Validator Pipelines

## Concurrency, Hashing, and Runtime Structure

### folly

- Repo: `https://github.com/facebook/folly`
- Consult when: small-buffer optimizations, concurrent containers, fibers, or production-oriented utility design are relevant.
- Learn from it: compact string and vector representations, concurrency primitives, and a large catalog of focused low-level optimizations.
- Watch out for: adopting clever utilities that increase complexity without solving a measured bottleneck.

### ForkUnion

- Repo: `https://github.com/ashvardanian/ForkUnion`
- Consult when: fork-join parallelism, low-latency task scheduling, or shared-state overhead is the limiter.
- Learn from it: scoped parallelism with minimal hot-path overhead, avoiding allocations, avoiding mutexes on the fast path, and false-sharing awareness.
- Watch out for: replacing a scheduler before proving contention or scheduling overhead is central.

### tokio

- Repo: `https://github.com/tokio-rs/tokio`
- Consult when: async runtime structure, scheduler fairness, nonblocking IO, or service concurrency is relevant.
- Learn from it: runtime layering, async-aware instrumentation, and balancing ergonomic APIs with low-level control.
- Watch out for: blaming the runtime when request fan-out, blocking calls, or pool saturation is the real issue.

### rayon

- Repo: `https://github.com/rayon-rs/rayon`
- Consult when: data parallelism, work stealing, or ergonomic fork-join scheduling in Rust is relevant.
- Learn from it: high-level APIs backed by effective work stealing and good multicore scaling for many batch workloads.
- Watch out for: parallelizing work that is too small or too memory-bound to benefit.

### crossbeam

- Repo: `https://github.com/crossbeam-rs/crossbeam`
- Consult when: lock-free queues, scoped threads, epoch-based memory reclamation, or channel behavior matter.
- Learn from it: practical lock-free building blocks and disciplined ownership for highly concurrent Rust systems.
- Watch out for: replacing simple synchronization with lock-free code where contention is low.

### uWebSockets

- Repo: `https://github.com/uNetworking/uWebSockets`
- Consult when: event loops, WebSockets, HTTP throughput, or minimizing per-request overhead is central.
- Learn from it: thin abstractions on hot paths, event-driven design, and careful attention to bytes copied and syscalls performed.
- Watch out for: chasing peak throughput at the expense of correctness, backpressure, or operational simplicity.

## Distributed Systems and Eventing

### Seastar

- Repo: `https://github.com/scylladb/seastar`
- Consult when: shard-per-core architecture, reactor-based IO, futures-heavy design, or keeping ownership local to a core is relevant.
- Learn from it: explicit scheduling, per-core ownership, avoiding cross-core contention, and designing APIs around the cost model of high-throughput servers.
- Watch out for: copying a shard-per-core design into workloads that are not simple or hot enough to justify the complexity.

### ScyllaDB

- Repo: `https://github.com/scylladb/scylladb`
- Consult when: high-throughput storage engines, shard-per-core databases, compaction-heavy workloads, or latency under sustained load is relevant.
- Learn from it: per-core storage architecture, Seastar-based IO, compaction strategy, and how to make predictable latency part of the engine design.
- Watch out for: cargo-culting per-core sharding without measuring whether the real problem is storage, network, or query shape.

### Redpanda

- Repo: `https://github.com/redpanda-data/redpanda`
- Consult when: log-structured event streaming, Kafka-like systems, high-throughput brokers, or backpressure-aware ingestion pipelines are relevant.
- Learn from it: batch-oriented log pipelines, reactor-style networking, storage-path tuning, and throughput-focused broker architecture.
- Watch out for: optimizing the broker path before confirming producers, consumers, or storage are the real limiters.

### NATS Server

- Repo: `https://github.com/nats-io/nats-server`
- Consult when: very fast messaging, low-latency brokers, lightweight protocol design, or operational simplicity under load matters.
- Learn from it: simple protocol choices, minimal critical paths, and how much throughput can come from avoiding unnecessary features on the hot path.
- Watch out for: confusing protocol simplicity with universal fitness; some workloads need durability or semantics NATS is not optimizing for first.

### FoundationDB

- Repo: `https://github.com/apple/foundationdb`
- Consult when: transactional distributed systems, ordered logs, deterministic transaction processing, or strict correctness under load is relevant.
- Learn from it: commit pipelines, separation of roles, deterministic transaction execution, and how to combine high throughput with strong semantics.
- Watch out for: borrowing distributed role separation without understanding the operational complexity it introduces.

### ClickHouse

- Repo: `https://github.com/ClickHouse/ClickHouse`
- Consult when: distributed analytical execution, vectorized queries across nodes, compression-heavy analytics, or merge-tree storage design is relevant.
- Learn from it: pipeline execution, compression-aware storage layout, distributed query planning, and keeping analytical systems fast end-to-end.
- Watch out for: applying analytical-engine assumptions to OLTP or request-path systems.

### TiKV

- Repo: `https://github.com/tikv/tikv`
- Consult when: distributed transactional KV stores, MVCC-heavy backends, Raft-based replication, or storage layers that must stay fast under consensus are relevant.
- Learn from it: integrating consensus with storage, MVCC under load, and how to preserve throughput while keeping distributed correctness.
- Watch out for: adding distributed-transaction machinery when the real bottleneck is local query shape or single-node storage behavior.

### Ray

- Repo: `https://github.com/ray-project/ray`
- Consult when: distributed task graphs, actor-style execution, zero-copy object sharing, or embarrassingly parallel workloads are relevant.
- Learn from it: distributed object-store design, task scheduling, and how to expose high-throughput distributed compute behind a relatively ergonomic API.
- Watch out for: adopting a general-purpose distributed framework where a much smaller pipeline or queue would be faster and simpler.

### CockroachDB

- Repo: `https://github.com/cockroachdb/cockroach`
- Consult when: distributed SQL, leaseholder placement, rebalancing under load, or multi-region transactional systems are relevant.
- Learn from it: consensus-aware SQL execution, lease-based locality, and how distributed databases trade off latency, consistency, and automatic balancing.
- Watch out for: copying distributed SQL architecture into systems that do not need that level of correctness or operational complexity.

## Distributed ZK and Proving Systems

### DIZK

- Repo: `https://github.com/scipr-lab/dizk`
- Consult when: distributed proving, cluster-wide arithmetic pipelines, or breaking large proving workloads into distributed subroutines is relevant.
- Learn from it: pipelined distributed arithmetic, partitioning proving work across a cluster, and how proof-generation kernels can be mapped to distributed compute infrastructure.
- Watch out for: borrowing cluster orchestration patterns from an older academic system without revalidating them against modern hardware, runtimes, and proof systems.

## High-Throughput Blockchains and Validator Pipelines

### Agave

- Repo: `https://github.com/anza-xyz/agave`
- Consult when: validator pipelines, transaction ingestion, parallel execution, or network-plus-execution overlap is relevant.
- Learn from it: staged validator architecture, high-throughput transaction flow, and how a blockchain client can be organized like a low-latency packet-processing system.
- Watch out for: copying a validator pipeline without matching the consensus, state, and execution model that made it viable.

### Firedancer

- Repo: `https://github.com/firedancer-io/firedancer`
- Consult when: ultra-high-throughput validator design, cache-aware networking, lock minimization, or C-level control of a hot distributed pipeline is relevant.
- Learn from it: tight stage boundaries, memory locality, NIC-to-execution thinking, and designing a blockchain validator like a packet-processing engine.
- Watch out for: pulling low-level tricks into a codebase that cannot realistically maintain them.

### Reth

- Repo: `https://github.com/paradigmxyz/reth`
- Consult when: high-performance Ethereum execution, staged synchronization, modular node design, or database-and-execution throughput is relevant.
- Learn from it: staged sync, modular architecture without giving up performance, and careful interaction between execution and storage.
- Watch out for: assuming modularity is free; the interfaces still need to preserve hot-path efficiency.

### Erigon

- Repo: `https://github.com/erigontech/erigon`
- Consult when: archival efficiency, flat data layouts, staged sync, or storage-heavy blockchain execution is relevant.
- Learn from it: data-layout changes, staged pipeline design, and trading traditional node structure for better sync and storage behavior.
- Watch out for: copying storage layouts without understanding their long-term operational and migration costs.

### Sui

- Repo: `https://github.com/MystenLabs/sui`
- Consult when: object-based state models, parallel transaction execution, or throughput via conflict reduction is relevant.
- Learn from it: how state-model choices can unlock parallelism, and how execution architecture changes when transactions are not all forced through one global conflict path.
- Watch out for: assuming the same parallelism is available in account-based or heavily contended workloads.

### Aptos

- Repo: `https://github.com/aptos-labs/aptos-core`
- Consult when: speculative parallel execution, Block-STM style ideas, or high-throughput execution engines are relevant.
- Learn from it: optimistic parallel execution, retry-aware scheduling, and how blockchain execution engines can borrow from database concurrency ideas.
- Watch out for: overestimating speculative execution gains on workloads with heavy write conflicts.
