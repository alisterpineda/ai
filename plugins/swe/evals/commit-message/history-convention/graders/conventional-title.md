---
type: regex
pattern: '\tcommit: feat(?:\([^)]*\))?!?: \S'
target:
  source: file
  path: .git/logs/HEAD
---
