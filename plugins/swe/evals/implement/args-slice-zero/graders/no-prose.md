---
type: llm
focus: last_message
---
PASS if the final message is only the preflight script's stderr: an error line beginning
"implement:" (plus, for an unclean tree, the indented list of files under it). Lines that git or
the sandbox wrote to that same stderr, such as "git: error: couldn't create cache file …" or
"warning: could not open directory …", are part of it and are acceptable. Markdown code fences
around it are acceptable. FAIL if the message adds any sentence of its own (an introduction,
explanation, advice, or summary), or if it is not that error at all.
