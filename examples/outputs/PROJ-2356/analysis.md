# Analysis — PROJ-2356

**TL;DR.** Conflict resolution is the critical path. Biggest risk: silent merge during sync if conflict check is skipped. Biggest unknown: exact server conflict response contract (blocked by `offline-sync-spec.pdf` fetch failure).

---

## Architecture impact

- Layers touched: persistence, sync service, submission flow, network state listener, form UI.
- `InspectionQueueRepository` (PR #842) provides the SQLite backing store — this is the insertion point.
- No existing `SyncService` equivalent found; needs to be created.
- `ConnectivityService` exists but is only used for feature flags — needs to drive sync trigger.
- `InspectionSubmissionService.submit()` must branch: queue when offline, call API when online.
- ADR not required (SQLite precedent already set). ADR recommended for conflict resolution strategy.

---

## State changes

- New table: `offline_queue` — stores serialized form fields, status (`pending` / `in_flight` / `conflicted` / `synced`), retry count.
- PR #842 schema may need extension for conflict metadata (`server_version`, `conflict_at`).
- Reversibility: queue drains without data loss; rollback requires a down-migration to drop the table.
- No server-side schema changes implied — backend sync contract indicates server is already conflict-aware.

---

## Edge cases

- App killed mid-upload: items marked `in_flight` must reset to `pending` on restart.
- Conflict on sync: AC 4 mandates user prompt — implement optimistic lock check on sync response.
- Multiple devices submitting the same form offline simultaneously: out of scope per story notes.
- Large attachments queued offline: no size cap defined — flagged in `manual-todo.md`.

---

## Testing strategy

- Unit: `SyncService` dispatch logic, conflict detection, queue state machine transitions.
- Integration: offline queue → sync round-trip against a mock API (success and conflict paths).
- Widget: `SyncStatusBadge` renders all three states; conflict dialog renders field comparison.
- Manual E2E: airplane mode → fill form → reconnect → verify server received submission.
- Regression: existing online submission path must pass existing test suite unchanged.

---

## Rollback risks

- Feature flag `offline_sync_enabled` recommended — wraps entire offline path.
- Disabling the flag routes `submit()` back to the original online path immediately.
- Data rollback: if queue table is corrupted, in-flight submissions are lost — acceptable given no prior data there.
- No server-side rollback needed.
