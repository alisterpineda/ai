# Delegate model

The model a subagent runs on when no flag names one, or when the subagent tool rejects the one a flag named. It depends on the subagent's role, and the skill that sent you here names the role:

- **Worker**: builds a unit of work from a brief.
- **Researcher**: reads the repo, documentation, or a tracker, and reports what it found.
- **Reviewer**: reviews work, or verifies a review's findings.

It is a cap: a session on a model the table names delegates to the model in the role's column, and every other session delegates to its own model.

| Your model | Worker | Researcher | Reviewer |
|---|---|---|---|
| Claude Fable, Claude Mythos | Claude Opus | Claude Opus | Claude Opus |
| GPT-6.2 Astra | GPT-6.2 Sol | GPT-6.2 Sol | GPT-6.2 Sol |
| Gemini 4 Carbon | Gemini 4 Hydrogen | Gemini 4 Hydrogen | your own |
| any other | your own | your own | your own |

A row covers every version of the models it names.

Give the subagent tool the delegate model under the name that tool takes (on Claude Code, `opus`). When the delegate model is your own, give the tool no model.

When the subagent tool takes no model, or rejects the delegate model's name, the delegate model is your own. Wherever your report names the model, name the one that ran and add why it isn't the expected one: `<your model> (the subagent tool took no model)`, `<delegate model> (<flag's name> was rejected)`.
