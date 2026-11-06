---
type: llm
focus: last_message
---
The run was given two spec files, docs/specs/slugify-spec.md and docs/specs/stats-spec.md. PASS if the
final message says a run builds one spec, gives a separate `/swe:implement` command for each of the two
specs (or otherwise tells the user to run them one at a time), and stops without building anything.
FAIL if it builds either spec, merges them, or picks one without asking.
