---
type: regex
pattern: '\tcommit: (?![A-Za-z]+(?:\([^)]*\))?!?:)[A-Z][^\n]{0,77}[^.\n]$'
flags: m
target:
  source: file
  path: .git/logs/HEAD
---
