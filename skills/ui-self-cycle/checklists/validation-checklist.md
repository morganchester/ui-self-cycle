# Validation Checklist

Use before closing an issue and before marking a run `done`.

## Issue-Level Validation

- [ ] The failing route or flow was re-run after the code change
- [ ] Before-change evidence exists and is referenced
- [ ] After-change evidence exists and is referenced
- [ ] Expected behavior is now observed
- [ ] Original failure signal is gone or materially reduced
- [ ] No new console error appeared in the touched flow
- [ ] No newly failed network request was introduced in the touched flow
- [ ] Direct UI regressions in the touched surface were checked

## Accessibility and Interaction Checks

- [ ] Keyboard interaction was checked if the issue touched interactive controls
- [ ] Focus visibility and focus restoration were checked if dialogs or navigation changed
- [ ] Labels, accessible names, or error associations were checked if forms changed
- [ ] The interaction still works without relying on hover only

## Responsive Checks

- [ ] Mobile viewport was checked if layout or interaction could vary by viewport
- [ ] Desktop or primary target viewport was checked
- [ ] No new horizontal overflow or clipping is visible in touched areas

## Code and Scope Checks

- [ ] Only issue-relevant files were changed
- [ ] No unrelated refactor was mixed in
- [ ] The fix targets the likely root cause, not just a visual mask
- [ ] Existing project conventions were preserved

## Run-Level Closure Checks

- [ ] `progress.txt` was updated
- [ ] `iteration-log.md` was appended
- [ ] `latest-handoff.md` was updated
- [ ] Retry counters and blocker state were updated correctly
- [ ] Final status is explicitly one of `continue`, `blocked`, or `done`

## Done Criteria

Only mark `done` when:

- [ ] Acceptance criteria are satisfied
- [ ] No higher-priority actionable issue remains for this task
- [ ] Validation evidence supports the final claim

If any item above is unchecked, do not mark `done`.
