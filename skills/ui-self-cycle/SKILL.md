---
name: ui-self-cycle
description: Production skill for autonomous web UI debugging and self-healing loops inside Ralph. Use for web apps and sites when Claude must inspect a project, discover how to run it, attach or start a local app, probe the UI with browser automation, collect runtime and accessibility evidence, apply the smallest responsible fix, validate each change, persist progress to files, and continue safely across repeated minimally supervised iterations.
---

# UI Self Cycle

## Purpose

`ui-self-cycle` is a production skill for repeated autonomous web UI debugging inside a Ralph loop.

It gives Claude a concrete operating contract for:

- discovering how a frontend project runs
- starting or attaching to the app
- probing the UI with automated browser flows
- collecting browser, DOM, console, network, layout, responsive, and accessibility evidence
- ranking issues by value and confidence
- fixing one issue at a time with small diffs
- validating every claimed fix with new evidence
- persisting state so the next iteration can continue without hidden context
- stopping safely when blocked or done

This skill is designed for repeated runs with clean agent context. Important state must live in files.

## When To Use

Use this skill when all of the following are true:

- the target is a web app or website
- the task is to debug, stabilize, or incrementally improve actual UI behavior
- the agent is expected to run multiple minimally supervised iterations
- browser evidence is useful or required
- the worker must preserve a durable progress trail between runs

Typical triggers:

- broken clicks, dead buttons, or unresponsive controls
- responsive layout regressions
- runtime console failures or hydration errors
- loading states that never resolve
- modal, routing, focus, keyboard, or form validation bugs
- regressions that need evidence-backed fixing and re-validation
- autonomous Ralph loops that need a stable worker protocol

## When Not To Use

Do not use this skill when:

- the task is pure backend or infrastructure work
- there is no UI surface to exercise
- the desired work is broad redesign rather than debugging and stabilization
- browser automation is explicitly out of scope and static analysis alone is enough
- the user wants large-scale refactors unrelated to evidence-backed UI issues
- destructive remediation would be required without explicit approval

## Required Inputs

- `GOAL`: the user-facing objective or bug-fix target
- `PROJECT_ROOT`: absolute or repo-relative project path
- `ACCEPTANCE_CRITERIA`: concrete success conditions
- `SAFE_MODE`: whether destructive changes are forbidden; default `true`

## Optional Inputs

- `BASE_URL`: existing running app URL if provided
- `ENTRY_PAGES`: important routes to visit first
- `KNOWN_BUGS`: prior reports or hypotheses
- `MAX_FIXES_THIS_RUN`: cap on distinct fixes in one run
- `VIEWPORTS`: explicit viewport set if product requires custom sizes
- `AUTH_SETUP`: local credentials, seed data, or login path
- `BLOCKERS`: known environment issues
- `PLAYWRIGHT_COMMAND`: explicit browser automation command if the project already has one

## Durable State Files

Persist state in files under the project if possible. If not, use a separate workspace folder controlled by Ralph.

Recommended files:

- `./.ralph/ui-self-cycle/progress.txt`
- `./.ralph/ui-self-cycle/iteration-log.md`
- `./.ralph/ui-self-cycle/latest-handoff.md`
- `./.ralph/ui-self-cycle/evidence/`
- `./.ralph/ui-self-cycle/config.yaml`

Never rely on conversation memory for critical state.

## Workflow

Follow this loop exactly.

### A. Read task and project state

- load current task inputs
- load prior `progress.txt`, `iteration-log.md`, and latest handoff if present
- identify the current objective, prior hypotheses, retries, and unresolved blockers

### B. Inspect code and runtime setup

- detect package manager from lockfiles
- inspect scripts from `package.json`, `pyproject`, `Makefile`, or existing task runner
- identify framework, build tool, and likely frontend entrypoint
- for server-rendered apps (Go `html/template`, Jinja, Blade, ERB), identify template directories and static asset paths; note that inline `onclick` attributes, template variable injection into JS, and cache-bust query params (`?v=N`) replace SPA patterns like hydration and bundler HMR
- prefer existing repo commands over inventing new ones

### C. Run or attach app

- if `BASE_URL` is provided and alive, attach
- otherwise discover a safe run command
- install dependencies conservatively only if clearly missing
- start one local app instance only
- record actual command, port, PID, and readiness evidence

### D. Probe UI automatically

- visit entry pages and high-risk routes
- collect screenshots, DOM state, console errors, and failed network requests
- exercise key interactions: click, type, submit, navigate, open/close modal, keyboard navigation
- test multiple viewport sizes

### E. Gather evidence

- save raw evidence files
- summarize observable failures
- distinguish direct evidence from inference

### F. Rank issues

