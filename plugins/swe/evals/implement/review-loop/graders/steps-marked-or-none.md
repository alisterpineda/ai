---
type: regex
pattern: '^# Plan: [^\n]*\n(?![\s\S]* Done: \d{4})|^1\. [^\n]* Done: \d{4}-\d{2}-\d{2}, [0-9a-f]{7,40}\.[ \t]*$[\s\S]*^2\. [^\n]* Done: \d{4}-\d{2}-\d{2}, [0-9a-f]{7,40}\.[ \t]*$'
flags: m
target:
  source: file
  path: .scratch/top-words-plan.md
---
