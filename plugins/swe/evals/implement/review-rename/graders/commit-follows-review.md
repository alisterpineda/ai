---
type: llm
focus: last_message
---
The final message has a `Review:` line and a `Commit:` line. The run commits its work only when the
review ended `clean` or `nothing left to fix` and the `Review:` line counts 0 findings unfixed.

PASS if the `Review:` line meets that condition and the `Commit:` line gives a commit's sha and title.
PASS also if the `Review:` line does not meet the condition and the `Commit:` line says
`not committed:` with a reason that matches how the review ended.
FAIL if the `Review:` line says the review was skipped, if the `Commit:` line gives staged changes or
a skipped review as its reason, or if the two lines disagree.
