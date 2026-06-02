# AGENTS.md

> Entry point for any AI agent (Copilot, Claude, Cursor, Windsurf) working **on this repo**.
> This is the story-agent project itself — a planning tool that teams copy into their own repos.
> The audience here is you (or an agent) improving story-agent, not a downstream user running it.

---

## What this repo ships

story-agent is three things bundled together:

1. **Agent assets** (`.ai/story-agent/`) — the orchestrator, sub-agents, prompts, and instructions that run in the target repo after install.
2. **Installer** (`scripts/story-agent-init.sh`) — copies assets into any target repo without destroying existing config.
3. **Examples + docs** (`examples/`, `README.md`) — sample generated output files showing what a full story run produces.

---

## Repo structure

```
.ai/story-agent/
├── agents/               ← agent definitions (YAML frontmatter + markdown workflow)
│   ├── story-agent.md    ← orchestrator
│   ├── explain-story.md  ← tracker fetcher
│   └── plan-story.md     ← codebase analyser + plan generator
├── instructions/
│   └── agent-instructions.md   ← hard rules loaded by every agent session
├── prompts/              ← analysis lenses + question-handling policies
│   ├── architecture-impact.md
│   ├── state-changes.md
│   ├── edge-cases.md
│   ├── testing-strategy.md
│   ├── rollback-risks.md
│   ├── question-classification.md
│   └── late-answer-reconciliation.md
├── templates/
│   ├── vscode/mcp.json           ← MCP server template used by installer merge logic
│   └── github/prompts/           ← GitHub Copilot prompt templates (copied when Copilot detected or --with-copilot-prompts)
│       ├── story-agent.prompt.md
│       ├── explain-story.prompt.md
│       └── plan-story.prompt.md
└── outputs/              ← gitignored; populated at runtime in the target repo

scripts/
├── story-agent           ← thin dispatcher (delegates to story-agent-init.sh)
└── story-agent-init.sh   ← full installer logic

examples/outputs/PROJ-2356/ ← sample generated outputs (story.md, explanation.md, analysis.md, decisions.md, plan.md, execution-state.json, validation.md, manual-todo.md)
```

---

## If you want to change X, edit Y

| What to change | Where |
|---|---|
| Orchestrator workflow or sub-agent triggers | `.ai/story-agent/agents/story-agent.md` |
| What explain-story fetches or outputs | `.ai/story-agent/agents/explain-story.md` |
| How explain-story asks PM questions and records answers | `.ai/story-agent/agents/explain-story.md` (step 6) |
| How codebase analysis or planning works | `.ai/story-agent/agents/plan-story.md` |
| How plan-story drains remaining PM questions before planning | `.ai/story-agent/agents/plan-story.md` (Phase 4, steps 9–12) |
| How unsplit vs taskized plans are decided and generated | `.ai/story-agent/agents/plan-story.md` (Phase 5) |
| Resume flow (`continue story <id>` / `continue story <id> from task <N>`) | `.ai/story-agent/agents/story-agent.md` |
| Hard rules that apply to every agent session | `.ai/story-agent/instructions/agent-instructions.md` |
| An analysis lens (architecture, state, edge, testing, rollback) | `.ai/story-agent/prompts/<lens>.md` |
| How open questions are classified | `.ai/story-agent/prompts/question-classification.md` |
| How late answers refresh an existing plan | `.ai/story-agent/prompts/late-answer-reconciliation.md` |
| Which MCP servers are merged into target repos | `.ai/story-agent/templates/vscode/mcp.json` |
| GitHub Copilot prompt templates (`.github/prompts/`) | `.ai/story-agent/templates/github/prompts/` |
| Install behaviour (what files are copied, what is patched) | `scripts/story-agent-init.sh` |
| User-facing docs and quick-start | `README.md` |
| Integration examples | `examples/` |

---

## Hard constraints

These are non-negotiable. Do not work around them without recording a decision in `decisions.md`.

