---
name: plan-story
description: Discovers codebase context, runs analysis lenses, and generates an implementation plan for a story. Requires explain-story to have run first.
tools: [tracker-mcp, filesystem]
---

# plan-story

> Codebase-aware agent. Discovers project context, runs analysis lenses, generates implementation plan. Assumes `/explain-story <id>` has already run.

## Trigger phrases

`plan story 2356`, `plan 2356`, `/plan-story 2356`

## Inputs

- **story id** — required. Must match an existing `.ai/story-agent/outputs/stories/<id>/` folder.
- **lens filter** — optional. Comma-separated subset of `architecture,state,edge,testing,rollback`. Defaults to all five. Question classification and late-answer reconciliation remain workflow-owned and are not filterable.

## Output folder

Adds to existing `.ai/story-agent/outputs/stories/<id>/`:

```
.ai/story-agent/outputs/stories/2356/
├── story.md                (from explain-story)
├── explanation.md          (from explain-story)
├── attachments/            (from explain-story — only if attachments exist)
├── design/                 (from explain-story — only if design links exist)
├── manual-todo.md          (from explain-story)
├── analysis.md             ← NEW
├── decisions.md            ← NEW
├── plan.md                 ← NEW
├── execution-state.json    ← NEW (always)
└── validation.md           ← NEW (always)
```

---

## Workflow

### Phase 1: Context discovery

**Goal:** Understand the codebase before analysis. No user config required.

1. **Look for existing context files** (read all that exist):

   | File                              | What it tells you                |
   |-----------------------------------|----------------------------------|
   | `CLAUDE.md`                       | Project conventions, constraints |
   | `CONTEXT.md`, `MEMORY.md`         | AI-maintained project context    |
   | `ARCHITECTURE.md`, `DESIGN.md`    | System design, layers            |
   | `README.md`                       | Stack, setup, structure          |
   | `CONTRIBUTING.md`                 | Conventions, review process      |
   | `.cursorrules`                    | Cursor IDE rules                 |
   | `.github/copilot-instructions.md` | Copilot conventions              |

2. **Quick structural scan** (always run, fills gaps):
   - **Use `list_dir` on the workspace root first** — this is the only reliable way to discover hidden directories (`.ai/`, `.github/`, etc.). Do not use `file_search` or `grep_search` for top-level discovery; glob patterns skip dot-directories by default.
   - Read `package.json` / `pubspec.yaml` / `pyproject.toml` / `build.gradle` / `pom.xml` → stack, deps
   - List top-level folders (`src/`, `lib/`, `app/`, `features/`, `test/`) → architecture pattern
   - Read key configs (`tsconfig.json`, `analysis_options.yaml`, `.eslintrc`) → conventions

3. **Hold context in memory** for use in all subsequent phases:
   - Stack/framework info → grounds architecture-impact lens
   - Test folder structure → grounds testing-strategy lens
   - Deployment/flag conventions → grounds rollback-risks lens
   - Feature layout → grounds file path suggestions in plan.md

### Phase 2: Load story context

4. **Verify explain outputs exist.** If `story.md` missing, tell user to run `/explain-story <id>` first.

5. **Read all files** in `.ai/story-agent/outputs/stories/<id>/` — story.md, explanation.md, attachments, design metadata.

6. **Load reusable planning policies** before question handling:
   - Read `.ai/story-agent/prompts/question-classification.md`
   - Read `.ai/story-agent/prompts/late-answer-reconciliation.md` when updating an existing plan

### Phase 3: Analysis lenses

7. **Run each lens** (order matters — later lenses reference earlier verdicts):

   1. `architecture-impact.md` — layers touched, cross-cutting concerns, ADR needed?
   2. `state-changes.md` — stores affected, migrations, reversibility verdict
   3. `edge-cases.md` — failure modes, offline, concurrency, PII
   4. `testing-strategy.md` — test types needed, coverage expectations
   5. `rollback-risks.md` — feature flags, kill-switch, data rollback

   For each lens:
   - Read `.ai/story-agent/prompts/<lens>.md`
   - Apply against:
     - `story.md` + attachments (from explain-story)
     - **Discovered project context** (from Phase 1: CLAUDE.md, README.md, package.json, folder structure, etc.)
   - Use discovered stack, conventions, and architecture to ground the analysis
   - Append output to `analysis.md`

8. **Write `analysis.md`** with TL;DR first:

   ```markdown
   # Analysis — <id>

   **TL;DR.** <one-line verdict>. <biggest risk>. <biggest unknown>.

   ---

   ## Architecture impact
   <lens output>

   ---

   ## State changes
   <lens output>

   (etc.)
   ```

   **Length cap: 150 lines total.** Collapse short sections into prose. Omit "none identified" — just skip the subsection.

### Phase 4: Open questions gate

9. **Drain remaining PM questions from `explanation.md`.** Check the "Open questions" section of `explanation.md`. Any entries still present were not answered during `explain-story`. Include them in the question pool as-is — do not re-classify them.

