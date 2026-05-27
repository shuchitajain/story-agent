---
mode: agent
description: Full workflow — fetch story from tracker, analyze codebase, generate implementation plan. Pauses for confirmation between phases.
---

# /story-agent

Follow [.ai/agents/story-agent.md](../../.ai/agents/story-agent.md) for the story id provided.

This runs `/explain-story` then pauses to ask before continuing to `/plan-story`.

If no id is provided, ask the user for one and stop.

