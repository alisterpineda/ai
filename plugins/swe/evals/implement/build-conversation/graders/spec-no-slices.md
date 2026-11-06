---
type: regex
target: trace
pattern: 'Source: the conversation[\s\S]{0,4000}?## Open questions[^#]{0,2000}## Slices'
match: not_contains
---
