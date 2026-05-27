# Copilot Workspace Instructions

Read these on every Copilot Chat invocation in this workspace.

## Source of truth
- Agent definitions: `.ai/story-agent/agents/`. When the user types a phrase matching an agent's trigger, follow that agent's workflow verbatim.
- Analysis lenses: `.ai/story-agent/prompts/`. Apply on request, e.g. "apply rollback-risks to this PR".
- Project context: Auto-discovered from `CLAUDE.md`, `README.md`, `ARCHITECTURE.md`, `package.json`, etc.

## Hard rules
- **No fabrication.** If a file path or field is not in the workspace or fetched data, mark it "candidate, verify".
- **No paraphrasing of acceptance criteria.** Copy verbatim from tracker.
- **No secrets in outputs.** Tokens, PATs, connection strings never appear in `.ai/story-agent/outputs/` or chat.
- **Decompose.** No single change touches more than 3 files or mixes UI / domain / data layers in one step.
- **Human approves.** Never auto-edit source files without explicit instruction. Planning agents stop at `plan.md`.

## Tool selection
- Prefer **MCP servers** over custom HTTP / shell calls for ADO, Figma, GitHub, Confluence.
- Match model to task: low-latency for narrow edits, high-reasoning for design / planning / debugging.

## Output style
- Markdown formatting, file references as workspace-relative links.
- No emojis unless asked.
- Short paragraphs, concrete verbs, no hedging.
