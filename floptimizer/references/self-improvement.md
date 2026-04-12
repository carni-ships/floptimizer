# Self-Improvement Loop

Use this file when you want the skill to improve over time without letting it mutate itself recklessly.

## Core Idea

The safe version of a self-improving skill is:

- capture real execution feedback
- turn repeated issues into explicit improvement candidates
- review those candidates periodically
- update the skill deliberately with evidence

Do not let one noisy run rewrite the skill. Let real usage produce a backlog that a later agent can review.

## What To Capture

When a run reveals friction, note things such as:

- guidance that was especially helpful
- missing guidance that forced ad hoc reasoning
- trigger misses or over-triggering
- script or tool gaps
- portability issues
- repeated user corrections
- a reusable heuristic the skill should remember
- an exemplar repo or paper the skill should add
- a reusable optimization trick that should be harvested into the trick catalog rather than copied into the skill itself
- a prompt, wording, or routing change that seems to improve how the agent searches or validates

## Good Candidate Types

- instruction gap: the skill did not say something it should have
- prioritization gap: the skill pointed to the wrong next move
- tooling gap: a helper script, template, or harness was missing
- trigger gap: the skill should load more or less often for some request shape
- portability gap: a step was too macOS-specific or too environment-specific
- evidence gap: the skill needed a better benchmark, safety check, or rollout rule

## Feedback Loop

1. During a serious run, fill in the `Skill Feedback` section in the benchmark capture notes or the session starter report.
2. Keep the notes compact and specific.
3. Periodically harvest those notes into a backlog with [`../scripts/harvest_skill_feedback.sh`](../scripts/harvest_skill_feedback.sh).
4. Review the backlog for repeated or high-severity issues.
5. When the candidate change is really a wording or routing change, evaluate it on a small representative task set before adopting it widely. Use [`prompt-evaluation.md`](prompt-evaluation.md).
6. Make the smallest skill change that closes the gap.
7. Revalidate the skill and re-import it where needed.

## Evidence Standard

Prefer changing the skill when one of these is true:

- the same issue appeared in multiple runs
- the issue caused a clear wrong turn or wasted time
- the issue risked incorrect or unsafe work
- the missing guidance is broadly reusable

Be cautious when:

- the issue was just normal judgment under uncertainty
- the environment was unusual and the fix would overfit
- the suggestion is really a one-off project detail, not a skill improvement
- the wording change felt nicer but was not tested on realistic tasks

## Good Feedback Example

```text
guidance_that_helped: branch log made a blocked GPU idea easy to revisit
missing_guidance: skill did not remind the agent to compare dependency versions after the profile landed in a codec library
tool_or_script_gap: no helper to compare capture summaries side by side
trigger_issue: none
candidate_update: add dependency-version check to the stuck-state workflow
```

## Guardrails

- Do not auto-edit the skill from one run without review.
- Prefer small targeted edits over broad rewrites.
- Keep project-specific details out of the core skill unless they generalize.
- Treat prompt and routing changes like code changes: evaluate them, do not just "feel" them.
- Revalidate after every skill update.
