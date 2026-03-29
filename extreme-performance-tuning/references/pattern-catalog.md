# Pattern Catalog

Use this file after the bottleneck is identified and before you design the optimization. These are recurring ideas distilled from high-performance libraries and systems.

## Contents

- Core patterns
- Data and storage patterns
- Systems patterns

## Core Patterns

- [`pattern-catalog-core.md`](pattern-catalog-core.md): native-core designs, batching, data layout, allocators, vectorization, fusion, and whole-pipeline thinking

## Data And Storage Patterns

- [`pattern-catalog-data.md`](pattern-catalog-data.md): shared-state reduction, metadata-first probing, zero-copy discipline, specialization, auto-tuning, caching, and storage-layout tradeoffs

## Systems Patterns

- [`pattern-catalog-systems.md`](pattern-catalog-systems.md): shard-per-core locality, staged pipelines, separating coordination from heavy compute, and enabling-work-first strategies