10. **Classify Engineering questions** from lens output using `question-classification.md`.
   - Keep only questions that materially affect implementation, scope, risk, dependencies, testing burden, or rollback complexity.
   - Do not duplicate any question already present in `explanation.md` Open questions.
   - Zero questions is valid.
   - Keep stable IDs only where they help future reconciliation.

11. **Ask all remaining questions** (PM carry-overs + Engineering). Pick the top 5 by planning impact and group by category. Ask user:

   ```
   Before planning, I have <N> relevant questions:

   Blocking
   1. **<question>** — why it matters: <one line>. Default: <suggestion>.

   Scope
   2. **<question>** — why it matters: <one line>. Default: <suggestion>.

   Clarification
   3. **<question>** — why it matters: <one line>. Default: <suggestion>.
   ...

   Reply with numbered answers, or `default` / `skip` to accept all defaults.
   ```

   `skip` and `default` are equivalent — both accept all default assumptions and proceed to planning.

12. **Wait for reply.** For each answered, defaulted, or skipped question:
   - Append to `decisions.md` (create or extend — preserve existing entries from explain-story):

     ```markdown
     # Decisions — <id>

     Recorded <timestamp>.

     ## Q<n>. <question>
     - Category: <blocking | scope | clarification>
     - Audience: <PM | Engineering>
     - From: <lens name or explain-story>
     - Why this matters: <one line>
     - Answer: <user answer> or `default: <assumption text>`
     - Implication: <what this changes>
     ```

   - If the question came from `explanation.md` Open questions, remove it from that section.
   - If all PM carry-overs are now answered, remove the "Open questions" section heading from `explanation.md` entirely.

12. **If `plan.md` already exists and the user is returning with late answers,** apply `.ai/story-agent/prompts/late-answer-reconciliation.md` before regenerating the final plan. Update `decisions.md` and only ask follow-ups when a real contradiction remains.

### Phase 5: Generate plan

13. **Walk workspace** to identify files to modify. Match against architecture-impact output. Mark uncertain paths as "candidate, verify".

14. **Decide: unsplit or taskized?**

   Keep the plan **unsplit** when the change is small enough to execute and review in one pass.
   Use that mode when the work is likely to touch about 3 to 4 files total, follows one tight dependency chain, and does not mix unrelated concerns.

   Split the plan into **tasks** when the overall change is too broad for one safe review.
   Use taskized mode when the implementation would otherwise span too many files, mix unrelated concerns, or leave the coding agent without a clear review boundary.

15. **Write `plan.md`:**

   **Unsplit plan template** (small, reviewable changes):

    ```markdown
    # Plan: <id> — <title>

    ## Summary
    2-3 short sentences.

    ## Status
    - Confidence: <high | medium | low>
    - Assumptions in force: <count>
    - Story last reviewed: <timestamp if known>
   - Taskized: no

    ## Impacted files
    - `path/to/file` — why

    ## Steps (atomic, ordered)
    1. **<step title>**
       - Files: <list>
       - Change: <one paragraph>
       - Verify: <concrete check>

    ## Risks (from analysis.md)
    - <one line each>

    ## Tests to write
    - <from testing-strategy>

    ## Rollback plan
    - <from rollback-risks>

    ## Assumptions taken
    - <only unresolved assumptions still affecting the plan>

    ## What changed since last plan
    - <only when this is a refresh>

    ## Out of scope
    - <excluded items>

   ## Final validation checkpoint
   - <commands and checks required before asking for human review>
    ```

   **Taskized plan template** (broad changes that need review boundaries):

    ```markdown
    # Plan: <id> — <title>

    ## Summary
    2-3 short sentences.

    ## Status
    - Taskized: yes — <N> tasks, current: task-1
    - Assumptions in force: <count>
    - Story last reviewed: <timestamp if known>

    ## Tasks

    ### Task 1 — <task title>
    **ID:** task-1
    **Depends on:** none
    **Goal:** <single concrete outcome>

    **Files:**
    - `path/to/file`
    - `path/to/file`

    **Change:** <one short paragraph>
    **Verify:** <concrete command or behavior check>
    **Handoff expectation:** <what the next task should receive>

    ### Task 2 — <task title>
    **ID:** task-2
    **Depends on:** task-1
    **Goal:** <single concrete outcome>

    **Files:**
    - `path/to/file`

    **Change:** <one short paragraph>
    **Verify:** <concrete command or behavior check>
    **Handoff expectation:** <what the next task should receive>

    ## Human checkpoints
    - Review and approve after each completed task before advancing.
    - Use `validation.md` to record validation results and handoff notes.

    ## Final validation checkpoint
    - <final checks once all tasks are complete>

    ## Risks (from analysis.md)
    - <one line each>

    ## Tests to write
    - <from testing-strategy>

    ## Rollback plan
    - <from rollback-risks>

    ## Assumptions taken
    - <only unresolved assumptions still affecting the plan>

    ## What changed since last plan
    - <only when this is a refresh>

    ## Out of scope
    - <excluded items>
    ```

   Rules (apply to both unsplit and taskized):
   - Keep this implementation-grade, but skim-friendly for a human reviewer.
   - Do not restate the story, ACs, or full lens output.
   - Include only materially relevant impacted files.
   - If the whole change is small enough to review in one pass, keep it unsplit.
   - **Hard cap: no task or unsplit execution step modifies >3 files.** Split before writing.
   - Prefer bullets and short paragraphs over long narrative.
   - Every task must have one concrete verification step and one handoff expectation.
   - Human review happens at the end of the whole plan in unsplit mode, and after each task in taskized mode.

