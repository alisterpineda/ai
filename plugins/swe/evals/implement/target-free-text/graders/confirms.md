---
type: llm
focus: last_message
---
The command was `/swe:implement` followed only by free text asking for a `reverse_words(text)` helper
in textkit/strings.py, with no conversation before it. PASS only if the final message (1) says it will
build reverse_words from the command's text, (2) names the spec file it wrote for it, (3) asks the user
to confirm the plan (or answer questions about it) before any code is written, and (4) does not report
having written code or tests. FAIL if any of these is missing, or if it rejects the text as an
unresolvable target.
