---
type: regex
pattern: '^1\. [^\n]* Done: 2026-10-01, [0-9a-f]{7,40}\.[ \t]*\n(?![\s\S]* Done: \d{4})'
flags: m
target:
  source: file
  path: .scratch/text-stats-plan.md
---
