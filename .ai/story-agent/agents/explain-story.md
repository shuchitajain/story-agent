---
name: explain-story
description: Loads story context from a tracker (Jira / ADO / Linear / GitHub Issues), a local file, or inline text — then assembles explanation, open questions, and a planning prompt. No codebase analysis.
tools: [filesystem, tracker-mcp, design-mcp, vcs-mcp]
# filesystem is always available.
# tracker-mcp / design-mcp / vcs-mcp are declared but must only be called in tracker mode (see Hard rules).
---

# explain-story

> Context-loading agent. Reads story details from a tracker, a local file, or inline text. Does not scan the codebase or run analysis lenses — that's `plan-story`.

## Trigger phrases

`explain story 2356`, `explain 2356`, `/explain-story 2356`
`/explain-story ./path/to/story.md`
`/explain-story "<inline story text>"`

## Inputs

Exactly one of the following — detect automatically from the invocation:

- **Tracker ID** — `PROJ-123`, integer, or similar. Format depends on tracker. Fetch from MCP. Example: `/explain-story PROJ-123`
- **File path** — a relative or absolute path ending in `.md` or an existing file. Read from disk. Example: `/explain-story .ai/story-agent/outputs/stories/TEST-2/story.md`
- **Inline text** — a quoted or unquoted block of story text provided directly in the prompt. Parse as-is. Example: `/explain-story "As a user I want to..."`

**Input mode determines which steps run.** See workflow below.

## Output folder

`.ai/story-agent/outputs/stories/<id>/`

```
.ai/story-agent/outputs/stories/2356/
├── story.md
├── explanation.md
├── attachments/          (only when the tracker lists attachments)
├── design/               (only when design links exist)
│   ├── <slug>.png        (required — one per resolved Figma node)
│   └── <slug>.md         (optional metadata companion)
└── manual-todo.md        (only when there are failures or story gaps)
```

## Workflow

### Step 0 — Detect input mode

