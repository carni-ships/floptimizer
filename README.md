# Floptimizer

`floptimizer` is a profile-first optimization skill for AI coding agents.

It is designed for aggressive but safe performance work across the whole stack:

- application code and algorithms
- runtimes and dependencies
- databases and storage
- networking and distributed systems
- build and CI performance
- SIMD, GPU, and hardware-aware tuning

The skill is portable first. The main entrypoint is the skill bundle at [`floptimizer/SKILL.md`](floptimizer/SKILL.md), with deeper references and reusable helper scripts under [`floptimizer/references/`](floptimizer/references/) and [`floptimizer/scripts/`](floptimizer/scripts/).

## What It Emphasizes

- measure first, then optimize
- prove behavior is unchanged
- keep experiments reproducible
- checkpoint meaningful results
- preserve non-winning but valuable branches
- coordinate multiple agents without oversubscribing shared compute
- treat performance work as a structured research loop, not a grab bag of tricks

## Quick Start

### Codex

Install the skill bundle into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
ln -s "$(pwd)/floptimizer" ~/.codex/skills/floptimizer
```

Then invoke it with prompts like:

```text
Use $floptimizer to profile this service and cut p99 latency by 30% without changing external behavior.
```

### Claude Code

Project-local install:

```bash
mkdir -p .claude/skills
ln -s "$(pwd)/floptimizer" .claude/skills/floptimizer
```

Then use:

```text
/floptimizer reduce memory usage in this batch job
```

### Claude.ai

Zip the [`floptimizer/`](floptimizer/) folder and upload that bundle as a skill. The skill entrypoint is [`floptimizer/SKILL.md`](floptimizer/SKILL.md).

## Key Helpers

Some of the most useful scripts are:

- [`floptimizer/scripts/perf_session_bootstrap.sh`](floptimizer/scripts/perf_session_bootstrap.sh): one-command kickoff for a performance session
- [`floptimizer/scripts/bench_capture.sh`](floptimizer/scripts/bench_capture.sh): reproducible benchmark capture with notes, telemetry, and metadata
- [`floptimizer/scripts/bench_compare.sh`](floptimizer/scripts/bench_compare.sh): compare captured baseline and candidate runs
- [`floptimizer/scripts/resource_gate.sh`](floptimizer/scripts/resource_gate.sh): check whether the machine is healthy enough for another heavy run
- [`floptimizer/scripts/coordination_bootstrap.sh`](floptimizer/scripts/coordination_bootstrap.sh): create a coordination ledger for multi-agent work
- [`floptimizer/scripts/campaign_bootstrap.sh`](floptimizer/scripts/campaign_bootstrap.sh): create a long-running optimization campaign directive and compact ledger

## Repository Layout

```text
floptimizer/
├── README.md                  # repo-level overview
├── LICENSE                    # repo license
└── floptimizer/
    ├── SKILL.md               # skill entrypoint
    ├── agents/openai.yaml     # UI metadata
    ├── references/            # on-demand guidance
    ├── scripts/               # helper scripts
    ├── catalog/               # trick catalog and paper artifacts
    ├── LICENSE                # skill-bundle license copy
    └── LICENSING.md           # short licensing summary
```

## Trick Catalog

The skill can accumulate reusable optimization knowledge over time. See:

- [`floptimizer/catalog/README.md`](floptimizer/catalog/README.md)

That catalog is split into raw candidates, curated tricks, cases, and paper-ready findings so future agents can reuse real optimization results instead of starting from scratch every time.

## License

This repository is licensed under Business Source License 1.1.

Key current settings:

- `Additional Use Grant`: `None`
- `Change Date`: `2030-03-29`
- `Change License`: `GPL-2.0-or-later`

See:

- [`LICENSE`](LICENSE)
- [`floptimizer/LICENSING.md`](floptimizer/LICENSING.md)

## Notes

- The skill bundle itself intentionally uses [`floptimizer/SKILL.md`](floptimizer/SKILL.md) as the canonical in-bundle entrypoint instead of maintaining a second README inside the skill folder.
- Some helper scripts were developed primarily on macOS first and then generalized. On Linux, CI, containers, or unusual hosts, treat local-machine cleanup and probe helpers as best-effort and inspect them before applying system-level changes.
