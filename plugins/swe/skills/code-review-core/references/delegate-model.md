# Delegate model

The model your subagents run on when no flag names one, or when the subagent tool rejects the one a flag named. It is a cap: a session on a model above the cap delegates to the cap model, and every other session delegates to its own model.

| Your model | Delegate model |
|---|---|
| Claude Fable, Claude Mythos | Claude Opus |
| GPT-6 Astra | GPT-6.1 Sol |
| Gemini 4 Carbon | Gemini 4 Argon |
| any other | your own |

A row covers every version of the models it names.

Give the subagent tool the delegate model under the name that tool takes (on Claude Code, `opus`). When the delegate model is your own, give the tool no model.

When the subagent tool takes no model, or rejects the delegate model's name, the delegate model is your own. Wherever your report names the model, name the one that ran and add why it isn't the expected one: `<your model> (the subagent tool took no model)`, `<delegate model> (<flag's name> was rejected)`.
