# writing-for-ai evals

`claude plugin eval` cases for `core:writing-for-ai`: whether it fires, and whether aligning a skill to it keeps what the skill's editing guardrails protect.

| Tag | Cases | What they check |
|---|---|---|
| `trigger` | `trigger-*` | Creating a skill, subagent charter, or slash command, tightening or deduplicating a CLAUDE.md or AGENTS.md, and critiquing a pasted SKILL.md fire `writing-for-ai`. |
| `no-trigger` | `no-trigger-*` | A typo fix in a SKILL.md, writing meant for people (an email, a blog post about agents, a README), and a question about a skill don't fire it. |
| `borderline` | `borderline-add-step` | Adding one step to an existing skill. Expected not to fire, but a miss here is a judgment call rather than a bug. |
| `align` | `align-guardrails` | `fixture.sh` writes `skills/triage/SKILL.md`, and the prompt asks to make it follow the skill. The run loads the skill and drops the "Done when" line that repeats its step. No edit loses the scoping condition (`when your prompt names one`), the report's fixed strings (`## Triage:`, `No action needed.`), or the rule its last "Done when" carries (`unconfirmed`). |
| `hard` | subsets of the above | |

Trigger cases run 3 times each; `align-guardrails` runs once.

## Run

```
cd plugins
claude plugin eval . --eval-dir core/evals/writing-for-ai --scaffold --ablation none \
  --model opus --judge-model opus --allow-tools Write Edit
```

Add `--tag align` for the align case alone, or `--tag trigger --tag no-trigger` for the trigger cases.

- `align-guardrails` grades the final `skills/triage/SKILL.md` with `regex` graders and one `llm` grader (the round-3 rule, whose wording the run may change) on `{ source: file }`, so a run may rewrite the file with `Write` or change it with `Edit`.
- A trigger case costs about $0.07 to $0.16 a run, and the align case about $0.10; the whole suite about $3.50.