- sort by user impact, reproducibility, confidence, and fix scope
- prefer one issue with strong evidence over many weak hypotheses

### G. Pick one highest-value actionable issue

- choose the smallest issue that meaningfully advances the goal
- avoid mixing unrelated fixes in the same step

### H. Implement the smallest responsible fix

- edit the narrowest code path first
- preserve project conventions and surrounding architecture
- avoid speculative rewrites

### I. Validate the fix

- rerun the relevant browser flow
- confirm the specific issue changed from failing to passing
- confirm no obvious regression in the touched path
- never claim success without fresh post-change evidence

### J. Write progress log

- update issue status, evidence references, files changed, validation result, and next step
- increment retry counters when a hypothesis fails

### K. Decide next state

- `continue`: there is another actionable issue with enough evidence
- `blocked`: progress is prevented by environment, ambiguity, missing access, or repeated failed hypotheses
- `done`: acceptance criteria are met and validated

## Decision Tree

1. Is there prior progress state?
   - yes: resume from the last unresolved issue
   - no: initialize progress files and begin discovery
2. Is a working app URL already available?
   - yes: attach and verify it
   - no: detect run command and start app
3. Can browser automation run?
   - yes: collect browser evidence
   - no: degrade to static analysis and report blocked or partial mode
4. Is there strong evidence for an actionable issue?
   - yes: fix one issue
   - no: gather more evidence or stop with blocked state
5. Did validation pass after the change?
   - yes: record fixed state and continue or finish
   - no: revert hypothesis mentally, record failed attempt, pick next hypothesis
6. Has the same issue exceeded retry threshold?
   - yes: enter blocked state
   - no: continue with the next most plausible root cause

## Browser Evidence Model

For each issue, maintain an evidence bundle with:

- `route`: URL or route
- `viewport`: width x height
- `action_sequence`: exact interaction steps
- `screenshot_before`
- `screenshot_after` when applicable
- `dom_snapshot`
- `console_errors`
- `network_failures`
- `accessibility_findings`
- `expected_behavior`
- `actual_behavior`
- `confidence`

Evidence classes:

- `runtime`: JS exceptions, hydration mismatch, rejected promises
- `interaction`: dead clicks, disabled state, broken handlers
- `state`: stale UI, missing updates, endless loading, bad transitions
- `layout`: overflow, clipping, z-index, invisibility, position issues
- `responsive`: breakpoint collapse, horizontal scroll, hidden navigation
- `accessibility`: focus order, trap failures, missing labels, keyboard gaps
- `network`: failed calls, unhandled loading/error states, bad retries
- `data_contract`: 200 OK response but payload shape differs from what UI expects (nested vs flat, array wrapper, renamed fields)
- `cache`: stale static assets served despite code changes — CDN, reverse proxy, or browser ignoring cache invalidation
- `store_wiring`: action completes successfully (200, toast shown) but writes to wrong backend store so the effect is invisible on the target page
- `platform`: API available in standard browsers but missing or restricted in WebView, Telegram Mini App, iOS Safari, or other embedded contexts

Evidence rules:

- store raw evidence before any code change
- keep issue summaries short but link to raw artifacts
- separate observed facts from inferred causes

## Root Cause Heuristics

Apply targeted heuristics before changing code.

## UI Structuring Rule

When the UI has account-level or profile-level actions, prefer moving them into
their own profile surface instead of mixing them into the main operational
screen.

Examples:

- password change belongs on a profile page, account panel, or profile dropdown
- logout belongs in a profile/account menu, not as a dominant primary action in
  the main workspace
- identity, credentials, account settings, and session controls should be
  grouped together

Use this rule especially when the current UI mixes:

- operational controls and system status
- profile/account settings
- authentication lifecycle actions

Reasoning:

- it reduces clutter in the main workflow
- it makes the primary screen more task-focused
- it avoids a common UI regression where account actions are embedded into a
  dashboard first and later have to be split back out into a dedicated profile
  flow

### Broken click handlers

Look for:

- covered or non-interactive element due to CSS
- `pointer-events: none`
- wrong `z-index`
- stale closures or missing callback binding
- button inside disabled form state
- event prevented by parent layer

### Missing state updates

Look for:

- state setter not called
- async branch returns early
- stale dependency array
- optimistic state never reconciled
- derived state memoization mismatch

### Loading spinners never ending

Look for:

- unresolved promise path
- missing error branch
- `finally` not clearing loading flag
- suspended fetch blocked by missing config
- component waiting on route param or auth state that never resolves

### Modal open or close bugs

Look for:

- state mismatch between trigger and modal
- portal mount issues
- backdrop swallowing close interaction
- focus trap teardown failure
- body scroll lock not cleaned up

### Form validation mismatches

Look for:

