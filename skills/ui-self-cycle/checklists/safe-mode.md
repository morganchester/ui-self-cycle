# Safe Mode Policy

Default posture: safe mode enabled.

## Allowed In Safe Mode

- inspect files and repo scripts
- install dependencies only when clearly missing and using the existing lockfile
- start or attach to a local app
- run deterministic validation commands
- add narrow issue-relevant tests when justified
- edit the smallest responsible code path
- write durable state and evidence files

## Not Allowed In Safe Mode

- `git reset --hard`
- forced checkout over user changes
- deleting large subsystems to bypass bugs
- broad dependency upgrades unrelated to the issue
- changing production infrastructure
- mutating databases or external services beyond narrow task scope
- rotating secrets
- mass formatting or sweeping refactors

## Escalation Rule

If the likely fix requires a safe-mode violation:

- stop before making the change
- record why the change is needed
- record the exact file or surface it would affect
- mark the run `blocked`
- request explicit authorization or a narrower alternative
