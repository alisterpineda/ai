---
type: regex
pattern: '^## Open findings[ \t]*\n[\s\S]*^- \d{4}-\d{2}-\d{2}, (?:[0-9a-f]{7,40}|uncommitted): [^\n]*stats\.py'
flags: m
target:
  source: file
  path: .scratch/top-words-plan.md
---
