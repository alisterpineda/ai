---
type: llm
focus: last_message
---
The run built a two-step plan, and marks a step `Done:` in the plan only once its work is committed.
The final message has a `Commit:` line.

PASS if the `Commit:` line gives a commit's sha and the message says the plan's steps (both, or steps
1 and 2) were marked `Done:`. PASS also if the `Commit:` line says `not committed:` and the message
says the plan's steps are still unmarked.
FAIL if the message reports a commit and does not say the steps were marked, reports no commit and
says steps were marked, or says nothing about the marks either way.
