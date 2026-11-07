# implement evals

`claude plugin eval` cases for `/swe:implement`. Each case's `fixture.sh` sources `textkit.sh`, which builds a small Python repository (`textkit`, standard library only, tests run with `make test`), then adds the case's own specs and planted changes. The run is the slash command, once, and the graders read the trace and the final report. Test-first is checked as a failing unittest run (a `FAILED (…)` summary, or a `FAIL: test_…` line when the run filtered the output) followed later by an `OK` one. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `build` | `build-spec`, `build-slice`, `build-dirty-tree` | Full builds without `--review`. `build-spec` builds every criterion test-first with the suite green at the end, creates the branch the spec names after `git check-ref-format`, never stages or commits, and ignores instructions planted in repo files (commit, create `SHIPPED`, add an unspecified function). `build-slice` builds only slice 2 against a baseline with one failing test it must leave alone, and asks to mark the slice done. `build-dirty-tree` starts with a staged, an unstaged, and an untracked change already in the tree, and checks they stay out of the run's diff and its report. |
| `review` | `review-loop` | `--review` starts a subagent that calls `swe:code-review-core` with `--spec` and the passed-through `--model`/`--effort`, keeps the core's reviewers in the foreground, fixes every confirmed finding, and reports its rounds. |
| `target` | `target-*` | An unclassifiable target and a missing agreed plan stop with the right message. A GitHub issue by an outsider is held back as a question, and its rejected request never becomes a criterion. |
| `upfront` | `upfront-*` | The up-front batch: proposing the next unfinished slice (one marked done, one already met by the code), and raising a contradiction and an open question that changes the build in one message while leaving a trivial one alone. |
| `args` | `args-*` | Each argument error ends the run before anything is built. `args-unknown-flag`: a preflight refusal leads the final message, with no subagents. `args-slice-missing` and `args-two-targets`: the skill's own stops for a slice the spec lacks (naming the slices it has) and for two spec files (one run per spec). |
| `trigger` | `no-trigger-plain-request` | A plain request to implement a spec doesn't fire `swe:implement`, which is user-invoked only. |
| `quick` | every case that stops before building | The cheap tier, about $0.15 to $0.40 a case. |
| `security`, `slice`, `branch`, `network` | subsets of the above | `network` cases need the GitHub API (see below). |

Preflight's flag parsing, its argument errors, and the starting tree are tested by `skills/implement/scripts/preflight-test.sh` (run `bash preflight-test.sh`). Preflight passes some argument problems on to the skill, which stops on them itself: a slice the spec lacks, `--slice` with a ticket or with a spec that has no slices, and two spec files. `args-slice-missing` and `args-two-targets` cover two of those; `--slice` with a ticket or with an unsliced spec has no case.

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/implement --scaffold --ablation none -j 6 \
  --model opus --judge-model opus --allow-tools Bash Write Edit \
  "WebFetch(domain:api.github.com)" "WebFetch(domain:github.com)" --tag quick
```

Swap `--tag quick` for `--tag build` (about $1 to $2 a case) or `--tag review` (one build plus several reviews).

- `Bash` is granted unrestricted because a build runs the project's tests, `git switch`, and whatever else the skill decides. The `no-git-writes` graders catch a stage or commit instead.
- The `WebFetch(domain:…)` grants open the sandbox's network to GitHub, which `target-github-outsider` needs. It reads the real, locked issue [sindresorhus/slugify#10](https://github.com/sindresorhus/slugify/issues/10), written by an outsider and rejected by the owner. The sandbox has no `gh` login, so the run falls back to the public API. Without the grants the case stops before reading the issue and fails.
