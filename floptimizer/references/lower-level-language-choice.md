# Lower-Level Language Choice

Use this file when a hotspot may deserve a rewrite into a lower-level language or native core and the question is not just "can we rewrite it?" but "should we, and into what?"

## Core Rule

Do not rewrite across language boundaries by vibes.

Do rewrite when:

- the hotspot is clearly CPU-bound
- the slice is large enough to matter end to end
- the boundary can be kept narrow
- correctness can be checked with a clear oracle
- batching can keep FFI or IPC crossings coarse

If the path is still mostly IO-bound, DB-bound, network-bound, lock-bound, or dominated by poor architecture shape, stay in the current language and fix that first.

## Strong Candidates By Source Ecosystem

### Interpreter-heavy or dynamic runtimes

Strongest candidates:

- Python
- Ruby
- JavaScript or TypeScript on Node.js
- Lua
- R

Most worth moving when the hotspot is:

- parsing, serialization, or validation
- search, indexing, matching, or scanning
- compression, hashing, crypto, or codecs
- vectorizable numeric kernels
- repeated tight loops over large inputs

These ecosystems often benefit from a thin-shell, native-core design when profiling says the interpreter or object model is truly in the way.

### Managed runtimes with decent baseline performance

Usually narrower candidates:

- JVM languages
- .NET languages
- Go

Default stance:

- stay in-language first
- fix allocation churn, data layout, batching, and runtime configuration first
- move only the hottest stable kernel when the runtime still dominates after those fixes

Good native-core candidates here are usually:

- parsers
- codecs
- crypto
- SIMD-friendly kernels
- specialized allocators or data structures

Do not assume the whole service should leave the runtime just because one kernel is hot.

### Already-low-level systems languages

Usually do not "rewrite lower" in the large:

- Rust
- C++
- C

Instead, go lower by:

- changing data layout
- reducing abstraction overhead
- specializing allocation
- improving vectorization or instruction selection
- adding ISA-specific paths
- using GPU or accelerator kernels when justified

The right move is usually a narrower rewrite inside the language, not abandoning the language.

## Good Signals That A Lower-Level Rewrite Is Worth Trying

- profiles show a hot loop dominated by interpreter, runtime, reflection, or generic abstraction overhead
- the hot slice is algorithmically sound but implementation-limited
- the data crossing can be batched into coarse calls
- the semantics are stable enough to encode behind a compact interface
- there is a strong exemplar showing the same pattern succeeding elsewhere
- the rewrite could become a reusable core for multiple call sites

## Signals To Delay Or Avoid It

- the bottleneck is mostly remote IO, storage, network, or lock contention
- the hot path is tiny in end-to-end terms
- the language boundary would be chatty or difficult to batch
- the hotspot is still poorly specified
- there is no practical oracle for differential checking
- a library or dependency swap would likely get most of the gain cheaper

## Choosing The Target Language

### Rust

Default best choice when you want:

- a safe native core
- good embedding into Python, Node.js, Ruby, or other hosts
- strong CLI and systems performance
- safer concurrency
- portable performance work with less memory-risk than C or C++

Good for:

- parsers
- search and indexing
- serialization
- data processing kernels
- service hot paths
- native extensions

### C++

Best when you want:

- maximum access to mature performance-heavy ecosystems
- existing C++ codebase alignment
- aggressive allocator, SIMD, or systems tuning
- direct access to battle-tested HPC, DB, or networking libraries

Good for:

- databases
- networking stacks
- rendering
- game or engine code
- specialized high-performance data structures

### C

Best when you want:

- the smallest and most portable ABI surface
- easy FFI into many hosts
- embedded, kernel-adjacent, or runtime-adjacent code
- very tight control over layout and overhead

Use when simplicity of interface matters more than expressiveness.

### GPU kernels or accelerator languages

Best when the hotspot is:

- massively parallel
- arithmetic-heavy enough to amortize transfer and launch overhead
- bounded enough to isolate behind a narrow interface

This is not just a language rewrite. It is a dataflow and memory-traffic redesign. Consult [`hardware-acceleration.md`](hardware-acceleration.md) first.

## Good Migration Shapes

- thin shell in the original language, native core underneath
- one native extension for one stable hot kernel
- shadow implementation with differential tests before cutover
- benchmark-only native prototype before production integration
- adapter boundary that keeps the old path as fallback

## Bad Framing

- "Python is slow, rewrite the service in Rust."
- "Go garbage collection is visible, rewrite everything in C++."
- "Node is the problem, port the whole stack."

## Better Framing

- "The JSON validation loop is 58% of CPU time and crosses a stable boundary; prototype it as a Rust extension behind the current interface."
- "The request path is still dominated by one parser after allocation and batching fixes; spike a native core and compare differential outputs."
- "The service is fine in its current language, but the codec kernel is worth rewriting lower because the interface is narrow and the ceiling is high."

## Practical Default

If the source language is dynamic and the hotspot is tight, repeated, and CPU-bound, a native-core spike is often worth trying.

If the source language is already reasonably fast, prefer a narrow lower-level kernel rather than a wholesale migration.

If the source language is already low-level, go lower inside the same stack before changing stacks entirely.
