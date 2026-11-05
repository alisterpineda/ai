# ideate evals

`claude plugin eval` cases for `/core:ideate`'s trigger. Each case is a single prompt (`prompt.md`) and one grader that checks whether the `ideate` skill fired.

| Tag | Cases | What they check |
|---|---|---|
| `trigger` | `trigger-*` | Requests to be grilled, interviewed, stress-tested, or to have holes poked in a plan, design, or decision fire `ideate`. |
| `no-trigger` | `no-trigger-*` | Factual questions, direct action requests, and keyword collisions ("grill chicken", "mock job interview", "grill me on exam topics") don't fire it. |
| `borderline` | `borderline-*` | Requests near the boundary, such as a decision doc or a devil's advocate take, that are better answered directly. Expected not to fire, but a miss here is a judgment call rather than a bug. |
| `hard` | subsets of the above | |

Cases run 3 times each.

## Run

```
claude plugin eval plugins/core --eval-dir evals/ideate --ablation none --tag trigger --tag no-trigger
```

Add `--tag borderline` to include the borderline cases. Drop `--eval-dir` to run every core skill's suite.
