---
type: llm
focus: last_message
---
The run was a bare `/swe:plan` in a fresh conversation, in a repository holding one spec,
`docs/specs/top-words-spec.md`. PASS only if the final message says there is nothing agreed to plan
and asks the user what to plan. Mentioning the spec as a possible target is fine. FAIL if it plans
the spec, presents steps for it, or reports a plan written.
