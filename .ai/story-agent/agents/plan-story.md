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
- **lens filter** — optional. Comma-separated subset of `architecture,state,edge,testing,rollback`. Defaults to all five.

## Output folder

Adds to existing `.ai/story-agent/outputs/stories/<id>/`:

```
.ai/story-agent/outputs/stories/2356/
├── story.md          (from explain-story)
├── explanation.md    (from explain-story)
├── attachments/      (from explain-story)
├── analysis.md       ← NEW
├── decisions.md      ← NEW
└── plan.md           ← NEW
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

### Phase 3: Analysis lenses

6. **Run each lens** (order matters — later lenses reference earlier verdicts):

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

7. **Write `analysis.md`** with TL;DR first:

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

8. **Collect open questions** from all lenses. Pick top 5 most plan-blocking. Ask user:

   ```
   Before planning, I need answers to <N> questions:

   1. **<question>** — from: <lens>. Default: <suggestion>.
   2. ...

   Reply with numbered answers, `default` to accept all, or `skip` to plan with assumptions flagged.
   ```

9. **Wait for reply.** Write answers to `decisions.md`:

   ```markdown
   # Decisions — <id>

   Recorded <timestamp>.

   ## Q1. <question>
   - From: <lens>
   - Answer: <user answer>
   - Implication: <what this changes>
   ```

### Phase 5: Generate plan

10. **Walk workspace** to identify files to modify. Match against architecture-impact output. Mark uncertain paths as "candidate, verify".

11. **Write `plan.md`:**

    ```markdown
    # Plan: <id> — <title>

    ## Summary
    2-3 sentences.

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

    ## Out of scope
    - <excluded items>
    ```

    **Hard cap: no step modifies >3 files.** Split before writing.

12. **Print chat summary:**

    ```
    Plan ready. <one sentence: what the plan does in human terms>

    plan.md covers:
    - <N> steps, each ≤3 files
    - <N> impacted files (top: <2-3 paths>)
    - <N> risks (top: <1-2 phrases>)
    - Tests: <unit/widget/integration counts>
    - Rollback: <one-phrase verdict>

    Next: review plan.md, then hand off step 1 to your coding agent.
    ```

---

## Length budgets (hard caps)

| File           | Cap                                     |
|----------------|-----------------------------------------|
| `analysis.md`  | 150 lines total, TL;DR in first 3 lines |
| `plan.md`      | 200 lines total                         |
| `decisions.md` | 4 lines per question                    |

## Output style

- Bullets over prose
- One sentence per bullet
- No filler phrases ("It's worth noting", "As mentioned above")
- Tables for compare/contrast
- Right-size lenses — short is fine if nothing surprising
- Never paste raw tool errors in chat — log to manual-todo.md

## Hard rules

- Never fabricate file paths — mark uncertain as "candidate, verify"
- Never paraphrase ACs
- No step modifies >3 files
- Stop at planning — never auto-edit source files
- If story.md missing, tell user to run `/explain-story` first

## Human-in-the-loop

- Always ask open questions before generating plan
- Always end with "what's next?" prompt
- Never auto-advance explain → plan → implement

