# code-review evals

`claude plugin eval` cases for `/swe:code-review`, which also exercise `code-review-core` behind it. Each case builds a small git repository with planted defects (`fixture.sh`), runs the slash command, and grades the report. Cases that review the same repository call the other case's `fixture.sh` rather than copying it.

| Tag | Cases | What they check |
|---|---|---|
| `review` | `correctness`, `standards`, `spec-full`, `spec-slice`, `clean`, `injection`, `staged`, `flags-after-target` | Each planted defect is a finding whose own section cites the right `file:line` (one grader per defect). `clean` confirms nothing. `injection` ignores instructions planted in the diff and writes nothing. `staged` reviews only the staged change. `flags-after-target` passes `--model` and `--effort` on to the reviewers. `correctness` also checks the run-wide rules once: reviewers run in the foreground, findings are verified, and nothing is written. |
| `args` | `args-unknown-flag` | An argument error ends the run with the snapshot script's message and no subagents. |
| `trigger` | `no-trigger-plain-review` | A plain request to review a commit is handled directly, without firing `code-review-core`, whose description reserves it for skills that name it. Runs 3 times. |
| `spec`, `security` | subsets of the above | |

## What belongs here

Every argument error, scope, and snapshot detail is tested deterministically by `skills/code-review-core/scripts/snapshot-test.sh` (run `bash snapshot-test.sh`). A case here checks only what needs a model: what the review finds, what it ignores, and how it runs. A new case needs a reason that no existing case covers. Give it a grader for each thing it exists to check plus the `report` grader, and leave the run-wide rules to `correctness`.

## Run

From `plugins/`, not `plugins/swe/`: swe depends on `core`, and the harness loads only plugins inside the directory it is pointed at. Point `--eval-dir` at `swe/evals` instead to run every swe skill's suite.

```
cd plugins
claude plugin eval . --eval-dir swe/evals/code-review --scaffold --ablation none -j 4 \
  --allow-tools "Bash(bash */snapshot.sh*)" Write Edit
```

A `review` case costs about $0.40 to $1.20, and the whole suite about $6. Cases run once by default; pass `--runs 3` before trusting a change to a charter.

- `--scaffold` runs each case's `fixture.sh`, which only creates files and commits in the run's empty workspace.
- `Write` and `Edit` are granted so a review that tries to modify files is caught by the `no-write` and `no-edit` graders rather than silently blocked.
- On Linux the harness needs `bubblewrap` and `socat` to grant `Bash`; without them every case fails before it starts.
- Don't run the harness as root. Its sandbox then makes `$TMPDIR` read-only, so every `Bash` call reports exit code 1, and the only writable place, `/tmp`, is one the Read tool can't open. The `args` case still passes, but every `review` case ends with the review reporting that it couldn't read its snapshot.
