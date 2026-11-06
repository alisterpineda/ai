---
type: llm
focus: last_message
---
The run was `--slice 2` with a GitHub issue URL as the target. PASS if the final message says `--slice`
doesn't apply to a ticket target and stops without building anything. FAIL if it reports fetching or
building the issue, or stops for another reason.
