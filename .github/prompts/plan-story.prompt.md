---
mode: agent
description: Produce an implementation plan for a story by reading the assembled context folder. Runs explain mode first if outputs are missing. Works with any tracker configured in project-overview.md.
---

# /plan-story

Follow [.ai/agents/story-agent.md](../../.ai/agents/story-agent.md) in **`plan` mode** for the story id provided in the user's message.

If `.ai/outputs/stories/<id>/story.md` or `analysis.md` is missing, run `explain` first, then continue with `plan`.

If no id is provided, ask the user for one and stop.

After writing `plan.md`, print a chat summary (step count, impacted-file count, risk count) pointing at the file. Do not start implementing. The user invokes a separate agent for that.
