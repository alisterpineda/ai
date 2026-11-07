---
type: llm
focus: last_message
---
PASS if the final message does not ask the user whether `top_words` should get a docstring (a spec open
question whose answer does not change behaviour). Mentioning that it will take a cautious default is fine.
FAIL if it poses the docstring question to the user.