| Signal | Mode | ID to use |
|---|---|---|
| Looks like a tracker ID (`PROJ-123`, integer, etc.) | **tracker** | parse verbatim |
| Looks like a file path (contains `/` or `\`, has a file extension, or path exists on disk) | **file** | derive from folder name or filename stem |
| Quoted or unquoted free text that is not a path or ID | **inline** | derive a slug from the title or first line |

---

### Tracker mode (steps 1–4 only run in this mode)

1. **Fetch work item via tracker MCP.** Pull: title, description (HTML → Markdown), acceptance criteria, status, labels, assignee, parent/child links, comments, attachment list.

2. **Write `story.md`.** Sections:
   - Title / Status / Description / Acceptance Criteria / Comments / Linked Items
   - **Linked PRs** (if VCS MCP wired and PR URLs found — include diff summary, review state, merge status)
   - Attachment Index
   - Preserve original wording verbatim. Never paraphrase ACs.
 
3. **Download attachments.** Only if the tracker returns one or more attachments:
   - Create `attachments/` and save each file to `attachments/<filename>`.
   - If a download fails, log to `manual-todo.md`.
   - If there are **no** attachments, skip this step entirely — do **not** create `attachments/`.
 
4. **Detect external links** in description/comments:
   - **Design tool URLs** (figma.com, etc.) → [Design fetch (Figma)](#design-fetch-figma). Only create `design/` when design links exist.
   - **PR URLs** → fetch summary via VCS MCP into `story.md` > Linked PRs
   - **SSO-walled URLs** → write to `manual-todo.md` as checkboxes
 
#### Design fetch (Figma)
 
For **each** Figma URL in description, ACs, or comments:
 
1. **Parse** `fileKey` and `nodeId` from the URL (`node-id=9519-15294` → `9519:15294`).
2. **Export PNG (required).** Call design MCP `download_figma_images`:
   - `fileKey` — parsed from URL
   - `nodes` — `[{ "nodeId": "<id>", "fileName": "<slug>.png" }]`
   - `localPath` — `.ai/story-agent/outputs/stories/<id>/design` (path relative to workspace root)
   - `pngScale` — `2` unless the user specifies otherwise
   - **Slug** the filename from the frame name or a short state label (e.g. `green-banner-no-buffer.png`).
3. **Verify** the `.png` exists under `design/`. If the MCP wrote elsewhere, copy or move it into `design/`. A resolved node without a saved PNG is an **incomplete** fetch.
4. **Metadata (optional).** Call `get_figma_data` for the same node and, if useful, write a companion `design/<slug>.md` with layout tokens, copy, and colors. This supplements the PNG — it does **not** replace it.
5. **Record** each link in `story.md` > **Design Links** table: URL, node, PNG filename, fetch status.
6. **On failure** (node not found, auth error): single retry, then log to `manual-todo.md` under `Access / Fetch Failures`. Do not substitute alternate frames unless the story text names them.
 
**Never** satisfy design fetch with markdown-only output. Metadata from `get_figma_data` alone is not a design deliverable.
 
---

### File mode (replaces steps 1–4)

1. **Read the file from disk.** Handle by extension:
   - `.md` / `.txt` — read as plain text, treat as story content verbatim.
   - `.pdf` — extract text if a PDF-reading tool is available; otherwise log to `manual-todo.md` under `Access / Fetch Failures` and proceed with whatever text can be extracted.
   - `.doc` / `.docx` — extract text if a Word-reading tool is available; otherwise log to `manual-todo.md` and proceed with whatever text can be extracted.
   - Any other extension — attempt plain-text read; if binary or unreadable, log to `manual-todo.md` and stop file mode, falling back to inline mode with whatever the user provided in the prompt.
   - If the file is already inside the output folder (`.ai/story-agent/outputs/stories/<id>/`), use that folder as the output folder for all subsequent files.
   - If the file is outside the output folder, derive `<id>` from the folder name or filename stem, create the output folder, and write extracted content to `story.md` there.
   - Skip attachment download and external link detection — no MCP calls.

---

### Inline mode (replaces steps 1–4)

1. **Write the provided text to `story.md`** in the output folder. Derive `<id>` from the first heading or first line (slugified). Do not invent fields not present in the input.
   - Skip attachment download and external link detection — no MCP calls.

---

### All modes continue from here

2. **Write `explanation.md`.** Plain-English brief, ≤150 words:

   ```markdown
   # <id> — <title>

   ## In plain English
   <2-3 sentences. What is this story asking for?>

   ## What "done" looks like
   - <user-visible outcome>
   - <3-5 bullets max, de-jargoned ACs>

   ## Why it matters
   <One sentence. User pain or business reason.>

   ## Likely impact (preview, not code analysis)
   - <1-3 bullets. High-level areas this probably affects>

   ```

   Rules:
   - Read `.ai/story-agent/prompts/question-classification.md` before deciding what to surface.
   - Keep this to a preview only. Do not claim codebase certainty or file-level impact here.
   - Do **not** write an "Open questions" section here — questions are handled in the next step.

3. **Print chat summary:**

   ```
   Done. Loaded <story title> from <source: tracker | file | inline text>.

   Files in `.ai/story-agent/outputs/stories/<id>/`:
   - story.md — <one-line summary>
   - explanation.md — plain-English narrative
   - attachments/ — <N files> or (none)
   - design/ — <N PNG frames> (+ <M metadata files>) or (none)
   - manual-todo.md — <N items> or (none)
   - decisions.md — (none yet, pending question answers below) or (none)

   Skipped: <N> <reasons or "none">
   ```

4. **Ask open questions (if any).** Classify any materially relevant questions using `question-classification.md`. If there are none, skip this step. Otherwise present them in chat, immediately followed by the plan-story prompt:

   ```
   Before moving on, I have <N> question(s) for the PM / product team:

   1. **<question>** — why it matters: <one line>. Default: <assumption>.
   ...

   Reply with numbered answers, or continue to run `/plan-story <id>` with all defaults accepted.
   ```

   If there are no open questions, present the plan-story prompt on its own:

   ```
   Ready to run `/plan-story <id>` to analyze the codebase and generate an implementation plan. Continue?
   ```

   **Response handling** — interpret intent loosely:
   - User answers question(s) by number — record in `decisions.md`, then re-present remaining questions (if any), or the plan-story prompt once all are resolved.
   - User signals they want to proceed — any of: `yes`, `continue`, `go`, `run plan`, `plan it`, `/plan-story`, or similar affirmative — write all unresolved questions to `decisions.md` as defaults, then immediately invoke `/plan-story <id>`. Do **not** ask again.
   - User answers some questions and also signals to proceed — record the explicit answers, default the rest, then invoke `/plan-story <id>`.
   - User signals stop or wants to review — any of: `no`, `stop`, `review first`, `not yet`, or similar — write all unresolved questions to `decisions.md` as defaults and stop.

   For each question resolved (answered or defaulted):
   - Append an entry to `decisions.md` (create the file if it does not exist yet):

     ```markdown
     # Decisions — <id>

     ## Q<n>. <question>
     - Category: <blocking | scope | clarification>
     - From: explain-story
     - Audience: PM
     - Why this matters: <one line>
     - Answer: <user answer> or `default: <assumption text>`
     - Implication: <one line — what this means for planning>
     ```

   If the user leaves without replying at all, write the remaining questions to `explanation.md` under an "Open questions" section so `plan-story` can drain them:

   ```markdown
   ## Open questions
   - <question> — Default: <assumption>
   ```

## Failure handling

- Single retry on MCP failures, then skip-and-log to `manual-todo.md`
- A Figma node counts as fetched only when its `.png` is saved under `design/` — metadata-only output is a failure
- Never block on a failed fetch — continue with what you have
- Always report skipped items in chat summary
- Split `manual-todo.md` into `Access / Fetch Failures` and `Story Gaps` when both are present

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
- Use `question-classification.md` to filter out low-value or cosmetic questions
- **Use `list_dir` for workspace/directory discovery** — do not rely on `file_search` or `grep_search` to find directories; glob patterns skip hidden directories (`.ai/`, `.github/`, etc.)
- **Never call `tracker-mcp`, `design-mcp`, or `vcs-mcp` in file or inline mode** — input is already on disk or in the prompt; no remote calls are needed or permitted.
- **Design fetch must save PNG exports** — never write markdown-only summaries to `design/` in place of rendered frames
- **Never create empty output directories** — do not `mkdir` `attachments/` or `design/` upfront; create each directory only when saving the first file into it
 
