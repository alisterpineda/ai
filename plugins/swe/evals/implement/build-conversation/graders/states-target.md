---
type: llm
focus: trace
---
PASS if, before the run's first edit to a project file (anything outside .scratch/), the agent told
the user in its own words what it was about to build (reverse_words (the plan agreed in the conversation)) and where the spec is (a new spec file under .scratch/).
Any wording counts. FAIL if no such statement comes before the first code change.
