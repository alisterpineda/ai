# Hand-off

Carry out the option the user chose, for the causes they chose. The Fix plan counts as agreed because the user chose it, so write it only after they do.

## Plan the fix, or write a spec

Write a `## Fix plan` block in the conversation as text, not as a file. `/swe:plan` with no target plans from the latest Fix plan or Shared understanding block, and `/swe:spec` reads the whole conversation, so both pick it up from here.

The block is the spec layout from `/swe:spec`: read `../spec/SKILL.md` from this skill's base directory and use its **Write** section, with the same section names in the same order, one heading level down under `## Fix plan`. The title becomes a `**Title:** <short title of the fix>` line, the `Source:` line stays a line, and each section becomes a `### <name>` heading. What goes in each:

- **Source**: every target, by ref.
- **Problem**: what is broken, for whom: the symptoms, in a few lines. Then, per chosen group, the root cause: the mechanism at `file:line`, and its outcome label.
- **Goals**: the symptoms the fix removes. **Non-goals**: the groups and fix options not chosen.
- **Decisions**: `<the fix chosen for a cause>: <why this option over the others>`.
- **Acceptance criteria** describe the fixed behavior at a seam a test can reach: "`parse('')` returns `[]`", never "the bug is fixed". Each group's symptom becomes at least one criterion, and its Scope adds one for each sibling path it names. When a cause is not `confirmed`, its first criterion is a test that reproduces the symptom, so the fix starts by proving the cause.
- **Open questions**: `None`, normally. A choice the diagnosis didn't make, such as which fix option or which behavior for an edge case, goes in front of the user before the block is written, not into it as a guess or a question.

**Every line traces to the diagnosis.**

After the block, give the command to type, on a line of its own:

- Plan the fix: `/swe:plan`.
- Write a spec: `/swe:spec`, with a short context that names the fix, so the spec covers the Fix plan rather than the whole conversation.

## Update the spec

For each chosen cause that breaks a `spec` target's criteria, edit that spec. Change nothing else in it.

- Append the fix's criteria to `## Acceptance criteria`, numbered after the last one.
- Append a decision to `## Decisions`, numbered after the last: `<n>. <the fix chosen>: <the root cause at file:line, its outcome label, and the item refs it explains>`.

A cause that breaks no spec target goes into a Fix plan as above, and you say so. When the spec is tracked by git, say that the edit is an uncommitted change for the user to commit. Then give the command to plan the fix, naming the new criteria so the plan covers them and not the whole spec: `/swe:plan <spec path> criteria <the new numbers>`.

## Stop

Write nothing. The report stands as the result.
