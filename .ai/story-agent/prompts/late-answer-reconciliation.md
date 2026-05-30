# Lens: Late Answer Reconciliation

> Reusable planning lens. Compare newly supplied answers with the current plan, resolve assumptions, and summarize what changed.

## Purpose
Avoid rerunning the full planning workflow when a user returns later with answers. Refresh the existing plan only where the new information materially changes it.

## Length budget
**<=25 lines.** Summarize deltas only. Do not restate the full plan.

## When to use
- User responds after `plan.md` already exists.
- Story details changed after the previous planning pass.
- Assumptions or provisional steps need confirmation.

## Inputs expected
- Current `decisions.md`
- Current `plan.md`
- New user answers or updated story details
- Current assumptions and provisional notes

## Reconciliation rules
- Update in place when the new answer confirms an existing assumption.
- Ask a follow-up question only if the new answer creates a contradiction or leaves a dependency unresolved.
- Record only meaningful deltas: steps reordered, files added or removed, risks upgraded or downgraded, assumptions resolved or replaced.
- Keep previous reasoning out of the output unless it changed.

## Output template

```markdown
## Plan Refresh

### Resolved assumptions
- [ASM-1] <old assumption> -> <resolved answer>

### Plan changes
- Step 2 updated: <one line>
- Impacted files changed: <one line>
- Risk updated: <one line>

### Follow-up questions
- <only if still needed>

### Freshness
- Story updated: <timestamp or "no change seen">
- Answers recorded: <timestamp>
- Plan refreshed: <timestamp>
```

## Done criteria
- No change summary is acceptable when answers confirm the current plan.
- Follow-up questions appear only for real contradictions or unresolved dependencies.
- The refreshed output is shorter than the original plan.