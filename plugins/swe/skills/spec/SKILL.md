---
# ── Portable (agentskills.io spec) ──
name: spec
description: "Turn the current conversation into a spec file, under .scratch/ (or an existing, gitignored .local/) unless the repo's instructions name a location: problem, goals, decisions, acceptance criteria, open questions, or the sections of the repo's own spec template. Usage: /swe:spec [context], where context narrows the scope and names the file. User-invoked only."
compatibility: "Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extensions, honored by Claude Code and GitHub Copilot ──
# Blocks auto-invocation; only /swe:spec works.
disable-model-invocation: true
argument-hint: "[context]"

# Maintainer notes (frontmatter never reaches the model):
# - references/path.md has identical copies in plan and diagnose; the repo's
#   check script fails when they differ, so edit all three together.
# - The layout is the default only: /swe:plan, /swe:diagnose, and
#   /swe:code-review read specs of any shape, so a repo template can replace it.
---

# Spec

Synthesize the conversation into a spec file. Everything the spec needs is already in the conversation; whatever is missing becomes an open question.

ARGUMENTS: $ARGUMENTS

## 1. Scope

The arguments, if any, are the **context**: free text naming the part of the conversation to spec. With a context, spec only that part. Without one, spec the whole conversation.

Read the latest **Shared understanding** block first, if the conversation has one; it is your primary source. Fill in detail from the rest of the conversation. Where the conversation changed its mind, the later statement wins.

## 2. Path

Read `references/path.md` and follow it, with the kind `spec`.

## 3. Write

Take the spec's structure from the first source that sets one:

1. The user's request in this conversation.
2. The repository: a spec, RFC, or design-doc template, or a format its `CLAUDE.md`, `AGENTS.md`, or `CONTRIBUTING.md` gives.
3. The user's standing instructions, and other skills in use.
4. Earlier specs: a structure most specs in the spec directory share.
5. The layout below.

A source that sets the structure replaces the layout's sections and their order. The rules after the layout still apply inside it: put each decision, criterion, and open question in the section the source gives it, and mark a section the conversation doesn't fill as open instead of filling it.

```markdown
# <Title>

Source: <what the spec was built from: the conversation, ticket URLs, a file>

## Problem
What is wrong or missing today, and for whom.

## Goals
## Non-goals

## Decisions
1. <decision>: <why>

## Design
<technical detail the conversation settled beyond the decisions: interfaces, schemas, data flow, UI states; leave the section out when it settled none>

## Acceptance criteria
1. <observable, checkable outcome>

## Open questions
- <question>: <why it matters>
```

- **Decisions** carry their reason. A decision the conversation never justified goes in as stated, with an open question asking why.
- **Acceptance criteria** are numbered, and each one can be checked on its own.
- **Every line traces to the conversation.** Anything you would have to invent goes to Open questions.
- When you name code (modules, files, commands), confirm in the repo that it exists.

## 4. Report

Reply with the file path and the count of decisions, criteria, and open questions. If Decisions came out empty, add one line suggesting `core:ideate` to work through the design first.

Done when the file exists, every in-scope decision from the conversation appears in it, and every gap is an open question.
