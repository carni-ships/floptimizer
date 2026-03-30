# Language Quickstart

Use this file when you want a fast first profiler command and one or two common hotspot greps without loading deeper language-specific material.

## Rust

- CPU profile: `cargo flamegraph`
- Basic benchmark: `cargo bench`
- Hotspot grep ideas:
  - `rg '\.clone\(\)' --type rust`
  - `rg 'collect::<Vec' --type rust`
  - `rg 'Mutex<|RwLock<' --type rust`

## Go

- CPU profile: `go test -bench=. -cpuprofile cpu.out` then `go tool pprof cpu.out`
- Trace: `go test -run=^$ -bench=. -trace trace.out`
- Hotspot grep ideas:
  - `rg 'interface\\{\\}' --type go`
  - `rg 'append\\(' --type go`
  - `rg 'sync\\.Mutex|sync\\.RWMutex' --type go`

## Python

- CPU profile: `py-spy record -o flame.svg -- python script.py`
- Lightweight baseline: `/usr/bin/time -l python script.py`
- Hotspot grep ideas:
  - `rg '\.iterrows\(\)' --type py`
  - `rg 'json\\.(load|loads|dump|dumps)' --type py`
  - `rg 'for .* in range\\(' --type py`

## TypeScript / Node.js

- CPU profile: `clinic flame -- node app.js`
- Built-in profile: `node --cpu-prof app.js`
- Hotspot grep ideas:
  - `rg 'JSON\\.(parse|stringify)' --type ts`
  - `rg 'await .*forEach|forEach\\(' --type ts`
  - `rg 'Buffer\\.from|new Uint8Array' --type ts`

## JVM

- CPU profile: `async-profiler` or JFR
- Benchmark: JMH when you need a microbenchmark
- Hotspot grep ideas:
  - `rg 'stream\\(' --glob '*.java'`
  - `rg 'parallelStream\\(' --glob '*.java'`
  - `rg 'synchronized' --glob '*.java'`

## C and C++

- CPU profile: `perf record --call-graph dwarf ./binary`
- Allocation profile: `heaptrack ./binary`
- Hotspot grep ideas:
  - `rg 'std::vector<.*> .*=' --glob '*.{cc,cpp,h,hpp}'`
  - `rg 'virtual ' --glob '*.{cc,cpp,h,hpp}'`
  - `rg 'new |delete ' --glob '*.{cc,cpp,h,hpp}'`

## Notes

- These are starting points, not a substitute for the deeper workflow.
- After the first pass, return to [`benchmarking.md`](benchmarking.md), [`bottleneck-map.md`](bottleneck-map.md), and [`idea-ranking.md`](idea-ranking.md).
