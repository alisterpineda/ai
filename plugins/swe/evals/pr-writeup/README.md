# pr-writeup evals

`claude plugin eval` cases for `swe:pr-writeup`. Each fixture sources `../commit-message/shop.sh` for its `main` branch, then builds a feature branch on top; the two trigger cases reuse `net-result`'s. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `result`, `trigger` | `net-result` | A casual "what should the PR say" fires the skill. The branch adds a function, renames it, and adds then removes a debug print: the run gives a title and a codeblock with `## Summary` and `## Changes`, the title and description cover only the net new `apply_discount` and never mention the old name, the rename, the debug print, or commits (a note to the user outside them may), and one concern gets 1 to 3 bullets. |
| `format` | `pr-template` | The repo's `.github/pull_request_template.md` has What, Why, How to test, and Checklist sections: the description uses those, in order, keeps the checklist, and has no `## Summary` or `## Changes`. |
| `trigger` | `trigger-open-pr` | "Open a PR for this branch" fires the skill, and the run gives a title and description to use without claiming it opened a PR or pushed. The fixture has no remote. |
| `no-trigger` | `no-trigger-summarize-pr` | Asking for a summary of a teammate's PR before reviewing it doesn't fire the skill. |

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/pr-writeup --scaffold --ablation none \
  --model opus --judge-model opus --allow-tools Bash
```

- A case costs about $0.10 to $0.17 a run.
