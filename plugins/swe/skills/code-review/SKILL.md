---
# ── Portable (agentskills.io spec) ──
name: code-review
description: "Review a diff for bugs, the repo's written standards, and spec conformance, with every finding verified before the report. Report-only; with no target, reviews staged changes, else all uncommitted ones."
compatibility: "Needs the skill swe:code-review-core, called by name. On Claude Code, context: fork runs the review in a background subagent and the report arrives as a notification. Hosts that ignore it, such as the Copilot harness, load this skill into the conversation, where it hands the review to one foreground subagent, or runs it there when it has no subagent tool. Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

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
#   command and where the review runs.
# - No fallback that reads the engine's files: a skill reads nothing outside
#   its own directory. Both skills ship in one plugin, so the engine is
#   missing only on a host that can't call skills by name.
# - An unfilled arguments placeholder is the test for "not forked". Claude
#   Code fills every one in the body, with nothing when there are no
#   arguments, so the body names the placeholder in words: written as the
#   token, the test would be filled in too and always hold. The Copilot runtime
#   (CLI, and VS Code's Copilot harness) has no context: fork, leaves the
#   placeholder as written, and appends its own `ARGUMENTS:` line after the
#   skill's text. There the engine's snapshot, raw findings, and verifier
#   results would all land in the user's conversation, so one subagent runs
#   the engine and only the report comes back. It still blocks the
#   conversation: nothing on that host runs a skill in the background.
# - The subagent is general-purpose by name: Copilot's `task` agent type is a
#   command runner on a small model.
# - `skill unreachable` covers a host whose subagents get no skill tool.
---

# Code review

ARGUMENTS: $ARGUMENTS

When the line above still ends in the placeholder, a dollar sign followed by the word ARGUMENTS, the host left it unfilled and loaded this skill into the user's conversation. The arguments are then on the last `ARGUMENTS:` line the host gives, else what the user typed after the command, and the review runs *Through a subagent*. Otherwise it runs *Here*.

## Here

Invoke the skill `swe:code-review-core`, by name, with the arguments unchanged, and follow it to the end. Its report, or the message that stops it, is your final message, word for word.

When the skill can't be reached, your whole final message is: `Couldn't reach the skill swe:code-review-core, which runs the review. Check that the swe plugin is installed whole and that this host lets a skill call another by name.`

## Through a subagent

Start one general-purpose subagent in the foreground and wait for its result. Its prompt holds:

- the repository's absolute path, to work from;
- to invoke the skill `swe:code-review-core`, by name, with the arguments unchanged, and follow it to the end;
- that its final message is the review's report, or the message that stopped the review, word for word, or `skill unreachable` when it can't invoke that skill.

Its result is your final message, word for word. Without a subagent tool, or when the result is `skill unreachable`, run the review *Here*.
