# Hand-off

Carry out the option the user chose, for the causes they chose. The Fix plan counts as agreed because the user chose it, so write it only after they do.

## Implement now, or write a spec

Write a `## Fix plan` block in the conversation as text, not as a file. `/swe:implement` with no target builds from the latest Fix plan or Shared understanding block, and `/swe:spec` reads the whole conversation, so both pick it up from here.

```
## Fix plan

**Title:** <short title of the fix>
**Source:** <every target, by ref>

**Problem**
<what is broken, for whom: the symptoms, in a few lines>

**Root cause**
<per chosen group: the mechanism at `file:line`, and its outcome label>

**Decisions**
1. <the fix chosen for a cause>: <why this option over the others>

**Acceptance criteria**
1. <observable, checkable outcome>

**Slices**
1. <name>: <what it delivers end to end>. Criteria: <numbers>
```

- **One slice per chosen cause**, in the report's group order. Each slice names the criteria that fix its cause.
- **Acceptance criteria** describe the fixed behavior at a seam a test can reach: "`parse('')` returns `[]`", never "the bug is fixed". Each group's symptom becomes at least one criterion, and its Scope adds one for each sibling path it names.
- When a cause is not `confirmed`, its slice's first criterion is a test that reproduces the symptom, so the fix starts by proving the cause.
- **Every line traces to the diagnosis.** A choice the diagnosis didn't make, such as which fix option or which behavior for an edge case, goes in front of the user before the block is written, not into it as a guess.

After the block, give the command to type, on a line of its own:

- Implement now: `/swe:implement`. Add `--slice all` when there is more than one slice, and suggest `--review` for a fix that touches shared code. `/swe:implement` needs a clean working tree.
- Write a spec: `/swe:spec`, with a short context that names the fix, so the spec covers the Fix plan rather than the whole conversation.

## Update the spec

For each chosen cause that breaks a `spec` target's criteria, edit that spec. Change nothing else in it.

- **With a `## Slices` section**: append the fix's criteria to `## Acceptance criteria`, numbered after the last one. Then append a slice at the end of `## Slices`, numbered after the last: `<n>. Fix <cause in a few words>: <what it delivers>. Criteria: <the new numbers>`. Existing slices, and their `Done:` markers, stay exactly as they are.
- **Without a `## Slices` section**: append the fix's criteria to `## Acceptance criteria` only.
- **In both cases**, append a decision to `## Decisions`, numbered after the last: `<n>. <the fix chosen>: <the root cause at file:line, its outcome label, and the item refs it explains>`.

A cause that breaks no spec target goes into a Fix plan as above, and you say so. When the spec is tracked by git, say that the edit is an uncommitted change for the user to commit. Then give the command to build each new slice, naming it: `/swe:implement --slice <n> <spec path>`. Without `--slice`, `implement` proposes the first unfinished slice, which may be an older one. `--slice` takes one number, so give one command per fix slice.

## Stop

Write nothing. The report stands as the result.
