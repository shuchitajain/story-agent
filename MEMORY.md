# MEMORY.md

> A small set of **current architectural truths**, not a commit log.
> Read this before making structural changes so you don't accidentally reverse a hard-won design choice.
> Each entry describes why the system works the way it does today. Cite a commit only as evidence.

---

## Rules for this file

- **One entry per decision, not per commit.** If a commit refines an earlier decision, update the existing entry — do not add a new one.
- **Delete entries when they are superseded.** Stale entries are more harmful than no entries.
- **Record only decisions with non-obvious reasoning.** If the rationale is self-evident from reading the code, skip it.
- **Keep the total under ~20 entries.** If you need to add one, consider whether an existing entry should be removed or merged first.

What belongs here: agent split choices, installer safety contracts, filterable-vs-always-on workflow steps, output folder contracts, constraints on MCP config mutation.
What does not: commit messages, README changes, image swaps, example updates, wording fixes.

---

## 2026-06-03 — Taskized plans + tracker-decoupled story input

**Commit:** `9c2e22f` — `replace phased execution with optional taskized plans`

**Decision (planning):** Plans are either unsplit (small, one-pass review) or taskized (split into bounded tasks with per-task review). Hard cap: no execution unit touches more than 3 files. Phase count was a weak proxy for reviewability; task-sized units give tighter AI scope and safer cross-session resume without a `handoff.md` artifact. `plan-story.md` Phase 5 (step 14) decides the split; `execution-state.json` carries `is_taskized` and task-level state; `story-agent.md` resume flow handles `continue story <id> from task <N>`.

**Decision (input):** `explain-story` now accepts a story from three sources: (1) tracker ticket ID (original), (2) local file path, or (3) inline text pasted into the prompt. Step 1 of `explain-story.md` detects input type and routes accordingly; the PM question loop and all downstream output (`explanation.md`, handoff to `plan-story`) are identical regardless of source.

---

## 2026-05-27 — Question classification and late-answer reconciliation are workflow-owned, not filterable lenses

**Commit:** `4b60cad` — `add question classification and late-answer reconciliation to planning workflow`

**Decision:** `question-classification.md` and `late-answer-reconciliation.md` are always-on steps baked into the `plan-story` workflow. They are not part of the `lens=` filter and cannot be skipped.

**Why:** Making them filterable would let users skip critical question handling entirely. A plan generated without question classification is likely to miss blockers. Late-answer reconciliation is only invoked when re-planning, so the cost is near zero when not needed. There was no user benefit to exposing them as options.

**What it replaced:** An earlier design that treated all prompts (including question handling) as peer lenses the user could opt out of.

**Current impact:** `plan-story.md` documents that `lens=` only filters the five analysis lenses; question handling is always phase 4 of the workflow regardless of the filter value.

---

## 2026-05-25 — MCP merge uses a JSONC-aware per-server merge, not wholesale file replacement

**Commit:** `18fe13e` — `fixed mcp config`

**Decision:** The installer parses existing MCP config files with a JSONC-aware Python parser (handles comments and trailing commas), then merges story-agent servers individually under `"servers"`. It never replaces the whole file.

**Why:** An earlier version overwrote or corrupted existing MCP configs in target repos, destroying server entries the user had already configured. Additive per-server merge is the only approach that is safe to re-run without data loss.

**What it replaced:** A simpler file-write approach that did not account for existing server entries or JSONC syntax.

**Current impact:** The `merge_mcp_servers_into_file()` function in `scripts/story-agent-init.sh` and the inline Python JSONC parser embedded in it. Any change to MCP merge logic must preserve the per-server additive contract.

---

## 2026-05-25 — Installer is additive and namespaced under `.ai/story-agent/`

**Commit:** `8b70398` — `Refactor installation to additive namespaced story-agent init`

**Decision:** All story-agent assets are copied under `.ai/story-agent/` in the target repo. The `copy_tree_additive()` function skips files that already exist. Existing instruction files (CLAUDE.md, .cursorrules, etc.) are only appended to, never replaced. Init is safe to re-run.

**Why:** An earlier design risked clobbering existing AI configuration in the target repo. Teams evaluating story-agent needed a zero-risk install that could be undone by deleting one directory. Namespacing under `.ai/story-agent/` also prevents collisions with any other tool.

**What it replaced:** A simpler copy that did not check for existing files and could overwrite user config.

**Current impact:** `copy_tree_additive()`, `ensure_story_agent_block()`, and `ensure_gitignore_block()` in the installer. Every new install behaviour added to the script must follow the same additive-only contract.

---

## 2026-05-24 — Three-agent split: orchestrator + explain-story + plan-story

**Commit:** `41fcb55` — `refactor(agents): split story workflow into orchestrator + workers`

**Decision:** The full workflow is split into three agents: `story-agent` (orchestrator), `explain-story` (tracker fetch only), and `plan-story` (codebase analysis + plan generation). Users can run sub-agents directly for partial workflows.

**Why:** A single monolithic agent mixed tracker I/O with codebase scanning and planning. This created two problems: (1) users who just wanted to fetch a story had to wait through codebase analysis, and (2) users who had already fetched a story had to re-fetch it to re-plan. Splitting into workers lets users run only the phase they need and compose them manually.

**What it replaced:** A single `story-agent.md` that ran the full pipeline end-to-end with no skip points.

**Current impact:** Three agent files under `.ai/story-agent/agents/`. The orchestrator pauses after explain completes and waits for user confirmation before advancing to plan. The `plan-story` agent verifies that `story.md` already exists and fails gracefully if explain has not run.
