---
type: llm
focus: last_message
---
The prompt was `/swe:plan docs/specs/top-word-spec.md`, a path that does not exist (the repository has
`docs/specs/top-words-spec.md`). PASS only if the final message stops the run, says that
`docs/specs/top-word-spec.md` names nothing it can read, and says which targets it takes (a spec file,
GitHub issues, or Azure DevOps work items). Suggesting the similarly named spec is fine. FAIL if it
plans anything, or reports a plan written.
