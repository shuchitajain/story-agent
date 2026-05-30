# Lens: Question Classification

> Reusable policy lens. Decide whether a story gap is worth surfacing, how urgent it is, and what assumption to carry if unanswered.

## Purpose
Turn vague "open questions" into a small, relevant set of planning inputs. This lens exists to stop the agent from inventing questions for the sake of sounding thorough.

## Length budget
**<=25 lines.** Output only questions that materially affect implementation, scope, risk, dependency choice, test burden, rollback complexity, or user-visible behavior.

## When to use
- During `explain-story` to surface story-quality gaps early.
- During `plan-story` before the open questions gate.
- During plan refresh when a new answer may resolve or reopen prior assumptions.

## Trigger patterns — always classify when spotted
These story or AC patterns should automatically produce at least one question, even if the rest of the story looks complete:

- **Partial population coverage** — an AC explicitly names one segment (existing users, active records, paid accounts, etc.) without stating what applies to everything outside that segment. Ask: what is the intended behaviour for the unaddressed group?
- **Vague action verb** — any verb (submit, update, sync, reset, clear, delete, cancel, etc.) applied to an undefined object or scope. Ask: what exactly is affected, and what is explicitly excluded?
- **Action with no stated boundary** — AC describes an action but doesn't define its reach: one record or all, session-only or persisted, local or synced, current user or all users.
- **State change with no recovery path** — any AC that modifies persisted state with no mention of how to undo, retry, or recover from partial failure.
- **Side effects not mentioned in ACs** — the action implies downstream consequences (cascades, navigation, notifications, linked data) that no AC addresses.
- **Missing UX consequence for a significant action** — no mention of confirmation, feedback, error state, or navigation outcome for an action that materially changes data or context.

## Do not surface a question when
- Only ask questions in the business, product, or design domain — intended behaviour, scope, user-facing outcomes, UX intent, or business rules. The PM can answer directly or loop in stakeholders and the design team.
- Do not ask questions that a non-technical person could not usefully answer. Anything that requires inspecting the codebase, an API spec, or existing system behaviour is a technical discovery task — handle it in `plan.md` as a "candidate, verify" note or silent assumption.
- Do not ask when a safe default exists and taking it does not change implementation shape — record it as an assumption instead.
- Do not ask when the uncertainty is already covered by an explicit assumption in the current plan.

**Self-check before surfacing any question:** Would a PM, designer, or business stakeholder be the right person to answer this? If no — do not ask. Take the safe default and note it as an assumption.

## Required fields per item
- `ID` — stable only if the workflow needs to track it across revisions.
- `Category` — `Blocking`, `Scope`, or `Clarification`.
- `Question` — one sentence.
- `Why this matters` — one line.
- `Default assumption` — one line, only if planning can proceed without an answer.
- `Source` — missing AC, ambiguous description, conflicting comment, unavailable design, skipped user answer, or similar.

## Category rules
- `Blocking` — core implementation shape may change without this answer. Example: a vague action verb with no defined scope — what gets affected and what doesn't are often two completely different implementations.
- `Scope` — plan can proceed, but estimate, touched files, or verification burden may change. Example: adding a confirmation dialog is optional in one interpretation and mandatory in another.
- `Clarification` — plan can proceed safely with a stated assumption. Example: button label wording when no copy spec is provided.

## Output template

```markdown
## Relevant Questions

### Blocking
- [BQ-1] <question>
  - Why this matters: <one line>
  - Default assumption: <one line or "none">
  - Source: <one line>

### Scope
- [SQ-1] <question>
  - Why this matters: <one line>
  - Default assumption: <one line>
  - Source: <one line>

### Clarification
- [CQ-1] <question>
  - Why this matters: <one line>
  - Default assumption: <one line>
  - Source: <one line>
```

## Done criteria
- Zero questions is acceptable when the story is already specific enough.
- Every surfaced question must justify itself with `Why this matters`.
- Keep the set small. Prefer 0-5 total questions, not category-filling.