---
name: explain-story
description: Loads story context from a tracker (Jira / ADO / Linear / GitHub Issues), a local file, or inline text — then assembles explanation, open questions, and a planning prompt. No codebase analysis.
tools:
  - github
  - filesystem
---

Follow [.ai/story-agent/agents/explain-story.md](../../.ai/story-agent/agents/explain-story.md) for the input provided.

Input can be a tracker ID (e.g. PROJ-123), a local file path, or inline story text pasted directly into the prompt. If no input is provided, ask the user for one and stop.

After completing, print a chat summary and ask if the user wants to run the plan-story agent next. Wait for response.
