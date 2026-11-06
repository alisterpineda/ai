---
type: llm
focus: trace
---
Find where the agent wrote the spec file under .scratch/ (a Write call, or a Bash heredoc). PASS only if
its Acceptance criteria cover all of: reverse_words returns the words in reverse order joined by single
spaces; empty or whitespace-only input returns ""; a non-str argument raises TypeError. Criteria that
restate other parts of the agreed plan (its location next to `shout`, punctuation staying attached to
its word, where the tests live) are fine. FAIL if any of the three is missing, or a criterion adds
behaviour the plan never mentioned.
