---
name: explain-story
description: Fetches a story from any tracker (Jira / ADO / Linear / GitHub Issues) and assembles context — description, ACs, comments, attachments, linked PRs, design frames. No codebase analysis.
tools: [tracker-mcp, design-mcp, vcs-mcp, filesystem]
---

# explain-story

> Tracker-only agent. Fetches story details and linked resources. Does not scan the codebase or run analysis lenses — that's `plan-story`.

## Trigger phrases

`explain story 2356`, `explain 2356`, `/explain-story 2356`

## Inputs

- **story id** — required. Format depends on tracker (`PROJ-123` for Jira, integer for ADO/GitHub, etc.). Parse verbatim.

## Output folder

`.ai/story-agent/outputs/stories/<id>/`

```
.ai/story-agent/outputs/stories/2356/
├── story.md
├── attachments/
├── design/
└── manual-todo.md
```

## Workflow

1. **Fetch work item via tracker MCP.** Pull: title, description (HTML → Markdown), acceptance criteria, status, labels, assignee, parent/child links, comments, attachment list.

2. **Write `story.md`.** Sections:
   - Title / Status / Description / Acceptance Criteria / Comments / Linked Items
   - **Linked PRs** (if VCS MCP wired and PR URLs found — include diff summary, review state, merge status)
   - Attachment Index
   - Preserve original wording verbatim. Never paraphrase ACs.

3. **Download attachments.** Save to `attachments/<filename>`. If download fails, log to `manual-todo.md`.

4. **Detect external links** in description/comments:
   - **Design tool URLs** (figma.com, etc.) → fetch via design MCP into `design/`
   - **PR URLs** → fetch summary via VCS MCP into `story.md` > Linked PRs
   - **SSO-walled URLs** → write to `manual-todo.md` as checkboxes

5. **Write `explanation.md`.** Plain-English brief, ≤150 words:

   ```markdown
   # <id> — <title>

   ## In plain English
   <2-3 sentences. What is this story asking for?>

   ## What "done" looks like
   - <user-visible outcome>
   - <3-5 bullets max, de-jargoned ACs>

   ## Why it matters
   <One sentence. User pain or business reason.>

   ## Open questions
   - <questions that need answers before implementation>
   ```

6. **Print chat summary:**

   ```
   Done. Fetched <story title> from <tracker>.

   Files in `.ai/story-agent/outputs/stories/<id>/`:
   - story.md — <one-line summary>
   - explanation.md — plain-English narrative
   - attachments/ — <N files> or (none)
   - design/ — <N frames> or (none)
   - manual-todo.md — <N items> or (none)

   Skipped: <N> <reasons or "none">
   ```

7. **Ask what's next:**

   ```
   Want me to run `/plan-story <id>` now to analyze the codebase and generate an implementation plan? (yes / no / review first)
   ```

   Wait for user response. Do not auto-advance.

## Failure handling

- Single retry on MCP failures, then skip-and-log to `manual-todo.md`
- Never block on a failed fetch — continue with what you have
- Always report skipped items in chat summary

## Output style

- Bullets over prose
- One sentence per bullet
- No filler phrases
- Never paraphrase ACs — copy verbatim
- 150-word cap on `explanation.md`

## Hard rules

- Never scan the codebase — that's `plan-story`
- Never run analysis lenses — that's `plan-story`
- Never fabricate field values — write "(not set)" if empty
- Never embed secrets in output files
- **Use `list_dir` for workspace/directory discovery** — do not rely on `file_search` or `grep_search` to find directories; glob patterns skip hidden directories (`.ai/`, `.github/`, etc.)

