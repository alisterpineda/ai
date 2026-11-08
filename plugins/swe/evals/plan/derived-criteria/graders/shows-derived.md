---
type: llm
focus: last_message
---
The spec has a Requirements list and no numbered acceptance criteria: `top_words(text, n)` returns the
`n` most common words as `(word, count)` pairs, most common first; ties are alphabetical; zero words
gives an empty list. PASS only if the final message:
1. lists numbered criteria derived from the spec that cover all three requirements,
2. quotes or cites the spec line each criterion comes from,
3. asks the user to confirm or correct them, and
4. stops to wait, without reporting a plan written.
FAIL if any of these is missing.
