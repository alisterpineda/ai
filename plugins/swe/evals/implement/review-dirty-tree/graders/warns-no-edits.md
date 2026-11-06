---
type: llm
focus: trace
---
PASS if, before its first build (the first edit to a project file outside .scratch/), the agent told
the user not to edit files in the repository until the run finishes. Any wording counts. FAIL if no
such warning comes before the first code change.
