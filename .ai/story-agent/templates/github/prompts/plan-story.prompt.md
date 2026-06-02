---
mode: agent
description: Produce an implementation plan for a story by reading the assembled context folder. Runs explain mode first if outputs are missing.
---

# /plan-story

Follow [.ai/story-agent/agents/plan-story.md](../../.ai/story-agent/agents/plan-story.md) for the story id provided.

If `.ai/story-agent/outputs/stories/<id>/story.md` is missing, tell the user to run `/explain-story <id>` first.

If no id is provided, ask the user for one and stop.

After writing `plan.md`, print a chat summary (taskized yes/no, execution-unit count, impacted-file count, risk count) pointing at the file. Do not start implementing. The user invokes a separate agent for that.