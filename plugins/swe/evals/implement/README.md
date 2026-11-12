# implement evals

`claude plugin eval` cases for `/swe:implement`. Each case's `fixture.sh` sources the plan suite's `tally.sh`, which builds a small Python repository (`tally`, standard library only, tests run with `make test`) and defines the settled top-words spec. The run is the slash command, once, and the graders read the trace, the final message, and the files it leaves. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `review`, `build` | `review-loop` | The one full run: build the spec, then review and fix. The review is `swe:code-review-core` in 1 to 3 subagents, given the spec, none of them or of the reviewers in the background. The run ends on implement's own report, with its `Review:` line, not on the review's. An uncommitted `tally/stats.py` with a planted divide-by-zero, which no unit touches, is deferred as in the tree before the run and left as it was. Nothing is staged or committed. |
| `review`, `build` | `review-fix` | The fix-and-review-again path. An uncommitted edit to `tally/counter.py`, the file the build changes, holds a planted `distinct_words` that counts every word. The run changed that file, so the finding is its to fix: the planted line is gone while `distinct_words` itself stays (the spec doesn't ask for it, but removing the user's code is their choice), a second review runs, and the `Review:` line counts at least one finding fixed. |
| `build` | `no-review` | `--no-review` builds the spec, starts no review, and hands over the `/swe:code-review` command. |
| `args`, `quick` | `args-unknown-flag` | `--review`, the removed implement's flag, stops the run with the two flags it takes, before any edit or subagent. |

The fix rule's judgment (which findings need the user's choice) has no case: the findings a review confirms on code the run has just written vary from run to run, so a grader has nothing fixed to check.

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/implement --scaffold --ablation none -j 3 \
  --model opus --judge-model opus --allow-tools Bash Write Edit
```

Add `--tag quick` for the case that stops before building.

- `Bash` is granted unrestricted because building runs the project's checks and the review runs its snapshot script. The `no-git-writes` grader catches a stage or commit instead.
- `review-loop` and `review-fix` each run a build and up to three reviews, so they are the slow, costly cases, about $1 to $2 a run.
