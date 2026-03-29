# Browser Debugging Workflow

Use this workflow when browser automation is available.

## 1. Session Setup

- attach to `BASE_URL` if already running, else start the app
- create a fresh browser context per viewport
- enable collection for:
  - console warnings and errors
  - page errors
  - failed or non-2xx/3xx network responses
  - screenshots
  - DOM snapshots or route facts

## 2. Route Selection

Probe in this order:

1. explicit `ENTRY_PAGES`
2. routes named in `KNOWN_BUGS`
3. obvious high-value flows:
   - home
   - login
   - primary dashboard
   - primary form
   - modal or settings flow if bug reports mention them

## 3. Per-Route Actions

For each route:

- navigate and wait for stable load
- capture initial screenshot
- inspect for console and failed network signals
- locate key controls
- perform the smallest realistic user action sequence
- capture after-action screenshot
- save route facts:
  - URL
  - title
  - overflow state
  - interactive element summary
  - active element and focus behavior when relevant

## 4. Viewport Matrix

Minimum viewport set:

- `375x812`
- `768x1024`
- `1440x900`

If the bug is mobile-only or desktop-only, still compare with at least one contrasting viewport.

## 5. High-Risk Interaction Probes

Run these when relevant:

- click primary CTAs
- open and close modal or drawer
- fill and submit forms
- tab through interactive controls
- trigger empty, loading, and error states when reproducible
- navigate forward and back

## 6. Evidence Output

Save these per run:

- full-page screenshots
- per-route DOM facts
- `console-issues.json`
- `network-issues.json`
- optional trace or video only if the repo already uses them or the issue is hard to diagnose

## 7. Interpretation Rules

- prioritize console and network failures that map to the failing route
- do not assume every warning is the root cause
- correlate UI symptoms with code paths before editing
- if the browser run is clean but the bug remains, inspect event wiring, CSS, state flow, and focus behavior

## 8. Re-Validation After Fix

Repeat the same route and action sequence:

- same viewport
- same user action
- same expected behavior

Only compare after-fix evidence against before-fix evidence for the same scenario.
