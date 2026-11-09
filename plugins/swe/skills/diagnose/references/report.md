# Diagnosis report

The report must stand on its own for someone who didn't watch the run. Facts only: what was reported, what you ran and saw, what you concluded, and how sure you are. A section marked *(when …)* appears only when its condition holds. Inside a group, leave out any section with nothing in it.

```
# Diagnosis: <short title>

Targets: <kind>: <ref>[, <kind>: <ref> …]
Context: "<context>"                        (when the arguments had context)
Tree: unchanged | <scratch dir>/ repro files only | instrumentation added and removed, git diff clean
<Warning: what was left behind, with the file and its remaining diff.>   (when instrumentation or a worktree couldn't be removed)
Not read: <ref>: <error>                    (when a target couldn't be fetched)

## 1. <the root cause, in a few words>

Explains: <the items, by ref, that this cause accounts for>
Outcome: Root cause: confirmed | Root cause: likely | Root cause: hypothesis | Working as intended | Needs information

### Symptom
<what was observed, by whom, where; cite the item each symptom comes from>

### Reproduction
<what you ran and what it showed, observed vs expected; or why it couldn't be reproduced>

### Root cause
<the mechanism, at `file:line`; the introducing commit when found; the evidence behind each claim.
For a hypothesis: each candidate, ranked, with what would confirm or rule it out.
For Working as intended: the spec criterion or design that the code follows.
For Needs information: the fact that is missing and who has it.>

### Scope
<other code paths with the same flaw, at `file:line`>

### Workaround
<what a user can do today>

### Fix options
1. <option>: <what changes, and its trade-off>  ← recommended
2. <option>: …

### Open questions
- <question>: <why it matters>

## 2. …

## Same symptom, different causes        (when items that look alike landed in different groups)

- <ref> and <ref>: <the shared symptom>; causes in groups <n> and <m>

## Candidates                             (when linked items look like the same bug)

- <ref> — <title>: <why it looks related>. Re-run with it as a target to include it.

## Ticket summary                        (when there are ticket targets)

<One block per ticket target, ready to paste as a comment, in plain Markdown: the cause in a sentence or two,
the outcome label, the workaround if any, and the recommended fix. No local paths beyond repo-relative ones,
and nothing from held-back text beyond what the summary needs.>

## Next step

<the hand-off options, below>
```

## Hand-off options

List only the options that fit, numbered, with your recommendation and why:

- **Plan the fix**: `/swe:plan` from the conversation. Fits when at least one group has a root cause and a recommended fix that is ready to build.
- **Update the spec**: add the fix's criteria and a decision to each target spec whose criteria a cause breaks. Fits only when a `spec` target is among the targets, some group departs from it, and it has a list of criteria or requirements to add to.
- **Stop**: the report is the result. This is the recommendation when every group is `Working as intended` or `Needs information`, or when you'd want more evidence before anyone builds a fix.

With more than one group that has a fix, ask which causes to include. By default, that's every group whose outcome is a root cause.

End the message on the question, and wait.
