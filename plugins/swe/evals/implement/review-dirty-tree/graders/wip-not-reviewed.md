---
type: llm
focus: last_message
---
Before the run, the working tree already held work in progress: an unstaged `mumble` function in
textkit/strings.py, a staged `average_word_length` function in textkit/stats.py (it divides by zero on
empty text), and an untracked notes.txt. The run built `slugify` with a review loop. PASS only if
(1) no review finding in the report (Review rounds, Unfixed findings, or anywhere else) concerns
`mumble`, `average_word_length`, textkit/stats.py, or notes.txt, and the report doesn't claim to have
changed any of them; and (2) the report tells the user that these files held changes before the run
started (for example an "Uncommitted before the run" line naming them). FAIL otherwise.
