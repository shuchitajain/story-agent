---
mode: agent
description: Fetch a story end-to-end from your configured tracker (Jira / Azure DevOps / Linear / GitHub Issues / etc.) including description, ACs, comments, attachments, and design-tool frames, then write a 5-lens analysis to .ai/outputs/stories/<id>/.
---

# /explain-story

Follow [.ai/agents/story-agent.md](../../.ai/agents/story-agent.md) in **`explain` mode** for the story id provided in the user's message. Tracker is configured in `.ai/context/project-overview.md` under Tooling.

If no id is provided, ask the user for one and stop.

After completing the workflow, print a short chat summary (file count, lens count, open-question count) and stop. Do not start `plan` mode unless the user explicitly asks.
