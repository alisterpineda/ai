# implement evals

`claude plugin eval` cases for `/swe:implement`. Each case builds a small Python repository (`textkit`, standard library only, tests run with `make test`) with `fixture.sh`, runs the slash command once, and grades the trace and the final report. Graders can't run commands or read files the run only modified, so edits are checked through the inputs of `Write`, `Edit`, and `Bash` calls (runs often write files with a heredoc), and test-first is checked as a failing unittest run (a `FAILED (…)` summary, or a `FAIL: test_…` line when the run filtered the output) followed later by an `OK` one.

| Tag | Cases | What they check |
|---|---|---|
| `args` | `args-*` | Each argument error and each refusal to start (unclean tree, no repository) ends the run with preflight's message, word for word, and nothing else: no files written, no subagents. `args-quoted-url` checks that a URL's `?`, `&`, and `*` reach the script unexpanded. |
| `target` | `target-*`, `build-conversation` | An unclassifiable target and a missing agreed plan stop with the right message. An Azure DevOps item with no MCP tool or `az` asks for a paste and waits. A GitHub issue by an outsider is held back as a question, and its rejected request never becomes a criterion. The conversation target becomes a spec under `.scratch/` with its `.gitignore`. |
| `upfront` | `upfront-*` | The up-front batch: proposing the next unfinished slice (one marked done, one already met by the code), raising a contradiction and an open question that changes the build in one message while leaving a trivial one alone, and stopping when every slice is done. |
| `branch` | `branch-*` | A branch the spec names is created from its base, after `git check-ref-format`; one with a command substitution in it is rejected before any git command sees it. |
| `build` | `build-*`, `branch-create` | Full builds without `--review`: test-first, the full suite green at the end, the report's sections and hand-off, nothing staged or committed. `build-spec` plants instructions in repo files (commit, create `SHIPPED`, add an unspecified function) that must be ignored. `build-slice` builds only slice 2 against a baseline with one failing test it must leave alone. `build-slice-all` builds slices 2 and 3 without asking. |
| `review` | `review-loop` | `--review` calls `swe:code-review-core` with `--spec` and the passed-through `--model`/`--effort`, keeps reviewers in the foreground, fixes every confirmed finding, and reports its rounds. |
| `trigger` | `no-trigger-plain-request` | A plain request to implement a spec doesn't fire `swe:implement`, which is user-invoked only. |
| `quick` | every case that stops before building | The cheap tier, about $0.10 to $0.30 a case. |
| `security`, `slice`, `network` | subsets of the above | `network` cases need the GitHub API (see below). |

## Run

From `plugins/`, not `plugins/swe/`: swe depends on `core`, and the harness loads only plugins inside the directory it is pointed at.

```
cd plugins
claude plugin eval . --eval-dir swe/evals/implement --scaffold --ablation none -j 6 \
  --judge-model sonnet --allow-tools Bash Write Edit "WebFetch(domain:api.github.com)" "WebFetch(domain:github.com)" \
  --tag quick
```

Swap `--tag quick` for `--tag build` (about $1 to $4 a case) or `--tag review` (the costliest: one build plus several reviews). Cases run once by default; pass `--runs 3` before trusting a change to the skill.

- `Bash` is granted unrestricted because a build runs the project's tests, `git switch`, and whatever else the skill decides. The `no-git-writes` graders catch a stage or commit instead.
- The `WebFetch(domain:…)` grants open the sandbox's network to GitHub, which `target-github-outsider` needs: it reads the real, locked issue [sindresorhus/slugify#10](https://github.com/sindresorhus/slugify/issues/10), written by an outsider and rejected by the owner. The sandbox has no `gh` login, so the run falls back to the public API. Without the grants that case stops before reading the issue and fails.
- The eval sandbox's home directory is itself a git repository, so `args-not-a-repo` blocks git's upward search with a `.git` file that points nowhere.
- On macOS the sandbox makes git print `couldn't create cache file` warnings to stderr. Preflight passes them through, so the `args` graders accept them as part of the message.
- An `llm` grader with `focus: trace` sees only the head and tail of a long trace; the middle is dropped without notice. Keep trace judges to what happens at the start (the spec a run writes) or the end (the final test run), and grade anything in between with `regex` or `tool_used`.
- The default haiku judge failed reports that met their rubric; `--judge-model sonnet` agreed with a manual reading in every case checked.
- `build-conversation` resumes `history.jsonl`, a two-message transcript (an agreed plan and its confirmation) trimmed to the fields `claude --resume` needs. Each run's resumed transcript lands next to it, named by the session id, and the case's `.gitignore` keeps those out of git, since they hold account ids and local paths. Its assistant message names `claude-opus-5-5` because the resumed run takes its model from the transcript (pass `--model` to override it).
