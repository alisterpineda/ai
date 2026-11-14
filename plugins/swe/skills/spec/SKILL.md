---
# ── Portable (agentskills.io spec) ──
name: spec
description: "Turn the current conversation into a spec file, under .scratch/ (or an existing, gitignored .local/) unless the repo's instructions name a location: problem, goals, decisions, acceptance criteria, open questions, or the sections of the repo's own spec template. Usage: /swe:spec [context], where context narrows the scope and names the file, or names an existing spec to update. User-invoked only."
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
# - Updating a spec in place is spec's own exception to path.md's "every run
#   writes a new file", which stays right for plan and diagnose. Numbers hold
#   across an update because plans cite criteria by number.
---

# Spec

Synthesize the conversation into a spec file. What the spec needs and the conversation left unsettled, you ask the user in one round; what is still missing after that becomes an open question.

ARGUMENTS: $ARGUMENTS

## 1. Scope

The arguments, if any, are the **context**: free text naming the part of the conversation to spec. With a context, spec only that part. Without one, spec the whole conversation. A context can also name an existing spec to update: that file is then a source alongside the conversation.

Read the conversation's latest **Shared understanding** or **Agreed fix** block first, if it has one; it is your primary source. Fill in detail from the rest of the conversation. Where the conversation changed its mind, the later statement wins.

## 2. Gaps

Work out what each section of the spec will say before writing the file. A **gap** is anything a section needs that the conversation didn't settle. Handle every gap by its kind:

- **A fact you can look up** (the codebase, files, docs): look it up.
- **The user's decision**: ask it.
- **A decision the conversation deferred or declined, or a fact no one in the conversation has**: open question.

Ask every user's-decision gap in one round, then wait for the answers. Number the questions, continuing the conversation's numbering when it has one, and give each its options and a recommendation with its reason:

```
❓ **Q<n> – <short title>**: <the question>

- **(a) <option>.** <what it means>
- **(b) <option>.** <what it means>

➡️ **(a).** <why>
```

An answer becomes a decision. A question the user skips, and a gap their answers open up, becomes an open question: ask one round only. With no user's-decision gaps, go straight to step 3.

## 3. Path

This run is an **update** in two cases, and the path is then that file:

- The context names an existing spec to update.
- This conversation wrote a spec, or worked through one's open questions, and this run's scope is the same as that spec's.

A spec the context names for another purpose, such as a format to follow, is read, and the run writes a new file.

Otherwise read `references/path.md` and follow it, with the kind `spec`.

## 4. Write

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
1. <observable, checkable outcome> <when derived: (D<n>, D<n>), the decisions it restates>

## Open questions
- <question>: <why it matters>
```

- **Decisions** carry the reason the conversation gave. A decision it never justified goes in as stated.
- **Acceptance criteria** are numbered, and each one can be checked on its own. Where the conversation set none, derive them: each restates one or more decisions as an observable outcome. A criterion that needs a value or behavior no decision gives is a gap.
- **Open questions** are decisions or facts still missing. Work the spec implies outside itself, such as another document it now contradicts, goes in the report.
- **Every line traces to the conversation or to an answer from step 2.** Anything you would have to invent is a gap.
- When you name code (modules, files, commands), confirm in the repo that it exists.

On an update, edit the file in place and keep its structure:

- A settled open question leaves Open questions and joins Decisions, and the criteria it yields join Acceptance criteria.
- A reversed decision is rewritten where it stands, with every criterion and Design line that restated it.
- Existing decisions and criteria keep their numbers; new ones take the next number.
- Source gains what the update was built from.

## 5. Report

Reply with the file path, the count of decisions, criteria, and open questions, and any work the spec implies outside itself. If Decisions came out empty, add one line suggesting `core:ideate` to work through the design first.

Done when the file exists, every in-scope decision from the conversation appears in it, and every gap is answered or an open question.

## 6. Later answers

When the user, later in this conversation, settles one of the spec's open questions or reverses one of its decisions, update the file as step 4 describes, then report the new counts.
