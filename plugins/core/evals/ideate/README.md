# ideate evals

`claude plugin eval` cases for `/core:ideate`: its trigger, and how an interview ends. Each trigger case is a single prompt (`prompt.md`) and one grader that checks whether the `ideate` skill fired.

| Tag | Cases | What they check |
|---|---|---|
| `trigger` | `trigger-*` | Requests to be grilled, interviewed, stress-tested, or to have holes poked in a plan, design, or decision fire `ideate`. |
| `no-trigger` | `no-trigger-*` | Factual questions, direct action requests, and keyword collisions ("grill chicken", "mock job interview", "grill me on exam topics") don't fire it. |
| `borderline` | `borderline-*` | Requests near the boundary, such as a decision doc or a devil's advocate take, that are better answered directly. Expected not to fire, but a miss here is a judgment call rather than a bug. |
| `ending` | `ending-waiting-on-fact` | A resumed interview (`history.jsonl`) whose last answers leave one decision waiting on an outside fact. The Shared understanding block lists that decision under Open as waiting on that fact, and decides nothing on the model's own. The prompt reads as a stop, so other Open items may appear marked not reached; none may claim to wait on something the user could answer. Its prompt asks for the skill by name, since the history doesn't load it, and an `ideate-fired` grader confirms the skill's current text was in play. |
| `hard` | subsets of the above | |

Cases run 3 times each.

## Run

```
cd plugins
claude plugin eval . --eval-dir core/evals/ideate --ablation none \
  --model opus --judge-model opus --tag trigger --tag no-trigger
```

Add `--tag borderline` to include the borderline cases. Swap the tags for `--tag ending` to run the ending case alone; it costs about $0.10 a run.
