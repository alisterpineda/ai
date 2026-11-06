#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Stats spec with every slice marked Done. --slice all must stop and say every
# slice is done.
mkdir -p textkit tests docs/specs
cat > README.md <<'MD'
# textkit

Small text helpers, standard library only.

## Development

Run the tests with `make test` (that is, `python3 -m unittest discover -s tests -v`).
There is no linter or type checker.
MD
cat > Makefile <<'MK'
test:
	python3 -m unittest discover -s tests -v
MK
cat > textkit/__init__.py <<'PY'
PY
cat > tests/__init__.py <<'PY'
PY
cat > textkit/strings.py <<'PY'
def shout(text):
    """Return `text` in upper case followed by one exclamation mark."""
    return text.upper() + "!"
PY
cat > tests/test_strings.py <<'PY'
import unittest

from textkit.strings import shout


class ShoutTest(unittest.TestCase):
    def test_shout(self):
        self.assertEqual(shout("hi"), "HI!")


if __name__ == "__main__":
    unittest.main()
PY
cat > docs/specs/stats-spec.md <<'MD'
# Text statistics

## Problem
Callers count words and lines with ad-hoc `split()` calls that disagree at the edges.

## Goals
- One module, `textkit/stats.py`, with consistent counting helpers.

## Non-goals
- Unicode word segmentation: words are whitespace-separated.

## Decisions
1. Pure functions over `str`, no classes: the helpers hold no state.

## Acceptance criteria
1. `word_count(text)` returns the number of whitespace-separated words; `word_count("")` returns 0.
2. `char_count(text, spaces=True)` returns the number of characters; with `spaces=False` it leaves out whitespace characters.
3. `line_count(text)` returns the number of lines: `line_count("")` is 0, `line_count("a\nb")` is 2, and a trailing newline adds no line (`line_count("a\n")` is 1).
4. `top_words(text, n)` returns the `n` most common words, lowercased, as `(word, count)` tuples, most common first, ties broken alphabetically.
5. `top_words` raises `ValueError` when `n` is less than 1.

## Slices
1. Counting: word and character counts. Criteria: 1, 2 Done: 2026-10-01.
2. Lines: the line count. Criteria: 3 Done: 2026-10-01.
3. Frequency: the most common words. Criteria: 4, 5 Done: 2026-10-01.
MD
cat > textkit/stats.py <<'PY'
def word_count(text):
    """Return the number of whitespace-separated words in `text`."""
    return len(text.split())


def char_count(text, spaces=True):
    """Return the number of characters in `text`, leaving out whitespace when
    `spaces` is False."""
    if spaces:
        return len(text)
    return sum(1 for ch in text if not ch.isspace())
PY
cat > tests/test_stats.py <<'PY'
import unittest

from textkit.stats import char_count, word_count


class WordCountTest(unittest.TestCase):
    def test_counts_words(self):
        self.assertEqual(word_count("one two  three"), 3)

    def test_empty(self):
        self.assertEqual(word_count(""), 0)


class CharCountTest(unittest.TestCase):
    def test_with_spaces(self):
        self.assertEqual(char_count("a b"), 3)

    def test_without_spaces(self):
        self.assertEqual(char_count("a b\n", spaces=False), 2)


if __name__ == "__main__":
    unittest.main()
PY
cat >> textkit/stats.py <<'PY'


def line_count(text):
    """Return the number of lines in `text`; a trailing newline adds none."""
    return len(text.splitlines())
PY
cat > tests/test_lines.py <<'PY'
import unittest

from textkit.stats import line_count


class LineCountTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(line_count(""), 0)

    def test_two_lines(self):
        self.assertEqual(line_count("a\nb"), 2)

    def test_trailing_newline(self):
        self.assertEqual(line_count("a\n"), 1)


if __name__ == "__main__":
    unittest.main()
PY
cat >> textkit/stats.py <<'PY'


def top_words(text, n):
    """Return the `n` most common lowercased words as (word, count) tuples."""
    if n < 1:
        raise ValueError("n must be at least 1")
    counts = {}
    for word in text.lower().split():
        counts[word] = counts.get(word, 0) + 1
    return sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:n]
PY
cat > tests/test_top_words.py <<'PY'
import unittest

from textkit.stats import top_words


class TopWordsTest(unittest.TestCase):
    def test_most_common_first_ties_alphabetical(self):
        self.assertEqual(top_words("b a B c a b", 2), [("b", 3), ("a", 2)])

    def test_rejects_n_below_one(self):
        with self.assertRaises(ValueError):
            top_words("a", 0)


if __name__ == "__main__":
    unittest.main()
PY
commit "textkit: stats complete"
