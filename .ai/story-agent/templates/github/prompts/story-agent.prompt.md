---
agent: agent
description: Full workflow — fetch story from tracker, analyze codebase, generate an implementation plan. Pauses for confirmation before planning.
---

# /story-agent

Follow [.ai/story-agent/agents/story-agent.md](../../.ai/story-agent/agents/story-agent.md) for the story id provided.

This runs `/explain-story` then pauses to ask before continuing to `/plan-story`.

If no id is provided, ask the user for one and stop.

