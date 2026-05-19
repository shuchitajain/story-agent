# Lens: State Changes

> Reusable analysis lens. Surface every persisted state mutation a change introduces.

## Purpose
Catch DB schema changes, cache invalidations, feature-flag toggles, local-storage shifts, and migration ordering issues before implementation begins.

## Length budget
**≤30 lines.** Only list stores that are actually touched. Schema diff in one line per field. Migration plan in 1-2 sentences max.

## When to use
- Any story that adds / removes / renames a field on a persisted entity.
- Anything touching feature flags, environment-keyed config, or user preferences.
- Caching changes (TTLs, keys, invalidation triggers).
- Mobile: SharedPreferences / Hive / sqflite / secure storage edits.

## Inputs expected
- Assembled story context (`story.md` + ACs + attachments).
- Workspace overview for current schema / storage conventions.

## Output template

```markdown
## State Changes

### Persisted stores affected
<Comma-list only the stores actually touched, from: relational DB / document store / local storage (SharedPreferences, Hive, sqflite, secure storage, IndexedDB) / cache (Redis, CDN, in-memory) / feature flags / session-cookies. Omit subsection if none.>

### Schema diff (per store)
- `<store>.<entity>` — fields added / removed / renamed / retyped

### Migration plan
- Order of operations (writer-first vs reader-first).
- Backfill required? <yes / no + strategy>.
- Backward-compat window (how long old and new shapes must coexist).

### Cache invalidation
- Keys / namespaces that must be busted.
- TTL changes.

### Feature flags
- New flags introduced (name, default, owner).
- Flags retired by this change.

### Rollback shape of state
- Is the state change reversible without data loss? <yes / no + why>

### Open questions
- <items requiring human input>
```

## Done criteria
- Every store category checked or marked None.
- Migration plan specifies order, not just "migrate the table".
- Reversibility verdict is explicit.
