---
type: llm
focus: last_message
---
Before the run, the working tree already held work in progress: an unstaged `mumble` function in
textkit/strings.py, a staged `average_word_length` function in textkit/stats.py, and an untracked
notes.txt. The run built `slugify`. PASS only if (1) the report presents none of `mumble`,
`average_word_length`, or notes.txt as a change this run made: not in its Untraceable changes section,
not in its criteria evidence, and not anywhere else; and (2) the report tells the user that these files
held changes before the run started (for example an "Uncommitted before the run" line naming
textkit/strings.py, textkit/stats.py, and notes.txt). FAIL otherwise.
