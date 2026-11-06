---
type: llm
focus: last_message
---
The run asked for `--slice 9` of docs/specs/stats-spec.md, whose slices are 1, 2, and 3. PASS if the
final message says the spec has no slice 9, names the slices it does have (1, 2, and 3), and stops
without building anything. FAIL if it builds or proposes to build a slice anyway, or doesn't say which
slices exist.
