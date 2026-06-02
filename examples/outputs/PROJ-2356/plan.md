# Plan: PROJ-2356 — Add offline sync for field inspection forms

## Summary

Adds an offline submission queue backed by SQLite, a sync service that drains the queue when connectivity is restored, and a conflict resolution prompt when the server detects a merge conflict. The entire offline path is wrapped behind a feature flag.

## Status

- Taskized: yes — 3 tasks, current: task-1
- Assumptions in force: 1
- Story last reviewed: 2026-06-03

---

## Tasks

### Task 1 — Offline queue and submission routing

**ID:** task-1  
**Depends on:** none  
**Goal:** Inspection form submissions route to a local SQLite queue when offline instead of calling the API.

**Files:**

- `lib/data/repositories/inspection_queue_repository.dart`
- `lib/services/inspection_submission_service.dart`

**Change:** Extend `InspectionQueueRepository` (from PR #842) with `enqueue()`, `markInFlight()`, `markFailed()`, and `drain()` methods. Modify `InspectionSubmissionService.submit()` to check `ConnectivityService.isOnline` and route to `enqueue()` when offline, falling back to the existing direct API call when online.

**Verify:** Unit tests for `submit()` — offline path enqueues, online path bypasses queue. Queue items persist across a simulated app restart.

**Handoff expectation:** `InspectionQueueRepository.drain()` works; `InspectionSubmissionService.submit()` correctly enqueues when offline. All unit tests pass.

---

### Task 2 — Sync service and connectivity trigger

**ID:** task-2  
**Depends on:** task-1  
**Goal:** Queue drains automatically when the device reconnects; conflicts are detected and classified.

**Files:**

- `lib/services/sync_service.dart`
- `lib/services/connectivity_service.dart`

**Change:** Create `SyncService.syncPendingInspections()` — iterates queue items via `drain()`, posts each to the API, checks `"conflict"` in the response body, marks items `synced` or `conflicted`. Wire `ConnectivityService` to call `syncPendingInspections()` on its `onConnected` event.

**Verify:** Integration test — mock API returns `{"conflict": true, ...}`; assert queue item transitions to `conflicted`. Mock API returns success; assert item removed from queue.

**Handoff expectation:** `SyncService` wired to connectivity events; sync outcomes classified correctly. No UI changes yet.

---

### Task 3 — Sync status badge and conflict prompt

**ID:** task-3  
**Depends on:** task-2  
**Goal:** Users see current sync state in the form header and receive a merge prompt on conflict.

**Files:**

- `lib/ui/widgets/sync_status_badge.dart`
- `lib/ui/screens/inspection_form_screen.dart`

**Change:** Create `SyncStatusBadge` widget with three states: offline, syncing, synced. Mount in `InspectionFormScreen` header (top-right, per Figma frame). Add a conflict dialog triggered when `SyncService` emits a conflict event; dialog shows server-version fields alongside local values with "Keep mine / Use server version" actions.

**Verify:** Widget tests for all three badge states. Manual test: airplane mode → fill form → reconnect → confirm badge transitions offline → syncing → synced. Trigger mock conflict → confirm dialog appears with both field versions.

**Handoff expectation:** All ACs testable. Existing online-mode integration tests still pass.

---

## Human checkpoints

- Review and approve after each completed task before advancing.
- Use `validation.md` to record validation results and handoff notes.

## Final validation checkpoint

- Run full test suite: `flutter test`.
- Manual E2E in airplane mode on a physical device.
- Disable `offline_sync_enabled` flag — verify existing online path is unchanged.

## Risks (from analysis.md)

- Conflict resolution depends on server returning `"conflict": true` — verify against `offline-sync-spec.pdf` before task 2.
- Attachment queuing is out of scope; PM must communicate this to field ops before release.

## Tests to write

- Unit: `InspectionSubmissionService.submit()` routing logic, `SyncService` conflict detection.
- Integration: offline queue → sync round-trip with mock API (success and conflict paths).
- Widget: `SyncStatusBadge` (all three states), conflict dialog field rendering.

## Rollback plan

- Feature flag `offline_sync_enabled` wraps the offline path; flip to `false` to restore original behavior immediately.
- No server-side changes to roll back.

## Assumptions taken

- Attachment queuing is out of scope (accepted default, Q1 in `decisions.md`).

## Out of scope

- Multi-device conflict (two devices submitting the same form offline simultaneously).
