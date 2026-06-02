# Decisions — PROJ-2356

Recorded 2026-06-03T10:14:22Z.

## Q1. Should attachment queuing be in scope for this story?

- Category: scope
- Audience: PM
- From: explain-story
- Why this matters: large offline attachments could exceed local storage limits and require a separate size-capping strategy.
- Answer: default: exclude attachments from offline queue — text fields only in this story.
- Implication: `offline_queue` stores form field values only; attachment handling deferred to PROJ-2401.

## Q2. Is the conflict merge UI a blocking requirement or can it be deferred?

- Category: blocking
- Audience: PM
- From: explain-story
- Why this matters: PM comment explicitly flags silent overwrites as a compliance violation.
- Answer: blocking — merge prompt is required in this story per PM Raj Nair (2026-05-30).
- Implication: conflict resolution UI must ship before sign-off; adds approximately 1.5 days.

## Q3. Which conflict resolution strategy does the backend sync contract prescribe?

- Category: blocking
- Audience: Engineering
- From: architecture-impact
- Why this matters: client-side merge prompt behavior depends on what the server returns on conflict.
- Answer: last-write-wins with server conflict flag in response body (`"conflict": true, "server_version": {...}`).
- Implication: client checks `conflict` field in sync response and surfaces merge prompt when true.
