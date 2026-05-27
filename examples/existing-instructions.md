# Existing Instructions (Before/After)

## Before

Repo already has instruction systems.

```text
.
├── CLAUDE.md
├── .cursorrules
├── .github/copilot-instructions.md
└── README.md
```

## Command

```bash
./scripts/story-agent init .
```

## After

```text
.
├── CLAUDE.md                           # preserved
├── .cursorrules                        # preserved
├── .github/copilot-instructions.md     # preserved
├── .ai/story-agent/                    # added
└── .github/prompts/                    # added only for Copilot setup or --with-copilot-prompts
```

Each detected instruction file gets one additive block:

```markdown
## Story Agent

See: .ai/story-agent/instructions/agent-instructions.md
```

## Notes

- Existing content is not replaced.
- Re-running init does not duplicate the Story Agent block.
