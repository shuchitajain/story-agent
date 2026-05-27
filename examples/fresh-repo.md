# Fresh Repo (Before/After)

## Before

A repo with no AI instruction files and no MCP config.

```text
.
├── .gitignore
├── README.md
└── src/
```

## Command

```bash
./scripts/story-agent init .
```

## After

```text
.
├── .ai/story-agent/
│   ├── agents/
│   ├── instructions/
│   ├── outputs/
│   ├── prompts/
│   └── templates/
├── .github/
│   └── copilot-instructions.md
├── .vscode/mcp.json
└── .gitignore
```

## Notes

- Creates a minimal `.github/copilot-instructions.md` when no instruction system exists.
- Does not create `.github/prompts/` by default for fresh repos.
- Use `--with-copilot-prompts` to install Copilot prompt wrappers explicitly.
- Adds story-agent output block to `.gitignore`.
- Creates one MCP file in the detected fallback path.
