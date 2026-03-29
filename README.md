# ui-self-cycle

Production-grade Claude/Codex skill for autonomous web UI debugging and self-healing iteration loops inside Ralph.

## What This Project Contains

This project packages the `ui-self-cycle` skill as a standalone installable artifact set.

It is intended for repeated autonomous runs where an agent must:

- inspect a web project
- detect how to run or attach to it
- probe the UI with browser automation
- collect evidence from screenshots, DOM, console, and network activity
- fix one highest-value issue at a time
- validate every claimed fix
- persist progress for the next Ralph iteration

## Project Layout

```text
ui-self-cycle/
├── README.md
└── skills/
    └── ui-self-cycle/
        ├── SKILL.md
        ├── system-prompt.md
        ├── runtime-template.md
        ├── task-protocol.md
        ├── browser-workflow.md
        ├── agents/
        │   └── openai.yaml
        ├── checklists/
        │   ├── blocked-state.md
        │   ├── safe-mode.md
        │   └── validation-checklist.md
        ├── templates/
        │   ├── commit-message-pattern.md
        │   ├── handoff-summary.md
        │   └── iteration-log.md
        ├── examples/
        │   ├── project-config.example.yaml
        │   ├── progress.txt.example
        │   └── prd-item.example.json
        └── scripts/
            ├── run-cycle.example.sh
            └── collect-ui-evidence.example.sh
```

## Key Files

- `skills/ui-self-cycle/SKILL.md`
  Main skill definition: purpose, workflow, decision tree, root-cause strategy, validation rules, stop conditions.

- `skills/ui-self-cycle/system-prompt.md`
  Core operating instructions for the worker agent.

- `skills/ui-self-cycle/runtime-template.md`
  Per-run task envelope with placeholders like `GOAL`, `BASE_URL`, `ENTRY_PAGES`, and `SAFE_MODE`.

- `skills/ui-self-cycle/task-protocol.md`
  Explicit run contract: inputs, outputs, progress tracking, failure states, retry policy, completion criteria.

- `skills/ui-self-cycle/browser-workflow.md`
  Structured browser-debugging workflow using Playwright-first evidence collection.

## Installation

### Install into Codex

```bash
mkdir -p ~/.codex/skills
cp -R ./skills/ui-self-cycle ~/.codex/skills/
```

### Install into Claude

```bash
mkdir -p ~/.claude/skills
cp -R ./skills/ui-self-cycle ~/.claude/skills/
```

Restart the client after installation so the skill is reloaded.

## Quick Start

Example invocation pattern:

```text
$ui-self-cycle inspect ./frontend, detect how it runs, gather browser evidence on /login and /dashboard, fix one validated UI bug, and persist progress for Ralph
```

Example project config:

```text
skills/ui-self-cycle/examples/project-config.example.yaml
```

Example durable state:

```text
./.ralph/ui-self-cycle/progress.txt
./.ralph/ui-self-cycle/iteration-log.md
./.ralph/ui-self-cycle/latest-handoff.md
```

## Runtime Assumptions

- target is a web app or website
- environment may be Vite, Next.js, React, Vue, Nuxt, Astro, or plain HTML/CSS/JS
- Playwright is preferred when available
- runs are iterative and may start with clean agent context
- state must be persisted in files, not inferred from prior chat

## Operational Style

The skill is intentionally strict about:

- root-cause-first debugging
- evidence before code changes
- small diffs over sweeping rewrites
- post-fix re-validation
- clear blocked states
- explicit `continue` / `blocked` / `done` outcomes

## Notes

- `scripts/*.example.sh` are examples, not universal wrappers for every project
- the skill is optimized for repeated autonomous operation inside Ralph
- safe mode is enabled by default and forbids destructive shortcuts
