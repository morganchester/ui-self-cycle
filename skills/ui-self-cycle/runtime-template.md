# Runtime Template

Use this template for each autonomous run.

```text
GOAL:
<single-run objective in user terms>

PROJECT_ROOT:
<absolute or repo-relative path>

BASE_URL:
<optional existing app URL; leave blank if agent must discover/start app>

ENTRY_PAGES:
- <route or full URL>
- <route or full URL>

KNOWN_BUGS:
- <reproducible issue>
- <suspected issue>

ACCEPTANCE_CRITERIA:
- <observable success condition>
- <observable success condition>

CONSTRAINTS:
- <framework or repo constraints>
- <paths that must not change>
- <time or risk limits>

SAFE_MODE:
true

MAX_FIXES_THIS_RUN:
1

VIEWPORTS:
- 375x812
- 768x1024
- 1440x900

AUTH_SETUP:
<credentials path, seed user, or "none">

STATE_DIR:
./.ralph/ui-self-cycle
```

Expected execution posture:

- load previous progress from `STATE_DIR`
- attach or start app
- gather evidence
- fix one issue
- validate
- persist status as `continue`, `blocked`, or `done`
