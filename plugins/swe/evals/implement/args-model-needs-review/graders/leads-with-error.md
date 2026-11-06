---
type: llm
focus: last_message
---
PASS if the final message starts with the preflight script's error, the line beginning "implement:"
(lines that git or the sandbox wrote to that same stderr, such as "git: error: couldn't create cache
file …", and Markdown code fences around the error are acceptable), adds at most a short line of help
after it, and does not claim to have built, written, or fetched anything. FAIL if the message opens with
anything else, such as an introduction, or if it is not that error at all.
