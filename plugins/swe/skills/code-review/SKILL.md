---
# ── Portable (agentskills.io spec) ──
name: code-review
description: "Review a diff for correctness, the repo's written standards, and conformance to a spec or one of its slices, verify every finding, and report. Report-only. Usage: /swe:code-review [--spec <path>] [--slice <n>] [--model <name>] [--effort <level>] [target]; with no target, reviews the staged changes, or all uncommitted changes if nothing is staged. User-invoked only."
compatibility: "On Claude Code, context: fork runs the review in a background subagent and the report arrives as a notification. Hosts that ignore it run the review in the main conversation. Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extensions ──
# disable-model-invocation blocks auto-invocation; only /swe:code-review works.
# context: fork + background: true run this body in a background subagent, so
# the conversation stays usable during the review. The body only hands off to
# swe:code-review-core, which other skills (a future implement) call directly.
disable-model-invocation: true
argument-hint: "[--spec <path>] [--slice <n>] [--model <name>] [--effort <level>] [target]"
context: fork
background: true
---

# Code review

ARGUMENTS: $ARGUMENTS

Invoke the skill `swe:code-review-core` through the Skill tool, passing the arguments above unchanged, and follow it to the end. Its report, or the message that stops it, is your final message, word for word.

If the Skill tool can't reach it, read `../code-review-core/SKILL.md` from this skill's base directory and follow it, taking the arguments above as its `ARGUMENTS`. Its "skill directory" is then `../code-review-core/`: resolve its `scripts/` and `references/` paths against that directory, not this one.
