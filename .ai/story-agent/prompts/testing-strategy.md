# Lens: Testing Strategy

> Reusable analysis lens. Decide what tests to write, at what level, and what already exists.

## Purpose
Produce a concrete test plan: unit / integration / contract / E2E split, fixtures needed, manual-only scenarios, and what existing coverage already handles.

## Length budget
**≤30 lines.** List only the test files actually needed. Don't enumerate every test case — group as "happy / failure / boundary" bullets under each file.

## When to use
- Every story. Test planning before code prevents shallow / structure-only tests later.

## Inputs expected
- Assembled story context (especially ACs and edge-cases lens output).
- Discovered test conventions from project context (test folders, frameworks, coverage gates).

## Output template

```markdown
## Testing Strategy

### Coverage already in place
- `<existing test file>` — what it covers, whether it needs updating

### New tests required

#### Unit tests
- `<module>` — assertion targets (real behavior, not just call shape):
  - Happy path: <what>
  - Failure paths: <what>
  - Boundary: <what>

#### Integration tests
- <scope: module pair / layer interaction> — scenarios

#### Contract tests (API / message schema)
- Producer side: <fields / events>
- Consumer side: <fields / events>
- Skip if no public contracts changed

#### End-to-end / UI tests
- <user journey> — automated yes/no, tool, fixtures needed

### Test data / fixtures
- New fixtures required: <name, shape, source>
- Existing fixtures reusable: <list>

### Manual-only scenarios
- <scenario> — why it can't be automated (one line each)

### Performance / load checks
- Required? <yes / no + threshold targets>

### Accessibility checks (if UI)
- WCAG level target
- Screen reader / keyboard nav scenarios

### Quality gates before merge
- [ ] Unit suite green
- [ ] Integration suite green
- [ ] Contract tests green
- [ ] Manual scenarios signed off by <role>
- [ ] Accessibility scan passes (if UI)
```

## Done criteria
- "Coverage already in place" lists real test files in the workspace, not generic placeholders.
- Assertion targets describe behavior, not "calls X with Y" structure.
- Manual-only list is justified (no lazy "too hard to automate").
