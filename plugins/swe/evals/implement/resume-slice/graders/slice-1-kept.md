---
type: regex
pattern: 'ranked = sorted\(count_words\(text\)\.items\(\), key=lambda pair: \(-pair\[1\], pair\[0\]\)\)\n    return ranked\[:n\]'
target:
  source: file
  path: tally/counter.py
---