**Installer is additive and idempotent.**
- `copy_tree_additive()` skips files that already exist in the target. Never use `cp -f` or any overwrite variant.
- Every init operation must be safe to re-run. If a block or server entry already exists, skip it silently.
- Never auto-create `~/.claude.json`. Mutating a user's global machine config without consent is a trust violation.

**Agent files must stay valid YAML frontmatter + markdown.**
- Every file under `.ai/story-agent/agents/` starts with a `---` YAML block containing `name`, `description`, and `tools`.
- Agents must not execute or modify source code in the target repo. They stop at `plan.md`.

**No fabrication, no paraphrasing ACs.**
- These rules originate in `agent-instructions.md`. If you change the wording there, update the matching summary in this file.

**`list_dir` for workspace discovery, not glob search.**
- Glob patterns silently skip hidden directories (`.ai/`, `.github/`, etc.). Agents must use `list_dir` on the workspace root to discover structure.

---

## Guardrails for working on this repo

**Never run the installer on this repo itself.**
`scripts/story-agent-init.sh` treats its argument as a target consumer repo. Running it here will corrupt the source assets. Test installer changes against a separate scratch directory.

**Installer must stay fully non-interactive.**
No `read`, no prompts, no pauses in `story-agent-init.sh`. It must be safe to run in CI pipelines without a TTY.

**Asset removals are breaking changes.**
Teams may have already installed story-agent. Deleting or renaming a file under `.ai/story-agent/` is a breaking change for every downstream repo. Deprecate by leaving the file in place and noting the replacement; document the removal in `decisions.md`.

**Validate YAML frontmatter after editing any agent file.**
Every file under `.ai/story-agent/agents/` must start with a valid `---` YAML block containing `name`, `description`, and `tools`. Malformed frontmatter silently breaks agent registration in most IDEs.

**Check `MEMORY.md` before reversing an established pattern.**
If the change you're about to make looks like it undoes a previous architectural decision, read the relevant MEMORY entry first. The decision may have been made for reasons not obvious from the current code.

---

## Decision tracking

Whenever a key decision is made during a conversation working on this repo, append an entry to `decisions.md` before the conversation ends.

**What counts as a key decision:**
- Adding, removing, or renaming an agent or lens
- Changing the installer's copy/merge/patch logic
- Changing output file names or the folder contract under `.ai/story-agent/outputs/stories/<id>/`
  - Current contract: `story.md`, `explanation.md`, `attachments/`, `design/`, `manual-todo.md`, `analysis.md`, `decisions.md`, `plan.md`, `execution-state.json`, `validation.md`
  - `decisions.md` is written by both `explain-story` (PM questions) and `plan-story` (Engineering questions); entries must not be overwritten, only appended
  - `explanation.md` Open questions section exists only when PM questions were left unanswered; `plan-story` drains it
  - `execution-state.json` is a planning-agent skeleton, owned and updated by the implementation agent
  - `validation.md` is a planning-agent skeleton, filled by the implementation agent after each execution unit; for taskized plans it also carries handoff notes to the next task
- Adding or removing a hard constraint
- Choosing one architectural approach over another (e.g. "made X a workflow step, not a filterable lens")
- Changing which MCP servers are bundled

**What does not count:**
- Wording fixes, typo corrections, example updates
- README phrasing changes
- Cosmetic reformatting of any file

**Entry format for `decisions.md`:**

```markdown
## YYYY-MM-DD — <one-line summary>

**Decision:** <what was decided>
**Why:** <reasoning; what problem this solves or what alternative was rejected>
**Affected files:** <comma-separated list>
**Status:** active | superseded by <link or date>
```

---

## Maintenance: when to update this file

Update AGENTS.md when:
- An agent is added to or removed from `.ai/story-agent/agents/`
- A lens is added to or removed from `.ai/story-agent/prompts/`
- A hard constraint is added, removed, or materially changed in `agent-instructions.md`
- The output folder contract changes
- The installer gains or loses a major behaviour (new file type patched, new config format supported, etc.)
