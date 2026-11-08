# Hand-off

Carry out the option the user chose, for the causes they chose. The fix counts as agreed because the user chose it, so write the Agreed fix block only after they do.

## Plan the fix

Write an `## Agreed fix` block in the conversation as text, not as a file. `/swe:plan` with no target plans from the latest Agreed fix or Shared understanding block, so it picks the block up from here. The symptoms are already in the report above it, so the block holds only what the plan builds from:

```markdown
## Agreed fix

**Title:** <short title of the fix>

Source: <every target, by ref>

### Non-goals
- <a group or fix option not chosen>

### Decisions
1. <the fix chosen for a cause>: <the root cause at file:line and its outcome label; why this option over the others>

### Acceptance criteria
1. <the fixed behavior, at a seam a test can reach>
```

- **Non-goals**: the groups and fix options not chosen. Leave the section out when there are none.
- **Decisions**: one per chosen cause.
- **Acceptance criteria** describe the fixed behavior at a seam a test can reach: "`parse('')` returns `[]`", never "the bug is fixed". Each group's symptom becomes at least one criterion, and its Scope adds one for each sibling path it names. When a cause is not `confirmed`, its first criterion is a test that reproduces the symptom, so the fix starts by proving the cause.
- A choice the diagnosis didn't make, such as which fix option or which behavior for an edge case, goes in front of the user before the block is written, not into it as a guess or a question.

**Every line traces to the diagnosis.**

After the block, give the command to type, `/swe:plan`, on a line of its own.

## Update the spec

For each chosen cause that breaks a `spec` target's criteria, edit that spec. Change nothing else in it.

- Append the fix's criteria to `## Acceptance criteria`, numbered after the last one.
- Append a decision to `## Decisions`, numbered after the last: `<n>. <the fix chosen>: <the root cause at file:line, its outcome label, and the item refs it explains>`.

A cause that breaks no spec target goes into an Agreed fix block as above, and you say so. When the spec is tracked by git, say that the edit is an uncommitted change for the user to commit. Then give the command to plan the fix, naming the new criteria so the plan covers them and not the whole spec: `/swe:plan <spec path> criteria <the new numbers>`.

## Stop

Write nothing. The report stands as the result.
