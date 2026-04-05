# Coordination Template

Use this as a lightweight shared ledger when multiple agents are working in parallel.

```text
# Agent Coordination Ledger

last_updated:
system_work_mode: heavy-ok | prefer-non-competing | non-competing

## Active Agents

- agent:
  role:
  branch_or_worktree:
  integration_status: in-progress | ready-for-review | merged | parked
  hypothesis_branch:
  status: active | blocked | parked | done
  work_mode: heavy-ok | non-competing
  compute_permission: none | claim-required
  write_scope:
  last_checkpoint_at:
  preserved_branch_or_worktree:
  expected_outputs:
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
  process_label:
  run_mode: foreground | background | detached
  pid_or_session:
  state_path:
  logs:
  resource_gate_checked_at:
  resource_gate_status:
  expected_duration:
  soft_checkpoint:
  hard_stop:
  started_at:
  status: active | released

## Experiment Frontier

- branch:
  owner:
  role:
  status: active | won | lost | blocked | parked
  blocker_or_result:
  revisit_trigger:
```

Suggested use:

- keep `Active Agents` small and current
- make `role` and `expected_outputs` explicit when agents are specialized
- move `integration_status` to `ready-for-review` when a subagent branch is ready for lead-agent review
- keep `Write Claims` narrow
- allow only one active heavy `Compute Slot` holder per shared machine unless you know the workloads will not interfere
- background or detached jobs should still keep the `Compute Slot` claimed until they really finish
- use `Experiment Frontier` as the shared branch log so agents do not rediscover the same direction
