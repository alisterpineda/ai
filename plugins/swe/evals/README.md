# swe evals

`claude plugin eval` cases for `/swe:code-review`. Each case builds a small git repository with planted defects (`fixture.sh`), runs the slash command, and grades the report.

| Tag | Cases | What they check |
|---|---|---|
| `review` | `correctness`, `standards`, `spec-slice`, `spec-full`, `clean`, `injection`, `staged`, `untracked`, `flags-after-target` | Every planted defect is reported at the right `file:line`; the clean diff has no confirmed findings; instructions planted in the diff are ignored; reviewers run in the foreground and every finding is verified; nothing is written. |
| `args` | `args-*`, `flags-after-target` | Each argument error ends the run with the snapshot script's one-line message and no subagents; flags after the target are accepted. |
| `spec`, `security`, `matrix` | subsets of the above | |

## Run

From `plugins/`, not `plugins/swe/`: swe depends on `core`, and the harness loads only plugins inside the directory it is pointed at.

```
cd plugins
claude plugin eval . --eval-dir swe/evals --scaffold --ablation none -j 4 \
  --allow-tools "Bash(bash */snapshot.sh*)" Write Edit
```

Add `--tag args` for the cheap cases (about $0.05 each) or `--tag review` for the full reviews (about $0.40 to $1.50 each). Cases run once by default; pass `--runs 3` before trusting a change to a charter.

- `--scaffold` runs each case's `fixture.sh`, which only creates files and commits in the run's empty workspace.
- `Write` and `Edit` are granted so a review that tries to modify files is caught by the `no-write` and `no-edit` graders rather than silently blocked.
- On Linux the harness needs `bubblewrap` and `socat` to grant `Bash`; without them every case fails before it starts.
- Don't run the harness as root. Its sandbox then makes `$TMPDIR` read-only, so every `Bash` call reports exit code 1, and the only writable place, `/tmp`, is one the Read tool can't open. The `args` cases still pass, but every `review` case ends with the review reporting that it couldn't read its snapshot.
