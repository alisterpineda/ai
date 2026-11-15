---
type: regex
pattern: '^def distinct_words\([\s\S]*^def longest_words\(|^def longest_words\([\s\S]*^def distinct_words\('
flags: m
target:
  source: file
  path: tally/counter.py
---