- schema and UI rules diverging
- client and server payload shape mismatch
- required field missing label or default
- validation messages mapped to wrong field

### Layout overflow

Look for:

- fixed widths, long unbroken text, image sizing
- flex child missing `min-width: 0`
- grid columns too rigid at narrow widths
- absolute layers expanding container

### Z-index overlap

Look for:

- stacking context created by transforms, opacity, or positioned parent
- ad hoc z-index values rather than scale tokens
- portal vs non-portal overlay mismatch

### Invisible elements due to CSS

Look for:

- same foreground and background colors
- opacity zero or hidden class never removed
- off-screen transforms
- parent clipping or height collapse

### Responsive breakpoints breaking layout

Look for:

- unpaired `md`/`lg` overrides
- desktop-only assumptions in fixed nav or grid
- content hidden without alternate mobile affordance

### Hydration and runtime errors

Look for:

- non-deterministic render values
- client-only APIs during server render
- mismatched IDs or locale formatting
- layout effects or DOM access too early

### Routing and navigation issues

Look for:

- broken route params
- link target mismatch
- missing suspense/error boundary
- navigation blocked by guard state or auth assumptions

### API or network failure handling gaps

Look for:

- unhandled non-200 responses
- missing retry or timeout path
- spinner with no empty/error state
- component assuming data shape on failure

### Stale assets from caching layer

Look for:

- reverse proxy (nginx, Caddy) with aggressive `Cache-Control` (`immutable`, long `max-age`)
- CDN edge cache not invalidated after deploy
- browser ignoring `Disable cache` in DevTools when a service worker or `immutable` directive is active
- static file URLs without cache-bust suffix (`?v=N`, content hash) or suffix not incremented after change
- symptoms: code changes have no effect, old JS errors persist, `curl` returns correct content but browser does not

### External service response shape mismatch

Look for:

- external orchestrator (n8n, Zapier, webhook pipeline) returning a different JSON structure than the frontend expects
- array wrapper around a single object (`[{book: {...}}]` vs `{book: {...}}`)
- nested objects where flat fields are expected (`{edition: {isbn}}` vs `{isbn}`)
- field renaming between services (`categoryCode` vs `category_id`)
- response 200 OK with valid JSON but wrong shape — the request succeeds, the UI renders empty or partial

### Store wiring bugs (works but writes to wrong place)

Look for:

- multiple backend stores for similar concepts (favorites vs library, bookmarks vs collections, cart vs wishlist)
- API call returns success and UI shows confirmation, but the written record never appears on the target page
- the target page reads from a different store/collection than the one the action writes to
- verify by tracing: which store does the API endpoint write to, and which store does the listing page query

### Platform API availability in restricted contexts

Look for:

- `<input capture="environment">` is a hint, not a command — ignored on desktop browsers and many WebViews
- `navigator.mediaDevices.getUserMedia` may be blocked in Telegram Mini App, Instagram WebView, or non-HTTPS contexts
- `navigator.share`, `navigator.clipboard`, `Notification` API may be unavailable or silently fail in embedded browsers
- feature detection (`if (navigator.mediaDevices)`) should gate the UI — hide buttons for unavailable features, not show them broken
- iOS Safari specific: `autoplay` restrictions, `position: fixed` inside scroll containers, `100vh` including address bar

### Server-rendered template and vanilla JS issues

Look for:

- Go `html/template`, Jinja2, Blade, ERB, or similar — no virtual DOM, no hydration, no HMR
- inline `onclick` attributes referencing global functions not yet loaded (script order matters)
- template variables injected into JS via `window.VAR = "{{.Value}}"` — missing escaping or `safeJS` producing unexpected output
- cache-bust query params (`?v=N`) on `<script>` and `<link>` tags not incremented after changes
- no client-side router — full page reloads on navigation, state lost between pages unless stored in cookies or server session

### Keyboard and focus issues

Look for:

- non-focusable custom controls
- missing visible focus state
- focus not moved into dialog
- focus not restored after close
- trapped focus escaping modal or being lost entirely

### CSS design system inconsistency across pages

Look for:

- design system defines styled form elements (`.input-sm`, `.btn-xs`, etc.) but some pages use bare `<input>`, `<select>`, `<button>` without classes
- toolbar/filter bars on one page group are styled (e.g. settings pages) while equivalent bars on another group (e.g. moderation pages) use unstyled elements
- fix by adding scoped CSS rules that target elements by context (`.toolbar input[type="text"]`, `.toolbar select:not(.btn)`) rather than requiring class on every element
- checkboxes and radio buttons with inconsistent sizing — some pages use a wrapper class (`.toggle-label`), others are bare; fix with a global `input[type="checkbox"]` reset
- audit ALL pages systematically, not just the reported ones — inconsistency bugs tend to be systemic

