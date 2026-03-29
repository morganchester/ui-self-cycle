# Commit Message Pattern

Use one commit per validated issue fix when commits are allowed.

Pattern:

```text
ralph(ui-self-cycle): fix <issue-id> <short-summary>
```

Examples:

- `ralph(ui-self-cycle): fix modal-close-esc restore focus after close`
- `ralph(ui-self-cycle): fix login-submit wire pending state reset`
- `ralph(ui-self-cycle): fix mobile-nav-overflow clamp header actions`

Rules:

- include the stable issue id
- describe the validated fix, not the symptom only
- do not mention success unless validation actually passed
