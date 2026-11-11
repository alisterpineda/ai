# commit-message evals

`claude plugin eval` cases for `swe:commit-message`. Each case's `fixture.sh` sources `shop.sh`, which commits a small cart library. Eval runs switch off git hooks and graders can't run commands, so a commit is graded from two places: its title from the reflog (`.git/logs/HEAD`), and what was staged and the message body from the run's own `git add` and `git commit` inputs. A run that stages with `git commit <path>` instead of `git add` fails `stages-task-file`. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `stage`, `trigger` | `stage-task-files` | The working tree holds the user's own changes (a localhost tweak in `config/settings.py`, an untracked `notes.txt`). The skill fires, `src/cart.py` is staged and neither of the user's files is staged or committed, nothing is staged with `git add .`, `-A`, `--all`, `-u`, or `git commit -a`, and the title starts with a capital letter, is under 80 characters, and has no type prefix and no trailing period. |
| `stage` | `commit-staged-index` | The user staged their own change to `src/cart.py` and left a localhost tweak in `config/settings.py` unstaged; the conversation changed nothing. A commit is made, and no `git add`, `rm`, `reset`, `restore`, or `stash` runs, nor `git commit` with `-a`, `--all`, `--include`, or `--only`: the index is committed as it is. |
| `stage` | `split-concerns` | Two independent changes asked for in one prompt: no `git add` or `git commit` runs, and the final message proposes one commit per change with its files and waits for the user. |
| `message` | `body-omitted` | A typo fix is committed with a title-only message: no `- ` bullet in the `git commit` input. Trailers such as `Co-Authored-By` don't count as a body. |
| `message` | `plan-labels` | The prompt asks for step 3 of a plan in the gitignored `.scratch/`, which sits under "Milestone 2". A commit is made, and the `command` of no `git commit` call contains "Milestone" or "step 3": no committed file explains those labels. The match stops at the end of `command`, so a Bash `description` that names the step doesn't count. |
| `format` | `history-convention` | The last five commits use Conventional Commits prefixes, which nothing in the repo writes down: the run's commit title starts with `feat:`. The fixture empties the reflog, so it holds only the run's commit. |
| `trigger` | `trigger-write-message` | Asking what a good commit message would be for the staged change fires the skill. Runs 3 times. |

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/commit-message --scaffold --ablation none -j 4 \
  --model opus --judge-model opus --allow-tools Bash Write Edit
```

- `Bash` is granted unrestricted because the commit runs through a heredoc with command substitution, which narrower `Bash(git *)` grants don't cover.
- A case costs about $0.12 to $0.20 a run, and the whole suite about $1.30.
