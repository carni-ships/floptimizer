# Novel Hypothesis Generation

Use this file when the bottleneck is understood, the known patterns have been checked, and you want additional ideas that may not already exist in the literature or common exemplar repos.

## Goal

Generate plausible new branches from first principles, not random novelty.

The standard is:

- explain the mechanism
- state the prerequisites
- label the idea as speculative
- design the smallest spike that could falsify it quickly

## When To Do This

Use this after:

- profiling identified the bottleneck class
- known repo or literature ideas have been reviewed
- the current hypothesis set feels too narrow
- you still need more upside from the hotspot

Do not start here. Novel synthesis is more useful after the bottleneck physics are already visible.

## Idea Sources

Generate additional branches from:

- bandwidth limits
- latency and queueing behavior
- cache locality and working-set size
- memory ownership and synchronization cost
- branch divergence and control-flow shape
- representation and data-layout choices
- stage boundaries and work placement
- hardware shape such as SIMD width, occupancy, or memory hierarchy

## Good Generators

Ask questions like:

- what representation would make this bottleneck disappear?
- what work can be avoided, deferred, merged, or hoisted?
- what boundary could move earlier, later, or disappear?
- what would this look like if synchronization were extremely expensive?
- what would this look like if copies were forbidden?
- what cheap first pass could discard most work before the expensive pass?
- what would have to become true for a 10x win on the same hardware?
- what idea from a different domain could transfer here?

Useful cross-domain prompts:

- what would a database engine do here?
- what would a compiler or vectorized query engine do here?
- what would a game engine or packet processor do here?
- what would a GPU-kernel or storage-engine designer do here?

## Branch Types

For each new branch, mark the source:

- known pattern
- literature-derived
- exemplar-derived
- first-principles speculative
- cross-domain transfer

Try to produce at least a few branches that are not directly copied from known implementations.

## Required Output Per Idea

For each candidate, write:

- branch name
- source type
- expected mechanism
- prerequisites
- main risk
- smallest spike experiment

## Example

```text
branch: two-stage filter before exact scoring
source_type: first-principles speculative
expected_mechanism: reduce bytes moved and expensive scoring calls by rejecting obvious misses with a tiny sketch
prerequisites: cheap sketch can be computed from already loaded metadata
main_risk: false positives too high to matter, or sketch build cost dominates
smallest_spike: prototype the sketch on recorded inputs and measure rejected fraction plus end-to-end CPU change
```

## Guardrails

- Do not confuse novelty with evidence.
- Keep speculative branches narrow and falsifiable.
- Avoid giant rewrites before a spike proves the direction.
- Prefer mechanism-first ideas over aesthetic rewrites.
- Retire speculative branches quickly if the spike does not support them.
