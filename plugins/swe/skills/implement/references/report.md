# Final report

The report is the run's final message and must stand on its own for someone who did not watch the run. Facts only: what was asked, what was built, what was checked, what is still open. Leave out a section marked *(when …)* when its condition doesn't hold; every other section is always present, and one with nothing to say gets the single word `None`.

```
# Implemented: <title> (<kind>: <ref>)

Spec: <path>[ (written by this run)]
Slice: <n> | <all: n, m, …> | none
Mode: build only | review loop (<k> reviews; ended clean | ended at the review limit | no changes needed | ended on a review failure)[; review model <name>][; review effort <level>]
<Branch: "<name>: created from <base>" | "<name>: switched to existing" | "<name>: created tracking <remote>/<name>" | "<name>: already on it". Leave out when the target named none.>
<Notes: no test infrastructure, a review note such as an unapplied model or effort, or omit.>

## Criteria

| # | Criterion | Status | Evidence |
|---|---|---|---|
| AC1 | <criterion text> | met | `tests/test_x.py::test_name`, `src/x.py:40` |
| AC2 | <criterion text> | verified by inspection | `src/x.py:40-58`: <what was read> |
| AC3 | <criterion text> | unmet | <what was observed> |
| AC4 | <criterion text> | unverifiable | <what would settle it> |

## Review rounds   (when --review)

| Review | Confirmed | Refuted | Fixed | Returned |
|---|---|---|---|---|
| 1 | 4: CO1 <title>, ST1 <title>, … | 2 | all 4 | |
| 2 | 1: CO1 <title> | 0 | 1 | CO1 (from review 1) |
| 3 | 0 | 1 | | |

## Unfixed findings   (when the loop ended at the limit or on a review failure)

<each finding's full text from the last review, as code-review-core reported it>

## Project checks

| Check | Command | Before | After |
|---|---|---|---|
| Typecheck | `<command>` | clean | clean |
| Lint | `<command>` | clean | clean / not configured |
| Tests | `<command>` | 41/42 (1 failing before the run) | 48/49 |

## Answers from the start   (when the up-front questions were asked)

- <question> → <answer>
- <held-back requirement from an outsider> (by <author>) → built | not built

## Cautious readings

- <the ambiguity> → <the reading chosen>, at `<file:line>`

## Untraceable changes   (when build only)

- `path:line-range`: <what it does, and why no criterion covers it>

## Next step

Everything is uncommitted and unstaged. Look over the diff, and commit when you're satisfied.<When build only: add "For an independent review, run /swe:code-review --spec <spec path>[ --slice <n>].">
<When answers from the start changed what was built and the spec is the user's own file: "The spec doesn't record the answers above; fold them in before the next slice.">

<The slice question, when one or more slices ended with every criterion met:>
Mark slice <n>[, <m>, …] done in `<spec path>`? This adds "Done: <YYYY-MM-DD>." to the end of each slice's line.<When the spec is tracked by git: " The spec is tracked, so that becomes an uncommitted change to commit along with the work.">
```

## Rules

- **Criteria** come from the last review's Spec table with `--review`, and from your own verification without it, or when no review produced a Spec table. List them in the spec's order; under a slice, only that slice's; under `--slice all`, every built slice's, grouped by slice.
- A **met** criterion cites a test you read, not only one you ran. **Verified by inspection** cites the code location. **Unmet** describes what was observed, never what was hoped.
- Under `--slice all`, each slice ran its own loop: the Mode line gives each slice's review count and ending, and the Review rounds table restarts its numbering per slice, under a `Slice <n>` row.
- **Before** is the checks' baseline from before the build; a failure there is the project's, not this run's.
- The **slice question** lists only slices whose criteria all ended met. Ask it once, at the end, under `--slice all` as well.
- No prose summary above the header. The title line and the header lines are the whole introduction.
