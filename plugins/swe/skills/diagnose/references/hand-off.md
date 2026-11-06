# Hand-off

Carry out the option the user chose, for the causes they chose. The Fix plan counts as agreed because the user chose it, so write it only after they do.

## Implement now, or write a spec

Write a `## Fix plan` block in the conversation as text, not as a file. `/swe:implement` with no target builds from the latest Fix plan or Shared understanding block, and `/swe:spec` reads the whole conversation, so both pick it up from here.

The block is the spec layout from `/swe:spec`: read `../spec/SKILL.md` from this skill's base directory and use its **Write** section, with the same section names in the same order, one heading level down under `## Fix plan`. The title becomes a `**Title:** <short title of the fix>` line, the `Source:` line stays a line, and each section becomes a `### <name>` heading. What goes in each:

- **Source**: every target, by ref.
- **Problem**: what is broken, for whom: the symptoms, in a few lines. Then, per chosen group, the root cause: the mechanism at `file:line`, and its outcome label.
- **Goals**: the symptoms the fix removes. **Non-goals**: the groups and fix options not chosen.
- **Decisions**: `<the fix chosen for a cause>: <why this option over the others>`.
- **Acceptance criteria** describe the fixed behavior at a seam a test can reach: "`parse('')` returns `[]`", never "the bug is fixed". Each group's symptom becomes at least one criterion, and its Scope adds one for each sibling path it names. When a cause is not `confirmed`, its slice's first criterion is a test that reproduces the symptom, so the fix starts by proving the cause.
- **Open questions**: `None`, normally. A choice the diagnosis didn't make, such as which fix option or which behavior for an edge case, goes in front of the user before the block is written, not into it as a guess or a question.
- **Slices**: one per chosen cause, in the report's group order, each naming the criteria that fix its cause.

**Every line traces to the diagnosis.**

After the block, give the command to type, on a line of its own:

- Implement now: `/swe:implement`. Add `--slice all` when there is more than one slice, and suggest `--review` for a fix that touches shared code.
- Write a spec: `/swe:spec`, with a short context that names the fix, so the spec covers the Fix plan rather than the whole conversation.

## Update the spec

For each chosen cause that breaks a `spec` target's criteria, edit that spec. Change nothing else in it.

- **With a `## Slices` section**: append the fix's criteria to `## Acceptance criteria`, numbered after the last one. Then append a slice at the end of `## Slices`, numbered after the last: `<n>. Fix <cause in a few words>: <what it delivers>. Criteria: <the new numbers>`. Existing slices, and their `Done:` markers, stay exactly as they are.
- **Without a `## Slices` section**: append the fix's criteria to `## Acceptance criteria` only.
- **In both cases**, append a decision to `## Decisions`, numbered after the last: `<n>. <the fix chosen>: <the root cause at file:line, its outcome label, and the item refs it explains>`.

A cause that breaks no spec target goes into a Fix plan as above, and you say so. When the spec is tracked by git, say that the edit is an uncommitted change for the user to commit. Then give the command to build the new slices:

- When every slice before the new ones is marked `Done:`, the new slices are all that's left: `/swe:implement --slice all <spec path>`.
- Otherwise, one command per new slice, naming it: `/swe:implement --slice <n> <spec path>`. Without `--slice`, `implement` proposes the first unfinished slice, which may be an older one, and `--slice all` would build the older unfinished ones too.

## Stop

Write nothing. The report stands as the result.
