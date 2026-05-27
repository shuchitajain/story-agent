# Existing MCP (Before/After)

## Before

Repo (or user machine) already has MCP config.

```text
.
├── .vscode/mcp.json
├── .cursor/mcp.json
└── .mcp.json
```

Example existing config:

```json
{
  "servers": {
    "custom": {
      "type": "stdio",
      "command": "echo",
      "args": ["ok"]
    }
  },
  "inputs": []
}
```

## Command

```bash
./scripts/story-agent init .
```

## After

The installer merges story-agent servers only when missing:

- `jira`
- `figma`
- `github`

Existing servers stay untouched.

## Claude Code behavior

- User/local MCP: `~/.claude.json` (merged if present)
- Project MCP: `.mcp.json` (merged if present)
- `~/.claude.json` is never auto-created by init

## Notes

- No server entries are deleted.
- Re-running init does not duplicate server entries.