16. **Write `execution-state.json`** to the story output folder immediately after `plan.md`:

   For an **unsplit plan**:
   ```json
   {
     "story_id": "<id>",
     "plan_version": 1,
     "is_taskized": false,
     "status": "ready",
     "blocked_reason": null,
     "awaiting_human_approval": false,
     "repo_anchor": "unknown",
     "last_updated": "<ISO timestamp>"
   }
   ```

   For a **taskized plan**:
   ```json
   {
     "story_id": "<id>",
     "plan_version": 1,
     "is_taskized": true,
     "current_task": "task-1",
     "completed_tasks": [],
     "status": "ready",
     "blocked_reason": null,
     "awaiting_human_approval": false,
     "last_validated_task": null,
     "repo_anchor": "unknown",
     "last_updated": "<ISO timestamp>"
   }
   ```

   `repo_anchor` starts as `"unknown"` — the implementation agent fills in the git commit hash when it begins work.
   `awaiting_human_approval` flips to `true` after a task finishes validation and is waiting for review.

   `execution-state.json` is owned by the **implementation agent**, not the planning agent. The planning agent only writes the initial skeleton.

17. **Write `validation.md`** skeleton to the story output folder:

   For an **unsplit plan**:
   ```markdown
   # Validation — <id>

   Single execution receipt for an unsplit plan.

   ---

   ## Final Execution
   - **Status:** pending
   - **Timestamp:** —
   - **Repo commit:** —
   - **Files touched:** —
   - **Commands run:** —
   - **What changed:** —
   - **Deviations from plan:** —
   - **Warnings:** —
   - **Human approval:** pending
   ```

   For a **taskized plan**:
   ```markdown
   # Validation — <id>

   One section per completed task.
   A task is complete only when validation passed and human approval is recorded.

   ---

   ## Task 1 — <task title>
   - **ID:** task-1
   - **Status:** pending
   - **Timestamp:** —
   - **Repo commit:** —
   - **Files touched:** —
   - **Commands run:** —
   - **What changed:** —
   - **Deviations from plan:** —
   - **Warnings:** —
   - **Human approval:** pending
   - **Handoff to next task:** —
   ```

   Record handoff notes after each completed task so a fresh session can load the next task without relying on prior chat history.
    **Scope:** <what is included; what is explicitly not included>

18. **Print chat summary:**

    ```
    Plan ready. <one sentence: what the plan does in human terms>

    - Taskized: <yes — <N> tasks | no — unsplit>
    - <N> execution units, each ≤3 files
    - <N> impacted files (top: <2-3 paths>)
    - <N> risks (top: <1-2 phrases>)
    - Tests: <unit/widget/integration counts>
    - Rollback: <one-phrase verdict>

    - execution-state.json — tracks current task and approval state
    - validation.md — records validation results and handoff notes
    Next: review plan.md, then hand off the whole plan (or task-1) to your coding agent.
    ```

---

## Length budgets (hard caps)

| File                   | Cap                                                    |
|------------------------|--------------------------------------------------------|
| `analysis.md`          | 150 lines total, TL;DR in first 3 lines                |
| `plan.md` (unsplit)    | 200 lines total                                        |
| `plan.md` (taskized)   | 300 lines total                                        |
| `decisions.md`         | 6 lines per question                                   |
| `execution-state.json` | fixed schema, no free-text fields except blocked_reason|
| `validation.md`        | 15 lines per execution section                         |

## Output style

- Bullets over prose
- One sentence per bullet
- No filler phrases ("It's worth noting", "As mentioned above")
- Tables for compare/contrast
- Right-size lenses — short is fine if nothing surprising
- `plan.md` should read like an execution brief, not a thesis
- Never paste raw tool errors in chat — log to manual-todo.md

## Hard rules

- Never fabricate file paths — mark uncertain as "candidate, verify"
- Never paraphrase ACs
- No step modifies >3 files
- Stop at planning — never auto-edit source files
- If story.md missing, tell user to run `/explain-story` first
- Question classification and reconciliation are workflow-required, even when lens filters are used

## Human-in-the-loop

- Always ask open questions before generating plan
- Always end with "what's next?" prompt
- Never auto-advance explain → plan → implement