### Inline style overrides breaking responsive layout

Look for:

- inline `style="margin-left:8px"` or similar on elements inside flex/grid containers — these override responsive CSS and cause horizontal overflow at narrow viewports
- fix at the CSS level with `!important` at the mobile breakpoint (`.toolbar > * { margin-left: 0 !important }`) rather than editing every HTML template
- add `overflow-x: hidden` on the outermost shell container as a safety net
- symptoms: page scrolls horizontally by a few pixels on mobile, often exactly the margin/padding value

### nginx caching hierarchy and cache-bust failures

Look for:

- `Cache-Control: immutable` prevents ANY revalidation within `max-age` — even `?v=N` query string changes won't help if the HTML page itself is cached with the old `?v=N`
- `expires 7d` directive sets `max-age=604800` implicitly — within this window, `must-revalidate` means "revalidate AFTER max-age expires", not "revalidate on every request"
- `no-cache` (without `expires`) forces the browser to always revalidate with the server but still allows 304 Not Modified — this is the correct directive for admin panels and low-traffic apps where cache-bust `?v=N` should work instantly
- escalation ladder: try `must-revalidate` first → if stale assets persist, check for `expires`/`max-age` overriding it → if still broken, switch to `no-cache` and remove `expires`
- always verify the actual response headers with `curl -I`, not just the config — proxy layers may add their own caching headers

## Fix Strategy

- prefer root-cause-first changes
- fix the smallest responsible scope first
- touch one issue at a time
- preserve conventions, patterns, naming, and framework idioms already present
- create targeted tests only when they improve deterministic validation and fit the repo
- avoid unrelated cleanup while debugging
- if a code path is uncertain, inspect more before editing

Change priorities:

1. configuration or wiring bug
2. event and state bug
3. CSS/layout bug
4. error-handling or empty-state gap
5. targeted test or guardrail if needed

## Validation Protocol

Validation is mandatory after each fix.

Minimum required validation:

- rerun the exact failing UI path
- confirm expected behavior now occurs
- confirm the prior failure signal is gone
- confirm no direct regression in the touched surface
- update progress with before/after evidence references

Prefer deterministic checks:

- existing tests
- targeted added tests only if justified
- Playwright or existing browser automation
- route-specific smoke checks

Never mark `done` from code inspection alone.

## Retry Policy

Use bounded retries per issue.

- maximum hypothesis retries per issue: `3`
- maximum fixes per iteration unless overridden: `2`
- after each failed hypothesis:
  - record the hypothesis
  - record evidence contradicting it
  - lower its priority
- if all plausible hypotheses for the same issue are exhausted, enter blocked state

Do not repeat the same failed hypothesis with trivial wording changes.

## Stop Conditions

Stop with `done` when:

- the task objective is satisfied
- acceptance criteria are met
- validation evidence exists for the final state

Stop with `blocked` when:

- environment cannot start or cannot be reached
- browser automation is unavailable and static analysis is insufficient
- required credentials or fixtures are missing
- ambiguous product decision is required
- same issue exceeded retry threshold
- safe fix would require destructive or broad changes not authorized

Stop with `continue` when:

- validated progress was made
- another actionable issue remains

## Blocked Protocol

When blocked:

- stop changing code
- summarize exactly what was attempted
- cite evidence and failure point
- specify whether the blocker is environmental, product, access, tooling, or ambiguity
- specify the smallest input needed to unblock
- write a clean handoff for Ralph

See `checklists/blocked-state.md`.

## Ralph Compatibility Notes

- assume each run may start with clean conversation context
- persist all key state to files
- emit a stable status line: `continue`, `blocked`, or `done`
- keep issue IDs and retry counts durable
- link every claim to file paths and evidence paths
- keep the handoff short enough for the next iteration to consume immediately
- never depend on hidden agent memory

Recommended per-iteration commit pattern:

- `ralph(ui-self-cycle): fix <issue-id> <short-summary>`

Recommended progress memory format:

- one durable `progress.txt` with machine-readable key-value sections
- one human-readable iteration log with evidence and decisions

## Example Invocation Patterns

- `$ui-self-cycle debug the checkout page where submit does nothing on mobile; project root is ./app; acceptance criteria are successful form submit and no console errors`
- `$ui-self-cycle inspect ./frontend, detect how it runs, attach or start it, probe /login and /dashboard, fix the highest-value reproducible UI bug, and persist progress for Ralph`
- `$ui-self-cycle continue from ./.ralph/ui-self-cycle/progress.txt and latest handoff; do at most one fix this run`
- `$ui-self-cycle run in safe mode against an already running app at http://127.0.0.1:3000 and verify modal keyboard behavior`
