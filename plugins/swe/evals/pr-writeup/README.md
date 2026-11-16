# pr-writeup evals

`claude plugin eval` cases for `swe:pr-writeup`. Each fixture sources `../commit-message/shop.sh` for its `main` branch, then builds a feature branch on top; the two trigger cases reuse `net-result`'s. The repo-wide eval conventions (models, graders, sandbox) are in the root `CLAUDE.md`.

| Tag | Cases | What they check |
|---|---|---|
| `result`, `trigger` | `net-result` | A casual "what should the PR say" fires the skill. The branch adds a function, renames it, and adds then removes a debug print: the run gives a title and a codeblock with `## Summary` and `## Changes`, the title and description cover only the net new `apply_discount` and never mention the old name, the rename, the debug print, or commits (a note to the user outside them may), and one concern gets 1 to 3 bullets. |
| `format` | `pr-template` | The repo's `.github/pull_request_template.md` has What, Why, How to test, and Checklist sections: the description uses those, in order, keeps the checklist, and has no `## Summary` or `## Changes`. |
| `yield` | `repo-target` | The repo's `AGENTS.md` sends pull requests to `develop`, which is one commit (a tax function) ahead of `main`; the fixture has no remote. The title and description cover the branch's discount function and don't present the tax function as part of the PR. |
| `yield` | `repo-skill` | The repo ships its own PR-writing skill in `.claude/skills/pr-text/`, with a `shop: ` title prefix and `## Risk` and `## What changed` sections: the run gives that title and those sections, with no `## Summary` or `## Changes`. It doesn't check which skill fired first, only whose format the text ends in. |
| `trigger` | `trigger-open-pr` | "Open a PR for this branch" fires the skill, and the run gives a title and description to use without claiming it opened a PR or pushed. The fixture has no remote. |
| `no-trigger` | `no-trigger-summarize-pr` | Asking for a summary of a teammate's PR before reviewing it doesn't fire the skill. |

## Run

```
cd plugins
claude plugin eval . --eval-dir swe/evals/pr-writeup --scaffold --ablation none \
  --model opus --judge-model opus --allow-tools Bash
```

- A case costs about $0.10 to $0.17 a run.
