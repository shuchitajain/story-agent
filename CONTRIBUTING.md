# Contributing

Thanks for your interest in contributing to story-agent.

## What to work on

Check the open issues. Anything labeled `good first issue` is a good starting point.

If you want to propose something new, open an issue first before writing code. It avoids wasted effort if the direction doesn't fit.

## Setup

```bash
git clone https://github.com/shuchitajain/story-agent.git
cd story-agent
```

No build step required. story-agent is plain bash and markdown.

## What's in scope

- Improvements to agent prompts under `.ai/story-agent/agents/`
- New or improved prompt rules under `.ai/story-agent/prompts/`
- Fixes or improvements to `scripts/story-agent-init.sh`
- New IDE wrapper templates under `.ai/story-agent/templates/`
- Additional tracker, design tool, or VCS support

## What's out of scope

- Adding a CLI or Python layer (the host IDE's LLM handles reasoning)
- Breaking changes to existing init behavior without a migration path
- Changes that couple story-agent to a specific tracker or IDE

## Pull requests

- Keep PRs focused. One thing per PR.
- Update `examples/` if your change affects agent output format.
- Test `scripts/story-agent init` against a real repo before opening a PR.

## Questions

Open an issue or reach out on [LinkedIn](https://www.linkedin.com/in/shuchita-jain/).
