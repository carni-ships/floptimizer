# Coordination Template

Use this as a lightweight shared ledger when multiple agents are working in parallel.

```text
# Agent Coordination Ledger

last_updated:

## Active Agents

- agent:
  branch_or_worktree:
  hypothesis_branch:
  status: active | blocked | parked | done
  write_scope:
  notes:

## Write Claims

- owner:
  files_or_modules:
  started_at:
  status: active | released
  release_when:

## Compute Slot

- holder:
  task:
  run_mode: foreground | background | detached
  pid_or_session:
  logs:
  expected_duration:
  soft_checkpoint:
  hard_stop:
  started_at:
  status: active | released

## Experiment Frontier

- branch:
  owner:
  status: active | won | lost | blocked | parked
  blocker_or_result:
  revisit_trigger:
```

Suggested use:

- keep `Active Agents` small and current
- keep `Write Claims` narrow
- allow only one active heavy `Compute Slot` holder per shared machine unless you know the workloads will not interfere
- background or detached jobs should still keep the `Compute Slot` claimed until they really finish
- use `Experiment Frontier` as the shared branch log so agents do not rediscover the same direction
