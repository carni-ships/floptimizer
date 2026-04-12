# Prompt Evaluation

Use this file when you are changing the skill wording, routing, campaign directive, or another steering prompt that may change how the agent searches and validates.

## Core Idea

Prompt and skill changes are interventions.
They should be evaluated, not adopted on vibe alone.

Treat a wording change like a code change:

- define what better means
- run it on a small representative task set
- compare behavior
- keep it only if the improvement is real

## Good Reasons To Evaluate

- the skill seems to over-trigger or under-trigger
- the agent keeps missing a safety or validation step
- the agent gets trapped in one kind of search direction
- a new wording seems to produce better branch selection or cleaner reports
- a routing change may reduce decision latency

## Small Evaluation Set

Use a compact but representative set of tasks such as:

- one simple local hotspot
- one noisy or machine-constrained case
- one rewrite-heavy branch
- one hardware-sensitive or offload-sensitive case
- one multi-agent or campaign-style case

You do not need a huge benchmark suite.
You need enough variation to catch obvious regressions or overfitting.

## What To Compare

Compare behavior, not just prose style:

- did the skill trigger when it should?
- did the agent choose a better first measurement?
- did it keep correctness and validation gates intact?
- did it obey resource and coordination rules better?
- did it produce more diverse or better-ranked branches?
- did it reduce repeated mistakes or rediscovery?
- did it finish faster because the steering was clearer?

## Good Process

1. Write down the exact wording or routing change.
2. State the expected behavior change.
3. Run a small representative task set with the old and new variants.
4. Compare the outcomes and failure modes.
5. Keep the new variant only if it clearly helps or removes a real pain point.

## Guardrails

- Do not replace a stable prompt because the new one merely sounds nicer.
- Do not overfit the skill to one repo or one recent conversation.
- Prefer small wording changes over sweeping rewrites unless the old routing is clearly broken.
- Keep the old version easy to restore until the new version proves itself.
