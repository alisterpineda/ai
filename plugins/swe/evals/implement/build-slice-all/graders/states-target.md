---
type: llm
focus: trace
---
PASS if, before the run's first edit to a project file (anything outside .scratch/), the agent told
the user in its own words what it was about to build (the remaining slices of the stats spec) and where the spec is (docs/specs/stats-spec.md).
Any wording counts. FAIL if no such statement comes before the first code change.
