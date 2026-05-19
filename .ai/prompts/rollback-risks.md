# Lens: Rollback Risks

> Reusable analysis lens. Decide whether the change is safely reversible, and what to do if it isn't.

## Purpose
Force an explicit rollback verdict before shipping. Identify data-shape changes that block rollback, define the feature-flag plan, and quantify blast radius if the change ships broken.

## Length budget
**≤25 lines.** Verdict is one label. Runbook is 3-5 numbered steps, one line each. No discussion of options not taken.

## When to use
- Every story before merge.
- Mandatory if the change touches persisted state, public APIs, payment / auth / sync logic, or runs at scale (>1 % of traffic).

## Inputs expected
- Assembled story context.
- Output of `state-changes.md` lens (reversibility verdict per store).
- Workspace deployment / flag conventions from `.ai/context/project-overview.md`.

## Output template

```markdown
## Rollback Risks

### Reversibility verdict
- **Safely reversible / Reversible with effort / Irreversible** — one line rationale.

### What blocks pure rollback (if anything)
- Schema changes that drop / rename / retype fields.
- New events / messages already consumed downstream.
- Cache poisoning risk.
- Client-side migrations already executed on user devices.
- External side effects (emails sent, payments captured, third-party state).

### Feature-flag plan
- Flag name: <`feature.<slug>`>
- Default state at deploy: off / canary % / on
- Rollout stages and pass criteria for each.
- Kill-switch behavior: who can flip, how fast, observable signal.

### Blast radius if shipped broken
- Users affected: <count / segment / "all">
- Data integrity risk: <none / recoverable / unrecoverable>
- Revenue / SLA risk: <none / minor / material>
- Detection lag: <time from deploy to first signal>

### Pre-deploy safeguards
- [ ] Behind feature flag
- [ ] Telemetry / alarms in place before flag flips
- [ ] Migration is writer-then-reader (or reader-then-writer) with justification
- [ ] Compat window documented (how long old + new shapes coexist)
- [ ] On-call briefed; runbook entry exists

### Rollback runbook
1. <step>
2. <step>
3. <step>

### Open questions
- <items requiring SRE / architect / product input>
```

## Done criteria
- Reversibility verdict is one of the three labels, not hedged.
- Blast radius is quantified, not "could be bad".
- Rollback runbook has at least 3 concrete steps, or the change is flagged "Irreversible — needs architecture review".
