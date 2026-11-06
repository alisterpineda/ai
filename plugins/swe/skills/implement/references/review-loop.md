# Review loop

Run with `--review`, once per slice: review the slice's changes, fix every confirmed finding, run the project checks, and review again, until a review confirms nothing or the review limit is reached. Every change in the final tree has been through a review.

The **review limit** is 7 reviews per slice. This is the one place that sets it; SKILL.md and the report refer to it by name.

## Calling the review

Invoke the skill `swe:code-review-core` through the Skill tool with these arguments:

```
--spec <spec path> [--slice <n>] [--model <review-model>] [--effort <review-effort>] <start-tree id>
```

- `--slice <n>`: the slice this loop belongs to, when the spec has slices.
- `--model` and `--effort`: the manifest's `review-model:` and `review-effort:` values, left out when they are `inherit`.
- `<start-tree id>`: the tree SKILL.md step 7 recorded, as the review's target. `code-review-core` then reviews every change in the working tree since that tree, untracked files included, and leaves the spec file out by its path. Changes that were in the tree before the run, staged or not, stay out of the review, and so does any part of a file that was already changed.

Follow `code-review-core` to its report; the report is handed back to you, and the loop continues from it. **The review's report is never your final message**, even when it confirms nothing: it is an intermediate result, so don't end your turn on it. Go straight on to *Each review* below, and from there to the next review or to SKILL.md's report. If the Skill tool can't reach it, read `../code-review-core/SKILL.md` from this skill's base directory and follow it with the arguments above as its `ARGUMENTS`, resolving its `scripts/` and `references/` paths against `../code-review-core/`.

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
