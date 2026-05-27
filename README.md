# story-agent

AI workflow infrastructure that plugs into your existing coding assistant ecosystem.

story-agent is additive by design. It does not replace your current setup for GitHub Copilot, Claude Code, Cursor, Windsurf, Roo, or other agent systems.

## TL;DR

```text
/story-agent PROJ-2356        # full workflow: fetch -> analyze -> plan
/explain-story PROJ-2356      # just fetch story from tracker
/plan-story PROJ-2356         # just analyze + plan (needs explain first)
```

- `/story-agent` runs the full workflow end-to-end
- `/explain-story` fetches story details, attachments, linked PRs/designs
- `/plan-story` discovers codebase context, runs 5 analysis lenses, generates plan
- Outputs: `.ai/story-agent/outputs/stories/<id>/`

## Installation

Use the local init command (conceptually equivalent to `uvx story-agent init`):

```bash
git clone <repo-url> <local-path>/story-agent
cd <local-path>/story-agent
./scripts/story-agent init /path/to/your/project
```

Optional Copilot adapter install:

```bash
./scripts/story-agent init /path/to/your/project --with-copilot-prompts
```

What init does:

- creates `.ai/story-agent/` in the target repo
- copies story-agent assets without overwriting existing files
- installs slash command prompt wrappers into `.github/prompts/` only when Copilot is already detected, or when `--with-copilot-prompts` is passed
- patches `.gitignore` with story-agent output paths
- detects existing AI instruction systems and appends a small reference block
- creates a minimal `.github/copilot-instructions.md` only when no instruction system exists
- merges story-agent MCP servers into existing MCP config files (`.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`, `~/.claude.json`, etc.) without removing existing servers

Running init multiple times is safe and idempotent.

Prompt behavior across IDEs:

- canonical prompts always live in `.ai/story-agent/prompts/`
- these prompts are used regardless of IDE through the story-agent instructions/agents
- `.github/prompts/` files are optional Copilot slash-command wrappers, not the source of truth

## Existing AI Systems Supported

The installer detects and integrates with these instruction ecosystems:

- `.github/copilot-instructions.md`
- `CLAUDE.md`
- `.cursorrules`
- `.windsurfrules`
- `.clinerules`
- `.roo/*`
- `.cursor/*`

Integration is additive. The installer appends a reference to:

`.ai/story-agent/instructions/agent-instructions.md`

No existing instruction content is replaced.

## MCP Setup (Composable)

story-agent no longer assumes ownership of a single MCP config path.

- if one or more MCP config files already exist (VS Code, Cursor, Claude-style), init merges required story-agent servers (`jira`, `figma`, `github`) only when missing
- if no MCP config exists, init creates one in the most likely workspace path (`.cursor/mcp.json`, `.mcp.json`, `.roo/mcp.json`, `.windsurf/mcp.json`, or fallback `.vscode/mcp.json`)
- existing server definitions are preserved

Claude Code note:
- Claude Code user/local MCP: `~/.claude.json` (default)
- Claude Code project MCP: `.mcp.json` (repo root)
- init merges both if they already exist
- init does not auto-create `~/.claude.json` (to avoid unexpected global machine-level changes)

Template used for merge:

`.ai/story-agent/templates/vscode/mcp.json`

## Daily Usage

All `/story-agent`, `/explain-story`, and `/plan-story` commands must run in agent mode.

```text
/story-agent <id>
/explain-story <id>
/plan-story <id>
/plan-story <id> lens=architecture,testing
```

Open `.ai/story-agent/outputs/stories/<id>/plan.md` and hand off to your coding agent.

## Output Files

Inside `.ai/story-agent/outputs/stories/<id>/`:

- `story.md` — verbatim story details and links
- `attachments/` — downloaded files from tracker
- `design/` — rendered design frames (if configured)
- `manual-todo.md` — SSO-blocked links requiring manual paste
- `analysis.md` — lens-based impact analysis
- `explanation.md` — concise narrative and open questions
- `decisions.md` — open-question responses captured during planning
- `plan.md` — ordered implementation steps, risks, checks, rollback notes

## Prerequisites

Install `uv` (provides `uvx`, used by MCP servers):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
which uvx && uvx --version
```

Add tracker credentials to `.env` (copy from `.env.example`).

## Safety + Scope

- Keep secrets in `.env`/environment variables; never commit real tokens
- `.ai/story-agent/outputs/stories/` should stay gitignored
- story-agent is planning-first: it stops at `plan.md` and does not edit source by itself

## Owner

- Shuchita Jain
