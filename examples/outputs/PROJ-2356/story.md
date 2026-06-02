# PROJ-2356 — Add offline sync for field inspection forms

**Status:** In Progress  
**Assignee:** Elena Torres  
**Labels:** offline, sync, mobile, Q3

---

## Description

Field technicians frequently lose connectivity in remote job sites. Currently, any inspection form submission requires an active network connection. This story adds offline support so technicians can fill and submit forms without connectivity; submissions sync automatically when the device reconnects.

## Acceptance Criteria

1. Technicians can open and complete inspection forms with no active network connection.
2. Completed forms are queued locally and sync automatically when connectivity is restored.
3. A visible indicator shows the device's current sync status (offline / syncing / synced).
4. If a conflict is detected (e.g., the form was updated server-side while offline), the conflict is surfaced to the user with a merge prompt — not silently overwritten.
5. Offline submissions survive app restarts and device reboots.
6. No existing online-mode behavior changes for users with connectivity.

## Comments

**Elena Torres** (2026-05-29): Design frames linked below — the sync indicator goes in the top-right corner of the form header.

**PM Raj Nair** (2026-05-30): AC 4 is a must-have; silent overwrites are a compliance violation for this client.