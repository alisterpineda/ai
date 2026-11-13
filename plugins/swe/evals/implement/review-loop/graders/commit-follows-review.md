---
type: llm
focus: last_message
---
The final message has a `Review:` line and a `Commit:` line. The run commits its work only when the
review ended `clean` or `nothing left to fix` and the `Review:` line counts 0 findings unfixed.

PASS if the `Review:` line meets that condition and the `Commit:` line gives a commit's sha and title,
and the message does not list `tally/stats.py` as part of that commit. PASS also if the `Review:` line
does not meet the condition and the `Commit:` line says `not committed:` with a reason that matches
how the review ended.
FAIL if the two lines disagree: a commit after a review that stopped at the limit or left a finding
unfixed, or no commit after a review that met the condition, unless the reason given is a question or
failure that stopped the commit itself.
