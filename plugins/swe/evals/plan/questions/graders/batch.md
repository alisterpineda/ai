---
type: llm
focus: last_message
---
The spec leaves open how words that tie on count are ordered, which changes the function's output. PASS
only if the final message:
1. asks how tied words are ordered,
2. gives options and a recommendation with a reason, and
3. stops to wait for the answer without reporting a plan written.
FAIL if any of these is missing.
