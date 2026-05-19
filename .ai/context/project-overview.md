# Project Overview — `<your project name>`

> Edit this file when you drop the story-agent bundle into a new workspace. Every story-agent run reads this first. Be specific; "use clean code" is not useful, "use Riverpod v2 generators, no ChangeNotifier" is.

---

## Tooling

> story-agent reads this section to know which MCPs to call.

- **Story tracker:** Jira (Cloud, `shuchitajain.atlassian.net`)
  - MCP server id in `.vscode/mcp.json`: `jira` (mcp-atlassian via uvx)
  - Story id format: `PROJ-N` (e.g. `SCRUM-5`)
  - Field mapping (tracker-specific → canonical):
    - Acceptance Criteria: Jira `customfield_10042` (verify on first fetch; fall back to description section if empty)
    - Story points: `customfield_10016` (verify; "not used" if absent)
    - Parent / epic: `parent` / `customfield_10014` (Epic Link)
- **VCS:** GitHub
  - MCP server id in `.vscode/mcp.json`: `github` (`@modelcontextprotocol/server-github`)
  - PR URL pattern to detect: `github.com/<org>/<repo>/pull/<n>`
  - Used for linked-PR enrichment only (diff summaries, review states, merge status). Not used for implementation writes.
- **Design tool:** Figma
  - MCP server id: `figma` (Figma Dev Mode MCP, hosted)
  - Link domain to detect: `figma.com`
- **SSO-walled knowledge sources:** none configured.

---

## Stack

- **Language(s):** Dart (Flutter 3.38.5)
- **Framework(s):** Flutter 3.38.5
- **State management:** Riverpod
- **Storage:** Hive, shared_preferences
- **Networking:** (not set)
- **Auth:** (not set)
- **CI / CD:** (not set)
- **Telemetry:** (not set)

## Architectural layers (used by `architecture-impact.md` lens)

- **Feature layout:** `lib/feature/<slug>/domain/` (single-tier `feature/domain` convention per bootstrap)
- **UI / presentation:** (inferred) co-located in `lib/feature/<slug>/` outside `domain/`
- **Domain / business logic:** `lib/feature/<slug>/domain/`
- **Data / persistence:** (inferred) Hive boxes + shared_preferences; no dedicated `data/` layer declared
- **Cross-cutting:** (not set)

## Persisted stores (used by `state-changes.md` lens)

- **Local key-value (primary):** Hive boxes (path: not set — candidate `lib/core/storage/` or per-feature, verify)
- **Lightweight prefs:** shared_preferences
- **Secure storage:** (not set)
- **Feature flags:** (not set)
- **Cache:** in-memory via Riverpod providers (inferred)

## Edge-case profile (used by `edge-cases.md` lens)

- **Mobile stack** — yes
- **Offline-first** — yes. Conflict-resolution strategy: (not set — verify per story)
- **Multi-device sync** — (not set)
- **Concurrent-edit risk** — (not set)
- **PII categories handled** — (not set)

## Test conventions (used by `testing-strategy.md` lens)

- **Unit / Widget / Integration / E2E layout:** (not set)
- **Mocks:** (not set)
- **Fixtures:** (not set)
- **Coverage gate:** (not set)

## Rollout / rollback conventions (used by `rollback-risks.md` lens)

- **Feature flags:** (not set)
- **Default rollout:** (not set)
- **Kill-switch:** (not set)
- **DB migration policy:** (not set — Hive box migrations handled per-adapter, verify)
- **App-store rollback:** (not set — staged rollout assumed)

## Champion artefacts registered in this workspace

| Artefact | Path | Owner | SDLC Map row |
|---|---|---|---|
| story-agent | `.ai/agents/story-agent.md` + 5 lenses in `.ai/prompts/` | <you> | Feature Development / planning |
| <other> | <path> | <owner> | <row> |

## External references

- Tracker project / workspace: `<id or url>`
- Design file / team: `<id or url>`
- Architecture wiki: `<url>`
- On-call runbook: `<url>`

## Confidentiality

- Client name in articles / public talks: (not set — no constraints declared).
- `.ai/outputs/` is gitignored. Do not commit story folders.

## Sensitive paths

- (none)
