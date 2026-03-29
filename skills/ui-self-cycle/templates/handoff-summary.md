# Handoff Summary Template

Use this exact shape for Ralph-facing handoff after each run.

```text
status: <continue|blocked|done>
goal: <current task goal>
project_root: <path>
run_timestamp: <ISO-8601>
issue_id: <stable issue identifier>
issue_title: <short issue summary>

what_changed:
- <file path>: <change summary>
- <file path>: <change summary>

evidence_before:
- <path or short reference>

evidence_after:
- <path or short reference>

validation:
- <command or browser flow>
- <result>

remaining_issues:
- <issue id>: <summary>

retry_state:
  issue_id: <issue id>
  retries_used: <n>
  retries_remaining: <n>

risks:
- <risk>

next_best_action:
- <single highest-value next step>

unblock_request:
- <only if blocked>
```
