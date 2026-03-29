# Iteration Log Template

Append one section per run.

```markdown
## Run <N> - <ISO-8601 timestamp>

Status: <continue|blocked|done>
Goal: <single-run objective>
Issue ID: <stable issue identifier>

### Prior State

- Acceptance target: <summary>
- Previous retries on this issue: <n>
- Previous blocker state: <none|summary>

### Discovery

- Framework/runtime: <detected stack>
- Package manager: <detected tool>
- Attach or start mode: <attach|start>
- Run command used: `<command>`
- Base URL used: <url>

### Evidence Before

- Expected: <expected behavior>
- Actual: <actual behavior>
- Console: <summary>
- Network: <summary>
- Accessibility: <summary>
- Evidence files:
  - <path>
  - <path>

### Root Cause Hypothesis

- Primary hypothesis: <short statement>
- Confidence: <low|medium|high>
- Rejected hypotheses:
  - <hypothesis>: <why rejected>

### Changes Made

- `<path>`: <what changed>
- `<path>`: <what changed>

### Validation After

- Flow rerun: <yes/no>
- Result: <pass/fail/inconclusive>
- Evidence files:
  - <path>
  - <path>

### Decision

- Next status: <continue|blocked|done>
- Reason: <short reason>
- Next recommended action: <single next step>
```
