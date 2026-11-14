# Review loop

Review the run's work, fix the findings that need no choice from the user, and review again, at most 7 reviews. The review only reports; you make the fixes.

## Run a review

Start one general-purpose subagent on the review model, at the review effort, in the foreground (on Claude Code, `run_in_background: false`), and wait for its result before doing anything else. Its prompt holds:

- the repository's absolute path, to work from;
- to invoke the skill `swe:code-review-core`, by name, and follow it to the end, with these arguments and no target: `--spec <the source's absolute path>` when the source is a file, then `--slice <n>` when the run built one slice of a plan, `--model <name>` when the arguments held `--review-model`, and `--effort <the review effort>`;
- that its final message is the review's report, or the message that stopped the review, word for word.

Without a subagent tool, invoke `swe:code-review-core` yourself, by name, with the same arguments. When it hands its report back, continue here.

The result is one of:

- **A report** (it starts `# Code review:`): go to *After each review*.
- **`nothing to review`**: the loop ends, with nothing to fix.
- **Anything else**, or the skill can't be reached: the loop ends, and what came back is the reason this review did not report. On the first review, no review ran. On a later one, the earlier reviews and their fixes still go in the report.

## The ledger

Keep one entry per confirmed finding across the reviews: its title, its site, its root cause, and what you did with it. A finding in a later review is the **same finding** as an entry when it names the same root cause at the same site, whatever its ID, wording, or line number.

A finding can hold more than one claim: the review merges claims at one site, so a scope-creep finding may also name a defect in the code it calls unrequested, and other sections then point to it with `See <ID>`. Give each claim its own entry and take each through the rules below on its own. The finding's suggested fix answers only one of them.

A finding is **serious** when the review rates it `MAJOR` or `CRITICAL`, or gives its kind as an unmet criterion, and **minor** otherwise. A finding seen again is judged as the latest review rates it.

## After each review

Take each confirmed finding in the report's order and do the first of these that applies:

1. **The same finding as one you deferred or left unfixed**: its entry stays as it is.
2. **The same finding as one you fixed**: the fix didn't hold. Leave the code as it is, and mark the entry unfixed when the finding is serious, noted when it is minor.
3. **This is the last review the limit allows, and the finding is serious**: mark it unfixed, as found by the last review. A fix made now would reach the tree unreviewed.
4. **Its site is in a file from the starting changes that no unit of this run changed**: defer it as in the tree before this run. A file a unit changed is the run's work as a whole, the lines that were there at the start included: a finding anywhere in it goes on to the next rule.
5. **This is the second review or a later one, and the finding is minor**: note it, with the review that found it, and leave the code as it is. A noted entry seen again as minor stays as it is.
6. **Its fix needs the user's choice**: defer it, with the choice in one sentence. A fix needs a choice when:
   - the ways to fix it differ in behavior a user could observe, and neither the source nor the code around it settles which;
   - it would add behavior a user could observe that the source doesn't state, such as a limit, a timeout, a fallback, or a changed name or output, even when that behavior closes the defect;
   - it would contradict a decision or criterion the source states;
   - it is new work the source doesn't describe, or work the source gives to a later slice or step;
   - it would remove code that was in the starting changes, or rewrite it beyond correcting the defect. Code the source doesn't ask for that was there at the start is the user's to keep or drop. A defect inside that code is a separate claim that this bullet doesn't defer: correcting it where it stands goes on through the other bullets, and to rule 7 when none applies.

   A serious finding that only the first two of these would defer is fixed instead, by the fix that adds the least such behavior.
7. **Otherwise fix it yourself**, whatever its severity. The finding's suggested fix is a starting point. Where the repo tests that area, the fix comes with a test that fails without it. A finding's ID is one of the source's labels and stays out of the repo.

When this review led to no fix that is still in the tree, the loop ends. Otherwise run the project's checks, then the next review. A failure your fixes caused is yours to fix; when a fix still fails the checks after three attempts, undo that fix and mark its finding unfixed.

## Record for the report

Keep, for steps 6 and 7: how many reviews reported, how many findings each one confirmed, and how the loop ended, and each ledger entry with its state, the files a fix changed, and the reason it was deferred, noted, or left unfixed.

The loop ended, by the first of these that fits:

- **review <n> did not report: <why>**: a review after the first came back without a report.
- **clean**: the last review confirmed nothing.
- **stopped at the limit**: the last review the limit allows confirmed a finding.
- **nothing left to fix**: every finding the last review confirmed was deferred, noted, or left unfixed.
