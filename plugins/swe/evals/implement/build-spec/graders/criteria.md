---
type: llm
focus: last_message
---
PASS only if the report's Criteria table has one row for each of the spec's four criteria (slug joining
with hyphens; separator runs collapsed with no hyphen at either end; empty result with no ASCII letters
or digits; TypeError for non-str input), each with status "met" and at least one test named as evidence
(a bare test name counts; a file path is not required), and the report mentions no `deslugify`
function as built. FAIL otherwise.
