# Paper-Ready Findings

Use this file when a run produced a finding that may deserve publication, a technical report, or a public writeup later.

## Core Idea

Do not wait until the end of a long optimization campaign to reconstruct the story.

When a run produces a novel, replicated, or otherwise paper-worthy result, capture it immediately in a structured way so later agents can stitch the findings into a coherent paper without re-deriving the evidence.

## What Counts As A Good Finding

Examples:

- a new optimization trick or combination that produced a real measured gain
- a strong negative result that disproved a tempting idea
- an enabling step that looked small alone but unlocked a large later win
- a hardware-sensitive crossover point that changed the recommended strategy
- a robust portability lesson that generalized across environments

## What To Record

For each paper-ready finding, capture:

- finding title
- claim
- finding type
- novelty class
- bottleneck class
- intervention
- baseline condition
- improved condition
- primary metric
- effect size
- secondary effects
- mechanism
- operating region
- prerequisites
- caveats
- reproducibility artifacts
- suggested figure or table
- whether it should be harvested into the paper bundle

## Good Writing Style

Prefer:

- causal language
- measured claims
- explicit operating region
- short caveats
- portable lessons separate from lucky parameter values

Avoid:

- marketing language
- unsupported superlatives
- results with no baseline or no metric
- implying generality when the result is hardware- or workload-specific

## Paper Bundle Workflow

1. Fill in the `Paper-Ready Finding` section in `notes.md` or `starter-report.md`.
2. Keep the fields compact but specific.
3. Run [`../scripts/harvest_paper_findings.sh`](../scripts/harvest_paper_findings.sh).
4. Review the generated `catalog/papers/arxiv-findings.md`.
5. Optionally run [`../scripts/generate_paper_skeleton.sh`](../scripts/generate_paper_skeleton.sh) to assemble a research-style draft scaffold.
6. Use those entries as the building blocks for an eventual paper section, appendix, or table.

## Guardrails

- capture negative and mixed findings too when they change the final story
- do not call something novel just because you have not personally seen it before
- if the result is noisy or provisional, say that directly
- keep reproducibility links back to the source run
