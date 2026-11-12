---
# ── Portable (agentskills.io spec) ──
name: code-review
description: "Review a diff for bugs, the repo's written standards, and spec conformance, with every finding verified before the report. Report-only; with no target, reviews staged changes, else all uncommitted ones."
compatibility: "Needs the skill swe:code-review-core, called by name. On Claude Code, context: fork runs the review in a background subagent and the report arrives as a notification. Hosts that ignore it run the review in the main conversation. Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extensions ──
# disable-model-invocation blocks auto-invocation; only /swe:code-review works.
# context: fork + background: true run this body in a background subagent, so
# the conversation stays usable during the review.
disable-model-invocation: true
argument-hint: "[--spec <spec, plan, or ticket URL>] [--slice <n>] [--model <name>] [--effort <level>] [target]"
context: fork
background: true

# Maintainer notes (frontmatter never reaches the model):
# - A thin wrapper: the review itself is swe:code-review-core, which
#   /swe:implement's review loop also calls. This skill adds only the user
#   command and the background fork.
# - No fallback that reads the engine's files: a skill reads nothing outside
#   its own directory. Both skills ship in one plugin, so the engine is
#   missing only on a host that can't call skills by name.
---

# Code review

ARGUMENTS: $ARGUMENTS

Invoke the skill `swe:code-review-core`, by name, with the arguments above unchanged, and follow it to the end. Its report, or the message that stops it, is your final message, word for word.

When the skill can't be reached, your whole final message is: `Couldn't reach the skill swe:code-review-core, which runs the review. Check that the swe plugin is installed whole and that this host lets a skill call another by name.`
