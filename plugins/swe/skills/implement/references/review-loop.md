# Review loop

Run with `--review`, once per slice: review the slice's changes, fix every confirmed finding, run the project checks, and review again, until a review confirms nothing or the review limit is reached. Every change in the final tree has been through a review.

The **review limit** is 7 reviews per slice. This is the one place that sets it; SKILL.md and the report refer to it by name.

## Calling the review

Each review is `swe:code-review-core`, run in a subagent so that its working (the core's instructions, the reviewers' raw findings, the verifiers' verdicts) stays out of this conversation and only its report comes back. Its arguments:

```
--spec <spec path> [--slice <n>] [--model <review-model>] [--effort <review-effort>] <start-tree id>
```

- `--slice <n>`: the slice this loop belongs to, when the spec has slices.
- `--model` and `--effort`: the manifest's `review-model:` and `review-effort:` values, left out when they are `inherit`. They set the reviewers' and verifiers' model and effort; the subagent that runs the review keeps the host's default.
- `<start-tree id>`: the tree SKILL.md step 7 recorded, as the review's target. `code-review-core` then reviews every change in the working tree since that tree, untracked files included, and leaves the spec file out by its path. Changes that were in the tree before the run, staged or not, stay out of the review, and so does any part of a file that was already changed.

**Start the review.** Start one general-purpose subagent with the host's subagent tool (Agent on Claude Code; `runSubagent` or `task` on GitHub Copilot). Its prompt contains:

1. The session's working directory, as an absolute path, as the directory it works from: the spec path in the arguments is relative to it, and `code-review-core` runs from it.
2. To invoke the skill `swe:code-review-core` through the Skill tool with exactly the arguments above, and follow it to the end. If the Skill tool can't reach it, to read `<absolute path of this skill's ../code-review-core/SKILL.md>` and follow it with those arguments as its `ARGUMENTS`, resolving its `scripts/` and `references/` paths against that directory.
3. That its final message is the core's report, or the message that stopped the core, word for word, with nothing added.

**Wait for the report.** When the tool hands the result back, go on. When it returns only a handle and the result will arrive later as a notification, end your turn and wait for it. Until it arrives, edit nothing in the tree and start no other step of the run. If the user writes in the meantime, answer, say the review is still running and the run continues when it reports, and keep waiting.

**The review's report is never your final message**, even when it confirms nothing: it is an intermediate result. Go straight on to *Each review* below, and from there to the next review or to SKILL.md's report.

**Fallback.** When the host has no subagent tool, or the subagent ends without the core's report or stop message, run the review yourself, inline: invoke `swe:code-review-core` through the Skill tool with the arguments above, or, if the Skill tool can't reach it, read `../code-review-core/SKILL.md` from this skill's base directory and follow it as above. Its report is handed back to you, and the rule above applies: don't end your turn on it. Note the fallback in the report.

If the review stops instead of reporting, the loop ends there; record its message as the review's result and go to the report:

- **"Nothing to review"** on the first review: the build changed nothing, because the slice was already done. The loop ends with **no changes needed**.
- **Anything else** (an argument error, or a failure): the loop ends on a **review failure**.

Either way, when no review produced a Spec table, SKILL.md step 9 has you verify the criteria yourself.

Under `--slice all`, the starting tree comes from before the first slice, so later reviews read the earlier slices' changes too. The Spec axis counts another slice's criteria as delivered early, not as scope creep, and code an earlier loop left clean seldom yields new findings.

## The ledger

Keep a ledger across the loop's reviews: one entry per confirmed finding, holding its title, location, root cause, and how many times you have fixed it. A finding in a later review is the **same finding** when it names the same root cause at the same site, even when its ID, wording, or line number changed.

## Each review

1. **Zero confirmed findings**: the loop ends clean.
2. **The last review the limit allows**: the loop ends at the limit. Record its confirmed findings as unfixed, with their full text, and fix none of them: a fix after the last review would reach the tree unreviewed.
3. **Otherwise**, for each confirmed finding, in the report's order:
   - **Fixed twice already** (it came back after two fixes): this is a blocker. Fixes that keep undoing each other, or two requirements pulling opposite ways, are a choice the spec doesn't settle. Ask the user, giving the finding, both earlier fixes, and the options you see; apply their answer.
   - **Conflicts with the spec**: a fix would contradict a decision or criterion the spec states. This is a blocker; ask the user with the finding, the spec line, and the options.
   - **Otherwise**, fix it, whatever its severity: code smells and MINOR findings included. Use the finding's suggested fix as a starting point, not a script. Where the fix changes behavior a test can see, follow test-first: a failing test that shows the defect, then the fix.

   Record each fix in the ledger. Every confirmed finding gets fixed or goes to the user; none is declined.
4. **Run the project checks** and bring them back to the baseline or better (SKILL.md step 8, Project checks), then start the next review.

Collect the blocker questions of one review into a single message rather than asking one at a time, and wait for the answers before fixing the rest.

## Recording each review

For the report, record per review: the number of confirmed and refuted findings, each confirmed finding's ID and title, which ones returned from an earlier review, and what you fixed. Keep the last review's Spec table: its criterion statuses and evidence are the report's Criteria table.

Done when the loop ended clean, at the limit, with no changes needed, or on a review failure, with every review recorded.
