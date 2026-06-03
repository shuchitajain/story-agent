---
name: story-agent
description: Full workflow — fetch story context from a tracker (Jira / ADO / Linear / GitHub Issues), a local file, or inline text — then analyze the codebase and generate an implementation plan. Pauses for confirmation before planning.
tools:
  - github
  - filesystem
---

Follow [.ai/story-agent/agents/story-agent.md](../../.ai/story-agent/agents/story-agent.md) for the input provided.

Input can be a tracker ID (e.g. PROJ-123), a local file path, or inline story text pasted directly into the prompt. If no input is provided, ask the user for one and stop.

This runs explain-story then pauses to ask before continuing to plan-story.
