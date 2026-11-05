---
type: llm
focus: last_message
---
PASS if the number in the report's "<N> findings confirmed" header line equals the number of
findings headed "### " (like "### CO1." or "### ST1.") in the report. "- See ..." pointer lines
are not findings. FAIL if the two numbers differ.
