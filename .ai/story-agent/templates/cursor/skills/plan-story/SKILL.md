---
name: plan-story
description: Discovers codebase context, runs analysis lenses, and generates an implementation plan for a story. Requires explain-story to have run first. Invoke with /plan-story.
disable-model-invocation: true
---

Follow [.ai/story-agent/agents/plan-story.md](../../../agents/plan-story.md) for the story id provided.

If `.ai/story-agent/outputs/stories/<id>/story.md` is missing, tell the user to run `/explain-story <id>` first.

If no id is provided, ask the user for one and stop.

After writing `plan.md`, print a chat summary (taskized yes/no, execution-unit count, impacted-file count, risk count) pointing at the file. Do not start implementing.
