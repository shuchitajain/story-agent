# story-agent — Team Onboarding Guide

Turn a story id into a fully assembled context folder, then an implementation plan, in two prompts. No more copy-pasting from Jira into chat.

```
You:  /explain-story PROJ-2356
You:  /plan-story PROJ-2356
You:  (open plan.md and start implementing)
```

That's the whole workflow.

---

## What it does

When you hit `/explain-story <id>`, the agent:

1. Pulls the work item from your tracker (Jira / ADO / Linear / GitHub Issues) — title, description, ACs, comments, attachments — verbatim.
2. Downloads PDFs, screenshots, and design exports to a local folder.
3. Renders Figma frames (if any) via the Figma Dev Mode MCP.
4. (Optional) Fetches diff summaries of linked PRs via the GitHub MCP.
5. Flags SSO-walled links (Confluence, SharePoint, etc.) you'll need to paste manually.
6. Runs **five analysis lenses** against everything it gathered:
   - **Architecture impact** — layers / contracts / cross-team ripples.
   - **State changes** — schema, migrations, feature flags, caches.
   - **Edge cases** — failure / boundary / concurrency / mobile-lifecycle cases the ACs missed.
   - **Testing strategy** — what to add, what's covered, manual-only scenarios.
   - **Rollback risks** — reversibility verdict, blast radius, runbook.
7. Writes everything to `.ai/outputs/stories/<id>/`.

When you hit `/plan-story <id>`, it reads that folder and produces `plan.md` with atomic, ordered steps naming **real files in your workspace** (not generic placeholders), each with its own verification line.

Implementation is **not** part of this agent. Open `plan.md` and tell your regular Copilot / Claude agent to execute step 1. It picks up the assembled folder as context automatically.

---

## Who this is for

- Engineering teams that use a story tracker with an MCP (Jira / ADO / Linear / GitHub Issues — the default ships with Jira).
- Teams using VS Code + GitHub Copilot, or Claude Code, as their daily AI tool.
- Anyone tired of the manual context-assembly tax before they can start a ticket.

---

## Prerequisites

