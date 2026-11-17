# Delegate model and effort

The model and the effort a subagent runs on when no flag names them, and the model it runs on when the subagent tool rejects the one a flag named. Both depend on the subagent's role, and the skill that sent you here names the role:

- **Worker**: builds a unit of work from a brief.
- **Researcher**: reads the repo, documentation, or a tracker, and reports what it found.
- **Reviewer**: reviews work, or verifies a review's findings.

Find your model's row and read the role's column: the delegate model, then the delegate effort.

| Your model | Worker | Researcher | Reviewer |
|---|---|---|---|
| Claude Fable, Claude Mythos | Claude Sonnet, `medium` | Claude Sonnet, `medium` | Claude Opus, `medium` |
| Claude Opus | Claude Sonnet, `medium` | Claude Sonnet, `medium` | your own, `medium` |
| GPT-6.2 Astra | GPT-6.1 Terra, `medium` | GPT-6.1 Terra, `medium` | GPT-6.2 Sol, `medium` |
| GPT-6.2 Sol | GPT-6.1 Terra, `medium` | GPT-6.1 Terra, `medium` | your own, `medium` |
| Gemini 4 Carbon | Gemini 4 Hydrogen, `medium` | Gemini 4 Hydrogen, `medium` | Gemini 4 Hydrogen, `high` |
| Gemini 4 Hydrogen | your own, `medium` | your own, `medium` | your own, `high` |
| any other | your own, `medium` | your own, `medium` | your own, `medium` |

A row covers every version of the models it names.

Give the subagent tool the delegate model under the name that tool takes (on Claude Code, `opus` or `sonnet`). When the delegate model is your own, give the tool no model.

When the subagent tool takes no model, or rejects the delegate model's name, the delegate model is your own. Wherever your report names the model, name the one that ran and add why it isn't the expected one: `<your model> (the subagent tool took no model)`, `<delegate model> (<flag's name> was rejected)`.
