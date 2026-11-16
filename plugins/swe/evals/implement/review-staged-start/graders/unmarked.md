---
type: regex
pattern: ' Done: \d{4}'
match: not_contains
target:
  source: file
  path: .scratch/usage-plan.md
---
