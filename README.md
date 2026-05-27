# story-agent — Quick Onboarding

Turn a story ID into a context folder and implementation plan in two prompts.

## TL;DR

```text
/story-agent PROJ-2356        # full workflow: fetch → analyze → plan
/explain-story PROJ-2356      # just fetch story from tracker
/plan-story PROJ-2356         # just analyze + plan (needs explain first)
```

- `/story-agent` runs the full workflow end-to-end
- `/explain-story` fetches story details, attachments, linked PRs/designs
- `/plan-story` discovers codebase context, runs lenses, generates plan
- Outputs: `.ai/outputs/stories/<id>/`

## What It Does

| Agent           | Purpose                                                                                |
|-----------------|----------------------------------------------------------------------------------------|
| `explain-story` | Fetches story from tracker, downloads attachments, pulls linked Figma/PRs              |
| `plan-story`    | Auto-discovers codebase context, runs 5 analysis lenses, generates implementation plan |
| `story-agent`   | Orchestrator — runs both in sequence                                                   |

No config required. MCP handles auth, agent auto-discovers project context from README.md, CLAUDE.md, package.json, etc.

## Prerequisites

Before running any agent command, verify these are in place:

**1. Install `uv` (provides `uvx`, used to run MCP servers):**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Confirm it works:

```bash
which uvx && uvx --version
```

**2. Confirm your tracker MCP server is running and tools are discoverable:**

- Open your editor's MCP panel and check your tracker server (Jira, ADO, Linear, GitHub Issues, etc.) shows green / connected.
- If red: verify your `.env` credentials, confirm `uvx` is on PATH, then reload the MCP server.
- Test that the MCP package runs without errors, e.g.:

```bash
uvx <your-mcp-package> --help
```

> MCP uses `uvx` via an absolute path in `mcp.json`. If `spawn uvx ENOENT` appears, your editor's restricted PATH can't find `uvx` — set the full path (e.g. `/Users/<you>/.local/bin/uvx`) in `mcp.json`.

## Quick Setup

```bash
git clone <repo-url> <local-path>/story-agent
cp -r <local-path>/story-agent/.ai .
cp -r <local-path>/story-agent/.github .
cp <local-path>/story-agent/.vscode/mcp.example.json .vscode/mcp.json
```

- Add your tracker credentials to `.env` (copy from `.env.example`).
- Add `.ai/outputs/stories/` to your `.gitignore`.

That's it. No config files to fill — agent auto-discovers project context.

## Daily Usage

> **Important:** All `/story-agent`, `/explain-story`, and `/plan-story` commands must be run in **agent mode** — not ask mode or chat mode. In GitHub Copilot (VS Code / JetBrains), select **Agent** from the mode dropdown before sending the prompt. In ask/chat mode the workflow will stall because it cannot write output files or call MCP tools.

```text
/story-agent <id>                         # full workflow
/explain-story <id>                       # just fetch
/plan-story <id>                          # just analyze + plan
/plan-story <id> lens=architecture,testing  # specific lenses only
```

Open `.ai/outputs/stories/<id>/plan.md` and hand off to your coding agent.

## Output Files

Inside `.ai/outputs/stories/<id>/`:

- `story.md` — verbatim story details and links.
- `attachments/` — downloaded files from tracker.
- `design/` — rendered design frames (if configured).
- `manual-todo.md` — SSO-blocked links requiring manual paste.
- `analysis.md` — lens-based impact analysis.
- `explanation.md` — concise narrative and open questions.
- `plan.md` — ordered implementation steps, risks, checks, rollback notes.

## Troubleshooting

- **Agent stalls / says file not found:** make sure you are in **agent mode**, not ask/chat mode.
- **MCP server red / `spawn uvx ENOENT`:** `uvx` not on PATH — set the absolute path in `mcp.json` (see Prerequisites above), reload the MCP server.
- **Tracker tools not discovered:** restart the MCP server; confirm `.env` credentials are correct.
- **`invalid tool confirmation request` (JetBrains):** GitHub Copilot plugin bug — update the plugin (`Settings → Plugins → GitHub Copilot → Update`), then restart the MCP server. Also check `Settings → Tools → GitHub Copilot → MCP Servers` for an auto-approve / trusted tools option.
- **Generic output:** add a `CLAUDE.md` or `ARCHITECTURE.md` with project specifics.

## Safety + Scope

- Keep secrets in `.env`/environment variables; do not commit real tokens.
- `.ai/outputs/stories/` should remain gitignored.
- Story-agent is planning-first: it stops at `plan.md` and does not edit source by itself.

## Owner

- Shuchita Jain
