---
# ── Portable (agentskills.io spec) ──
name: spec
description: "Turn the current conversation into a spec file, under .scratch/ unless the repo's instructions name a location: problem, goals, decisions, acceptance criteria, open questions, optional slices. Usage: /swe:spec [context], where context narrows the scope and names the file. User-invoked only."
compatibility: "Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extensions, honored by Claude Code and GitHub Copilot ──
# Blocks auto-invocation; only /swe:spec works.
disable-model-invocation: true
argument-hint: "[context]"
---

# Spec

Synthesize the conversation into a spec file. Everything the spec needs is already in the conversation; whatever is missing becomes an open question.

ARGUMENTS: $ARGUMENTS

## 1. Scope

The arguments, if any, are the **context**: free text naming the part of the conversation to spec. With a context, spec only that part. Without one, spec the whole conversation.

Read the latest **Shared understanding** block first, if the conversation has one; it is your primary source. Fill in detail from the rest of the conversation. Where the conversation changed its mind, the later statement wins.

## 2. Path

These rules, and the layout in step 3, are the swe plugin's one source for where a spec goes and what it looks like: `/swe:implement` writes its specs by them, and `/swe:diagnose`'s Fix plan follows the layout.

- **Directory**: the spec location named in the repo's `CLAUDE.md` or `AGENTS.md`, if any. Otherwise `.scratch/` at the git repo root, or in the current directory outside a repo.
- **The `.scratch/` directory**: before anything is written into it, make sure `.scratch/` exists and contains a `.gitignore` whose content is `*`, creating either as needed. Nothing written there then shows in `git status`, a diff, or a review. Every swe skill that writes to `.scratch/` follows this rule.
- **Filename**: `YYYYMMDD-<slug>-spec.md`, with today's date. The slug is two to five kebab-case words, taken from the context or from the subject.
- **Every run writes a new file.** If the name is taken, append `-2`, `-3`, and so on before `.md`.

## 3. Write

Use these sections, in this order:

```markdown
# <Title>

Source: <what the spec was built from: the conversation, ticket URLs, a file>

## Problem
What is wrong or missing today, and for whom.

## Goals
## Non-goals

## Decisions
1. <decision>: <why>

## Acceptance criteria
1. <observable, checkable outcome>

## Open questions
- <question>: <why it matters>

## Slices
1. <name>: <what it delivers end to end>. Criteria: <numbers>
```

- **Decisions** carry their reason. A decision the conversation never justified goes in as stated, with an open question asking why.
- **Acceptance criteria** are numbered, and each one can be checked on its own.
- **Slices** appear only when the work won't fit in one agent session. Each is a vertical chunk that satisfies whole criteria.
- **Every line traces to the conversation.** Anything you would have to invent goes to Open questions.
- When you name code (modules, files, commands), confirm in the repo that it exists.

## 4. Report

Reply with the file path and the count of decisions, criteria, and open questions. If Decisions came out empty, add one line suggesting `core:ideate` to work through the design first.

Done when the file exists, every in-scope decision from the conversation appears in it, and every gap is an open question.
