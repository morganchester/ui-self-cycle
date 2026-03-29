# Blocked State Protocol

Enter blocked state only when continued safe progress is not possible.

## Blocker Categories

Use exactly one primary category:

- `environment_unavailable`
- `dependency_or_install_failure`
- `server_start_failure`
- `browser_automation_unavailable`
- `missing_credentials_or_seed_data`
- `ambiguous_product_decision`
- `unsafe_required_change`
- `retry_threshold_exceeded`
- `external_service_dependency`

## Required Blocked Report Fields

- `status: blocked`
- `blocker_category`
- `current_goal`
- `last_action_attempted`
- `observed_failure`
- `evidence_paths`
- `safe_actions_already_taken`
- `why_next_safe_step_is_not_possible`
- `minimum_input_needed_to_unblock`
- `recommended_next_step_for_ralph`

## Blocked State Rules

- Stop editing code once blocked is confirmed
- Do not keep probing the same failed hypothesis past retry policy
- Do not hide uncertainty
- Do not mark `done` or `continue` if the next step requires unavailable input
- Keep the unblock request minimal and specific

## Example Blocked Summary

```text
status: blocked
blocker_category: server_start_failure
current_goal: Fix login form submit path
last_action_attempted: Started app with `pnpm dev`
observed_failure: App exits immediately because required env `API_BASE_URL` is missing
evidence_paths:
  - ./.ralph/ui-self-cycle/evidence/startup-2026-03-28T101500.log
safe_actions_already_taken:
  - detected package manager and scripts
  - tried attach mode and start mode
  - searched repo for documented local env setup
why_next_safe_step_is_not_possible: Runtime validation cannot proceed without valid local env
minimum_input_needed_to_unblock: Provide local `.env` values or a reachable staging URL
recommended_next_step_for_ralph: Request env values or switch to attach mode with a live app URL
```
