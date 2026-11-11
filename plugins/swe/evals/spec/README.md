# spec evals

`claude plugin eval` cases for `/swe:spec`. Each case's `fixture.sh` sources `local.sh`, which builds the plan suite's `tally` repository (`plan/tally.sh`) plus a `.local/` holding one file and no `.scratch/`, then adds the case's own files and commits. Each case's `history.jsonl` resumes the same short design conversation, which settled a `top_words` helper but never said what a negative `n` does. The `path` cases' copies add one exchange that settles it and tells the run to ask nothing further, so the run goes straight to writing; `gaps-ask` keeps the conversation without it. The harness reads a history file only from inside its case directory, so the two `path` copies stay identical by hand. The run is the bare slash command, once, with no one to answer a question, and the graders read the trace and the final workspace. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `path` | `path-local` | The repo's own `.gitignore` ignores `.local/`. The spec is written to `.local/YYYYMMDD-<slug>-spec.md`, no `.scratch/` is created, and no `.gitignore` is added inside `.local/`. `no-scratch` checks for `.scratch/.gitignore`, which the path rule writes when it sets up a `.scratch/` that git doesn't already ignore, because `file_exists` sees only files, never a directory. |
| `path` | `path-local-tracked` | `.local/` is committed and not ignored, so it is a project directory, not scratch. The spec is written to `.scratch/YYYYMMDD-<slug>-spec.md`, and nothing is written into `.local/`, `.gitignore` included. |
| `gaps` | `gaps-ask` | The conversation leaves a gap that is the user's decision. The run asks it as a numbered question with options and a recommendation, and writes no file before the answer. `asks` matches the question template's fixed marks, not its wording. |

A repo with neither directory is covered by `plan`'s `plan-shape`, which checks the plan lands in `.scratch/`.

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/spec --scaffold --ablation none -j 3 \
  --model opus --judge-model opus --allow-tools Bash Write Edit
```

- `Bash`, `Write`, and `Edit` are granted so a run that writes to the wrong directory, by any tool, leaves the file for the graders to catch rather than being blocked.
- The cases are cheap: at most one file written each, no subagents, about $0.18 a run.
