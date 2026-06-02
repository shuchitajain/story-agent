# PROJ-2356 — Add offline sync for field inspection forms

## In plain English

Field technicians working in dead-zones can't submit inspections right now. This story queues form submissions locally and syncs them automatically once connectivity returns, with a merge prompt when conflicts are detected server-side.

## What "done" looks like

- Forms open and save without a network connection
- Queued submissions auto-sync when the device reconnects
- A sync status badge is visible in the form header (offline / syncing / synced)
- Conflicts surface a merge prompt instead of silently overwriting
- Queue survives app restarts and device reboots
- Existing online-mode behavior unchanged

## Why it matters

Compliance-critical inspections are being lost when network drops mid-session; silent overwrites are a client-level compliance violation.

## Likely impact (preview, not code analysis)

- Local persistence layer (queue storage and state machine)
- Sync service and network state detection
- Form submission flow and status UI