| Requirement | Why | How to check |
|---|---|---|
| VS Code ≥ 1.95 with MCP support | Hosts the MCP servers | `code --version` |
| GitHub Copilot **or** Claude Code | Runs the agent prompts | Sign-in panel in VS Code |
| Node.js ≥ 18 | Runs Figma / GitHub MCPs via `npx` | `node -v` |
| [uv](https://docs.astral.sh/uv/) | Runs the Jira MCP (`mcp-atlassian`) via `uvx` | `uv --version` (install: `brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh`) |
| Tracker access (Jira / ADO / etc.) | Read work items, ACs, attachments | Log into the tracker in a browser |
| Figma access (optional) | Render linked design frames | Log into Figma |
| GitHub access (optional) | Fetch linked PR summaries | GitHub login |

---

## Quick start (≈15 min)

### 1. Copy the bundle into your project

```bash
# From your project root (the workspace you open in VS Code):
git clone <repo-url> /tmp/story-agent
cp -r /tmp/story-agent/.ai      .
cp -r /tmp/story-agent/.github  .   # merges if you already have one
cp    /tmp/story-agent/.vscode/mcp.json .vscode/mcp.json
```

Add `.ai/outputs/stories/` to your project's `.gitignore` (or copy the bundle's `.gitignore` if you don't have one). Outputs may contain client data — do not commit.

### 2. Get your tokens (5 min)

**Jira (default tracker):**
1. Open https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token", name it `story-agent-readonly`, copy the value.
3. Note your Atlassian email and your site URL (e.g. `https://yourcompany.atlassian.net`).

**Figma (optional, for design frames):**
1. Open https://www.figma.com/settings → "Personal access tokens".
2. Generate a token with scope `file_content:read`. Copy the value.

**GitHub (optional, for linked-PR enrichment):**
1. Open https://github.com/settings/personal-access-tokens.
2. Generate a **fine-grained** PAT scoped to the relevant repo(s) with:
   - `Pull requests: Read`
   - `Contents: Read`
3. Copy the value.

### 3. Set environment variables

Add to your shell profile (`~/.zshrc` / `~/.bashrc`) **or** a project-local `.env` your shell sources before launching VS Code:

```bash
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_USERNAME="you@yourcompany.com"
export JIRA_API_TOKEN="..."

export FIGMA_TOKEN="..."           # optional
export GITHUB_TOKEN="..."          # optional, for PR enrichment
```

Reload: `source ~/.zshrc` (or new terminal). **Then launch VS Code from that terminal** so it inherits the vars.

### 4. Tell the agent about your project

Open [.ai/context/project-overview.md](.ai/context/project-overview.md) and fill it in. **At minimum**, complete the **Tooling** section at the top:

- Tracker name (`Jira`)
- Story id format (e.g. `PROJ-123`)
- Field mapping (Jira's acceptance-criteria field on your project — look in the Jira field config, often a custom field like `customfield_10042`)
- Design tool domain (`figma.com` or blank)
- VCS for PR enrichment (`github.com/<org>/<repo>` or blank)
- SSO-walled domains (your Confluence, internal wikis)

The Stack / Architecture / Tests / Rollback sections matter for the analysis quality but you can fill them progressively — the agent will still work if they're partial.

### 5. Restart VS Code

Quit VS Code completely and relaunch from the terminal where the env vars are set. Open the MCP panel (Cmd-Shift-P → "MCP: Show Servers") and confirm `jira` (and `figma`, `github` if enabled) show "Running" / green.

### 6. First run — validate against a known story

In Copilot Chat (or Claude Code):

```
/explain-story PROJ-123
```

(Replace with a real, **closed** story id from your tracker — closed so you can sanity-check against reality.)

Check `.ai/outputs/stories/PROJ-123/`:
- `story.md` — title, description, ACs match Jira verbatim.
- `attachments/` — any PDFs / images downloaded.
- `analysis.md` — five sections, no empty subsections.
- `design/` — Figma frames if any were linked.
- `manual-todo.md` — SSO links listed (paste excerpts into this file and re-run `/explain-story` to incorporate them).

Then:

```
/plan-story PROJ-123
```

Open `plan.md`. Every step should name **real files** that exist in your workspace. If you see placeholder names like `<your-file.dart>`, your `project-overview.md` likely needs more detail about your project structure.

---

## Daily usage

### Prompt patterns that work

| Prompt | Effect |
|---|---|
| `/explain-story PROJ-2356` | Full assembly + 5 lenses |
| `/explain-story PROJ-2356 lens=architecture,testing` | Only those 2 lenses (faster, fewer tokens) |
| `explain story PROJ-2356` (Claude Code) | Same as above, natural language |
| `/plan-story PROJ-2356` | Plan only (re-runs `explain` if needed) |
| `apply rollback-risks lens to this PR diff` | Reuse a lens on something other than a story |

### After `/plan-story`

Open `plan.md`, then in the same chat:

```
Execute step 1 of .ai/outputs/stories/PROJ-2356/plan.md
```

Your regular Copilot / Claude agent takes over from here. Story-agent itself never edits source files.

### Re-running on the same story

- `/explain-story` rewrites `story.md`, `analysis.md`, `explanation.md`. It **preserves** `attachments/`, `design/`, and any text you pasted into `manual-todo.md`.
- `/plan-story` only rewrites `plan.md`.

So if Jira updates after you started, re-run `/explain-story` to refresh.

---

## Human-in-the-loop (HITL) contract

Story-agent is explicitly HITL. It never auto-advances between phases and never silently makes decisions that affect scope or production.

**At the end of every phase, the agent asks what to do next.** Example:

```
You:    /explain-story PROJ-2356

(First run only — agent detects placeholders in project-overview.md)
Agent:  Your project-overview.md has 12 unfilled fields. I'd like to ask 8
        questions (max) to fill them in. This is a one-time project setup;
        future /explain-story runs reuse the answers. (a) interview now,
        (b) skip and run best-effort, or (c) stop so you can edit manually?

You:    a
Agent:  [asks 8 questions, you answer]
Agent:  project-overview.md updated. Continuing with /explain-story PROJ-2356.
        [writes 6 files]

(Every story — pre-plan open-questions gate)
Agent:  Before I plan this, I need answers to 5 open questions:
         1. Feature slug — `inspections` or `notes`?
            Suggested default: inspections.
         2. Draft store — sqflite or Hive?
            Suggested default: Hive (synchronous write).
         3. ...
        Reply with numbered answers, `default`, or `skip`.

You:    1=inspections, 2=Hive, 3=yes, 4=server-wins-confirmed, 5=skip
Agent:  Decisions recorded at decisions.md.
        Want me to (a) generate plan.md now, (b) wait while you review,
        or (c) refine a lens?

You:    a
Agent:  /plan-story PROJ-2356 → [writes plan.md grounded in decisions.md]
        plan.md ready (7 steps, 4 impacted files, 2 risks).
        Want me to hand off step 1 to your implementation agent,
        or review the plan first?

You:    review — step 3 is too big, split it
```

You drive every transition: `explain` → `plan` → `implement`. Two gates ensure decisions are explicit:

- **Bootstrap gate (one-time per project):** auto-fires the first time `project-overview.md` has placeholders. Answers are written back to `project-overview.md` and reused on every future run. Re-run manually with `/bootstrap-project` if you ever want to update.
- **Per-story open-questions gate (every explain → plan):** max 5 plan-blocking questions pulled from the 5 lenses. Answers persisted to `.ai/outputs/stories/<id>/decisions.md` and consumed by `/plan-story`. Different story, different questions.

**The agent also pauses mid-run** if it hits a decision that needs your judgement:

- Missing or vague ACs
- Contradictory requirements (AC vs AC, or AC vs parent epic)
- `project-overview.md` Tooling fields blank or incomplete
- Sensitive areas (auth / payments / PII / data migration)
- Files owned by another team or marked `do-not-edit`
- Rollback-risks lens concludes non-reversible / needs backfill
- Linked PRs with unresolved reviews or merge conflicts
- Any case where it would otherwise need to fabricate a path, field value, or AC

It will ask before continuing rather than guess.

What the agent does **not** ask permission for (declared scope, read-only, idempotent):

- Fetching the work item, comments, attachments via MCP
- Downloading attachments / rendering design frames
- Fetching linked-PR diff summaries
- Writing files under `.ai/outputs/stories/<id>/` (gitignored)

Full checkpoint list: [.ai/agents/story-agent.md → Human-in-the-loop](.ai/agents/story-agent.md).

---

## Customising for your team

### Switch tracker (e.g. to Azure DevOps)

1. In `.vscode/mcp.json`, replace the `jira` block with the `azure-devops` snippet from the bottom of the file (it's already commented in as a reference).
2. Set the corresponding env vars (`ADO_ORG_URL`, `ADO_PROJECT`, `ADO_PAT`).
3. In `.ai/context/project-overview.md` → Tooling, change tracker name, story id format, and field mappings.
4. Restart VS Code.

Same pattern for Linear or GitHub Issues.

### Add or skip an analysis lens

- **Skip a lens on one run:** `/explain-story <id> lens=architecture,state,testing`.
- **Skip a lens always:** delete the file from `.ai/prompts/`. The agent only runs lenses that exist.
- **Add a custom lens** (e.g. `security-review.md`, `cost-impact.md`): copy an existing lens file as a template, edit the purpose / output template, save to `.ai/prompts/`. The agent picks it up automatically.

### Customise project-overview.md

It's the single biggest lever for analysis quality. Fields the lenses use:
- `architecture-impact` reads the **Architectural layers** section to name real packages.
- `state-changes` reads **Persisted stores**.
- `edge-cases` reads **Edge-case profile** (mobile? offline-first?).
- `testing-strategy` reads **Test conventions** (paths, frameworks, coverage gate).
- `rollback-risks` reads **Rollout / rollback conventions** (flag naming, kill-switch process).

Specificity wins. "Riverpod v2 with codegen, no ChangeNotifier" produces better output than "uses state management".

---

## Output reference

What gets written to `.ai/outputs/stories/<id>/`:

| File | When | Contents |
|---|---|---|
| `story.md` | explain | Verbatim title / description / ACs / comments / linked items / (linked PRs if GitHub wired) / attachment index |
| `attachments/` | explain | Original-format PDFs, images, docs downloaded from tracker |
| `design/` | explain (if design MCP wired) | Frame PNGs + JSON metadata from Figma / Sketch |
| `manual-todo.md` | explain (if SSO links found) | Checklist of URLs the agent couldn't fetch; paste excerpts inline and re-run |
| `analysis.md` | explain | 5 lens sections, fully filled (or `none identified`) |
| `explanation.md` | explain | 200-400 word narrative summary; open-questions block at the end |
| `plan.md` | plan | Impacted files, ordered atomic steps with verification, risks, tests, rollback, out-of-scope |

The whole `stories/` folder is gitignored. If you want to share, copy specific files manually.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| MCP panel shows `jira` red / failed | `uv` not installed, or `JIRA_*` env vars missing | Install `uv`, set vars, **launch VS Code from terminal** (not Dock) |
| `/explain-story` says "no MCP found" | VS Code didn't pick up `.vscode/mcp.json` | Reload window (Cmd-Shift-P → "Developer: Reload Window") |
| Analysis sections are generic / placeholder-y | `project-overview.md` is sparse | Fill in architectural layers, stores, test conventions with real paths |
| Figma frames not rendering | Token missing scope, or you're outside the team that owns the file | Regenerate token with `file_content:read`, re-export |
| Plan names files that don't exist | Project structure not described in `project-overview.md` | Add a concrete file-tree snippet under **Stack** |
| Jira ACs come back empty | Wrong custom-field id in Tooling field map | Inspect a known story via Jira REST API to find the correct `customfield_XXXXX` |
| `manual-todo.md` keeps appearing for every SharePoint link | Expected — story-agent never bypasses SSO; paste content manually then re-run `explain` |

---

## Updating

To pull a newer version of story-agent into a workspace that already has it:

```bash
# from your project root
cp -r /tmp/story-agent-new/.ai/agents      .ai/
cp -r /tmp/story-agent-new/.ai/prompts     .ai/
cp    /tmp/story-agent-new/.github/copilot-instructions.md .github/
cp -r /tmp/story-agent-new/.github/prompts .github/
# do NOT overwrite .ai/context/project-overview.md or .ai/outputs/
```

`project-overview.md` is yours; leave it alone on updates.

---

## FAQ

**Q: Will story-agent write code or open PRs?**
No. It stops at `plan.md`. Implementation is the regular Copilot / Claude agent's job, using whatever VCS workflow your team has.

**Q: Where do tokens live? Is anything committed?**
Tokens live in your shell environment only. `.vscode/mcp.json` uses `${env:...}` indirection so the file is safe to commit. `.ai/outputs/stories/` is gitignored.

**Q: We use Confluence / Notion / internal wiki. Will the agent fetch from there?**
No (SSO walls). Those URLs land in `manual-todo.md` with a checkbox. Paste excerpts and re-run `explain`. If/when an MCP for that source becomes available, add it to `mcp.json` and wire it in `project-overview.md`.

**Q: Can two engineers run it on the same story simultaneously?**
Yes, but they'll overwrite each other's outputs. Run in your own workspace clone, or use separate output folders by naming convention.

**Q: How do we measure value?**
Suggested KPIs: time-to-first-commit on a new story (baseline vs after adoption), number of stories where missing ACs / edge cases are caught before coding starts, reviewer comments per PR (should drop).

**Q: Can I share the assembled `.ai/outputs/stories/<id>/` with a teammate?**
Yes, zip and send. Useful for design / arch reviews. Check for client-confidential data first.

---

## Support and contribution

- **Owner:** Shuchita Jain (`@coderSJ`)
- **Issues / requests:** raise in the repo issue tracker.
- **Contribute a lens:** copy an existing `.ai/prompts/*.md`, follow the same Purpose / When-to-use / Output-template / Done-criteria structure, open a PR.
- **Contribute a tracker MCP wiring:** add a reference snippet to the bottom of `.vscode/mcp.json` and a row in this README's tracker table.

---

## Compliance notes (EPAM teams)

- Lightest reusable shape (markdown + MCP, zero custom code).
- Decomposed: 5 analysis lenses, each individually reusable.
- One canonical agent definition + thin host adapters.
- MCP over custom REST.
- Fine-grained PATs, read-only, single-scope.
- All artefacts in version control with a named owner.
- Test against one closed real story before sharing.

Full ruleset: [/docs/epam-ai-champion-playbook.md](../docs/epam-ai-champion-playbook.md).
