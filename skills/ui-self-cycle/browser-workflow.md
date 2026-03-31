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

## 6b. Form Element Consistency Audit

When the project has multiple pages with similar UI (admin panels, dashboards, settings):

- collect all form elements across ALL pages: `<input>`, `<select>`, `<button>`, `<textarea>`, `<input type="checkbox">`
- compare sizing, padding, border, font-size, border-radius across pages
- look for pages where toolbar inputs are styled (via design system classes) vs pages where equivalent inputs are bare/unstyled
- check checkbox/radio sizing consistency — common bug: some use a wrapper class, others are bare and appear oversized or misaligned
- check modal form elements separately — modals often have different styling context than page-level forms
- if inconsistency found, prefer CSS-level fixes (contextual selectors like `.toolbar input`) over adding classes to every HTML element
- after fixing CSS: bump cache version (`?v=N`) in ALL HTML files that reference the stylesheet

## 7. Cache Verification

Before diagnosing any "code change has no effect" symptom:

- compare the served file content (via `curl` or network tab response body) against the source file on disk
- check `Cache-Control` and `ETag` response headers for aggressive caching (`immutable`, long `max-age`)
- verify that static asset URLs include a cache-bust suffix (`?v=N`, content hash) and that the suffix was incremented after the change
- if a reverse proxy (nginx, Caddy) or CDN sits in front of the app, its cache may survive app restarts — check proxy config or purge cache
- if the browser serves stale content despite code changes, fix the caching layer before investigating further

## 8. Platform Context Awareness

When the target environment includes WebViews or embedded browsers:

- `<input capture="environment">` is a hint, not a command — desktop and many WebViews ignore it
- `navigator.mediaDevices.getUserMedia` may require HTTPS and may be blocked entirely in Telegram Mini App, Instagram WebView, or older Android WebView
- test with the actual target platform when possible; if not, note platform assumptions as potential blockers
- feature-detect APIs and gate UI accordingly (hide buttons for unavailable features rather than showing them broken)

## 9. Interpretation Rules

- prioritize console and network failures that map to the failing route
- do not assume every warning is the root cause
- correlate UI symptoms with code paths before editing
- if the browser run is clean but the bug remains, inspect event wiring, CSS, state flow, and focus behavior
- if a network response is 200 OK but the UI renders empty, inspect the response payload shape — it may not match what the JS expects (array vs object, nested vs flat, renamed fields)
- if an action succeeds (200, toast shown) but the effect is missing on another page, trace which backend store the action writes to and which store the listing page reads from — they may be different

## 10. Re-Validation After Fix

Repeat the same route and action sequence:

- same viewport
- same user action
- same expected behavior

Only compare after-fix evidence against before-fix evidence for the same scenario.
