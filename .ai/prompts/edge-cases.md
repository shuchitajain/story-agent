# Lens: Edge Cases

> Reusable analysis lens. Generate edge cases the ACs almost certainly missed.

## Purpose
ACs describe the happy path. This lens enumerates the failure / boundary / adversarial cases that need explicit handling before code is written.

## Length budget
**≤35 lines** (this lens is allowed to be the longest — edges are the point). Only list categories that have real cases for this story. Omit empty categories. One line per edge case, no explanations.

## When to use
- Every story, every time. Edge cases are where bugs ship.
- Especially for user input, network calls, concurrent operations, mobile lifecycle events.

## Inputs expected
- Assembled story context.
- Stack-specific edge categories from `.ai/context/project-overview.md` (e.g. offline-first, conflict resolution).

## Output template

```markdown
## Edge Cases

### Input edges
- Empty / null inputs
- Maximum length / payload size
- Invalid types or formats
- Unicode / emoji / RTL text
- Whitespace-only / leading-trailing whitespace

### State edges
- First-run / cold-start
- User logged out mid-flow
- Permission revoked between screens
- Stale cached data
- Multiple tabs / multiple devices concurrent edits

### Network / IO edges
- Offline at start
- Goes offline mid-operation
- Slow / flaky network (timeout, partial response)
- Server returns 4xx / 5xx / unexpected schema
- Retry storm risk

### Concurrency edges
- Two writers race on the same record
- Optimistic-lock conflict
- Background sync collides with foreground edit

### Mobile-specific edges (if applicable)
- App backgrounded mid-flow
- Low memory / process killed
- Permissions: camera / location / notifications denied
- Deep-link entry mid-flow
- Locale / RTL / dark-mode rendering

### Security / abuse edges
- Replay attacks (if writing to an API)
- Privilege escalation paths
- PII in logs / crash reports
- Untrusted input from clipboard / share intent

### Out of scope (explicitly)
- <cases listed but deliberately not handled, with reason>
```

## Done criteria
- At least one item per category, or "not applicable: <reason>".
- Mobile-specific section is mandatory if `.ai/context/project-overview.md` declares a mobile stack.
- Out-of-scope list is not empty (forces a decision).
