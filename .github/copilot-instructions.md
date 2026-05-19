# Copilot Workspace Instructions

Read these on every Copilot Chat invocation in this workspace.

## Source of truth
- Project knowledge: [.ai/context/project-overview.md](../.ai/context/project-overview.md). Read it before answering anything about the stack, layers, storage, tests, or rollback policy.
- Active agent definitions: [.ai/agents/](../.ai/agents/). When the user types a phrase matching an agent's trigger, follow that agent's workflow verbatim.
- Reusable analysis lenses: [.ai/prompts/](../.ai/prompts/). Apply on request, e.g. "apply rollback-risks to this PR".

## Hard rules
- **No fabrication.** If a file path, ADO field, or API name is not in the workspace or in fetched data, mark it "candidate, verify".
- **No paraphrasing of acceptance criteria.** Copy verbatim from ADO.
- **No secrets in outputs.** PATs, Figma tokens, connection strings never appear in `.ai/outputs/` or chat.
- **Decompose.** No single change touches more than ~3 files or mixes UI / domain / data layers in one step.
- **Human approves.** Never auto-edit source files without an explicit instruction. Planning agents stop at `plan.md`.
- **Lean context.** Pull only task-critical files into context. Prefer reading `.ai/context/project-overview.md` over dumping the whole repo.

## Tool selection
- Prefer **MCP servers** over custom HTTP / shell calls for ADO, Figma, GitHub, Confluence.
- Match model to task: low-latency for narrow edits, high-reasoning for design / planning / debugging.

## Output style
- Markdown formatting, file references as workspace-relative links.
- No emojis unless asked.
- Short paragraphs, concrete verbs, no hedging.

## Champion artefacts in this workspace
See the table at the bottom of [.ai/context/project-overview.md](../.ai/context/project-overview.md). Every artefact has a named owner and an SDLC AI Map row.
