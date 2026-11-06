#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Unsliced slugify spec, built with --review and a review model and effort.
# The loop must call swe:code-review-core with --spec and the passed-through
# --model/--effort, and report its rounds.
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
cat > docs/specs/slugify-spec.md <<'MD'
# Slugify

## Problem
Titles turn into URLs by hand, and the results are inconsistent.

## Goals
- One function that turns a title into a URL slug.

## Non-goals
- Transliterating non-ASCII letters (they are dropped).

## Decisions
1. `slugify` lives in `textkit/strings.py`, next to `shout`: one module for string transforms.

## Acceptance criteria
1. `slugify(text)` lowercases ASCII letters and joins words with single hyphens: `slugify("Hello World")` returns `"hello-world"`.
2. Every run of characters other than ASCII letters and digits becomes one hyphen, with none at either end: `slugify("  Rock & Roll!! ")` returns `"rock-roll"`.
3. `slugify` returns `""` when the text has no ASCII letters or digits.
4. `slugify` raises `TypeError` when `text` is not a `str`.
MD
commit "textkit with slugify spec"
