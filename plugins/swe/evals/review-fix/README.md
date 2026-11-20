# review-fix evals

`claude plugin eval` cases for `/swe:review-fix`. Each case's `fixture.sh` sources the plan suite's `tally.sh`, which builds a small Python repository (`tally`, standard library only, tests run with `make test`). The run is the slash command, once, and the graders read the trace, the final message, and the files it leaves. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `review` | `fix` | The one full run. A committed repository holds one uncommitted edit to `tally/counter.py`: a planted `distinct_words` that counts every word, though its docstring promises distinct words ignoring case. The run fixes it: the planted line is gone while `distinct_words` itself stays. A second review runs, every review is `swe:code-review-core` in a subagent called with `--uncommitted`, and exactly one, the first, is called without `--serious-only`. The report starts with the `Reviewed:` line and its `Review:` line counts at least one finding fixed. Nothing is staged, committed, stashed, reset, or restored through git. |
| `args`, `quick` | `args-unknown-flag` | `--fix` stops the run with the flags it takes, before any edit or subagent. |
| `args`, `quick` | `clean-tree` | A clean tree stops the run with `Nothing to review`, before any edit or subagent. |

The loop's rules are `/swe:implement`'s, from a copy of the same reference file, and that suite's review cases cover the rest of them: run its `review-fix` and `review-loop` cases too after a change to `references/review-loop.md`. `--spec`, `--slice`, and the review flags have no case here: each would cost a full review loop to check that a flag reaches the engine, which `implement`'s `review-flags` and the `code-review` suite's spec cases already check on the same wording.

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/review-fix --scaffold --ablation none -j 3 \
  --model opus --judge-model opus --allow-tools Bash Write Edit
```

Add `--tag quick` for the two cases that stop before any review.

- `Bash` is granted unrestricted because the run runs the project's checks and the review runs its snapshot script. The `no-git-writes` grader in `fix` catches a git write in the session's own calls.
- `fix` runs up to seven reviews, so it is the slow, costly case, about $1 a run.
