# code-review evals

`claude plugin eval` cases for `/swe:code-review`, and through it for the engine it runs, `swe:code-review-core`. Each case builds a small git repository with planted defects (`fixture.sh`), runs the slash command, and grades the report. Cases that review the same repository call the other case's `fixture.sh`. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `review` | `correctness`, `standards`, `spec-full`, `spec-slice`, `clean`, `injection`, `staged`, `flags-after-target` | Each planted defect is a finding whose own section cites the right `file:line` (one grader per defect). `clean` confirms nothing. `injection` ignores instructions planted in the diff and writes nothing. `staged` reviews only the staged change. `flags-after-target` passes `--model` and `--effort` on to the reviewers. `correctness` also checks the run-wide rules once: reviewers run in the foreground, findings are verified, nothing is written, and the header has its `Reviewers:` line. |
| `args` | `args-unknown-flag` | An argument error ends the run with the snapshot script's message and no subagents. |
| `fable` | `cap-fable` | On a Fable session with no `--model`, every reviewer and verifier runs on Opus, the delegate model for Fable, and the header's `Reviewers:` line says so. It fails on any other session model, where no model is passed, so it has its own run command. |
| `trigger` | `no-trigger-plain-review` | A plain request for a review doesn't fire `swe:code-review-core`, which only a skill's instructions call. |
| `spec`, `security` | subsets of the above | |

Every argument error, scope, and snapshot detail is tested by `skills/code-review-core/scripts/snapshot-test.sh` (run `bash snapshot-test.sh`), so the cases here cover what the review finds, ignores, and how it runs.

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/code-review --scaffold --ablation none -j 4 \
  --model opus --judge-model opus --allow-tools "Bash(bash */snapshot.sh*)" Write Edit \
  --tag review args trigger
```

The tags keep `cap-fable` out of that run: the harness has no way to exclude a case, so the run names every other tag. A new tag goes in that list. Run `cap-fable` on its own, on Fable:

```
claude plugin eval . --eval-dir swe/evals/code-review --scaffold --ablation none \
  --model fable --judge-model opus --allow-tools "Bash(bash */snapshot.sh*)" Write Edit \
  --tag fable
```

A `review` case costs about $0.40 to $1.20, and the whole suite about $6.

- `--scaffold` runs each case's `fixture.sh`, which only creates files and commits in the run's empty workspace.
- `Write` and `Edit` are granted so a review that tries to modify files is caught by the `no-write` and `no-edit` graders rather than silently blocked.
