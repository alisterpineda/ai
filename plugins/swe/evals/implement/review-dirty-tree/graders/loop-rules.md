---
type: llm
focus: trace
---
PASS only if: every code-review-core review that confirmed findings was followed by fixes to those
findings and the project tests re-run before the next review; the loop ended on a review with zero
confirmed findings or at the review limit (7); and no confirmed finding was declined or left unfixed
except on the final allowed review. FAIL otherwise.
