# Lens: Architecture Impact

> Reusable analysis lens. Apply to any change description (story, RFC, PR diff) to surface architectural ripples.

## Purpose
Identify which layers, services, packages, and contracts the change touches, and flag anything that needs an Architecture Decision Record (ADR) or cross-team review.

## Length budget
**≤30 lines.** Bullets, not paragraphs. Omit subsections that don't apply (don't write "Cross-team: none identified" — just leave it out). Each open question goes in **this lens only** if it's an architecture decision; cross-reference from other lenses.

## When to use
- New feature spanning >1 layer (UI / domain / data / integration).
- Anything that changes a public API contract, message schema, or shared library.
- Stories that look "small" but reference shared infrastructure (auth, sync, queue, gateway).

## Inputs expected
- Assembled story context (`story.md`) **or** any change description.
- Workspace overview (`.ai/context/project-overview.md`) so layer naming is accurate.

## Output template

```markdown
## Architecture Impact

### Layers touched
<Comma-list only the layers actually affected, from: UI / domain / data / integration / cross-cutting (auth, logging, telemetry). Omit this subsection if none.>

### Affected components
- `<package or module>` — what changes and why
- ...

### Contracts modified
- API endpoints: <list or "none">
- Message schemas / events: <list or "none">
- Shared types / interfaces: <list or "none">

### Cross-team / cross-service implications
- <consumers that will break, or "none identified">

### ADR needed?
- yes / no — if yes, one-line rationale

### Open questions
- <items requiring human / architect input before implementation>
```

## Done criteria
- Every section present (write "none identified" rather than omit).
- Components named match real paths in `.ai/context/project-overview.md`.
- ADR-needed verdict is binary, not "maybe".
