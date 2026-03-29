# Task Protocol

This file defines the runtime contract for `ui-self-cycle`.

## Inputs

Required input fields:

- `goal`
- `project_root`
- `acceptance_criteria`
- `safe_mode`

Optional input fields:

- `base_url`
- `entry_pages`
- `known_bugs`
- `constraints`
- `max_fixes_this_run`
- `viewports`
- `auth_setup`
- `state_dir`

## Outputs

Each run must produce:

- a final run status: `continue`, `blocked`, or `done`
- updated `progress.txt`
- appended `iteration-log.md`
- updated handoff summary
- referenced evidence paths when runtime probing happened
- changed file list if code was modified

Preferred machine-readable output fields:

- `status`
- `goal`
- `issue_id`
- `issue_title`
- `files_changed`
- `validation_result`
- `evidence_before`
- `evidence_after`
- `next_action`
- `blocker_category` when blocked

## Progress Tracking

Use `progress.txt` as the single durable machine-friendly state file.

Minimum fields:

- current status
- current goal
- project root
- base URL in use
- current issue id and title
- retries used for current issue
- timestamp of last run
- last validation result
- next action
- open issues
- blocked reason if any

Use `iteration-log.md` for the human-readable narrative trail.

## Failure States

The worker must explicitly distinguish these failure states:

- `environment_unavailable`
- `dependency_or_install_failure`
- `server_start_failure`
- `browser_automation_unavailable`
- `missing_credentials_or_seed_data`
- `ambiguous_product_decision`
- `unsafe_required_change`
- `retry_threshold_exceeded`
- `validation_inconclusive`

Failure state rules:

- record the first direct evidence of failure
- stop repeating the same failed hypothesis
- request only the minimum information needed to continue

## Retry Policy

- maximum failed hypotheses per issue: `3`
- maximum fixes per run: `1` by default, unless overridden
- after each failed hypothesis:
  - write what was tried
  - write why it was rejected
  - increment the issue retry counter
- if the counter reaches threshold with no safe next hypothesis, emit `blocked`

## Completion Criteria

A run can emit `done` only if:

- the stated goal is met
- acceptance criteria are satisfied
- post-change validation evidence exists
- no unresolved higher-priority actionable issue remains for the current task

A run must emit `continue` if:

- a validated fix landed and another actionable issue remains
- discovery is incomplete but progress is still possible without outside input

A run must emit `blocked` if:

- outside input is required
- the environment prevents safe progress
- browser or runtime validation is impossible and static analysis is insufficient
- retry threshold is exhausted on the current issue
