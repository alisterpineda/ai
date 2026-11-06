#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Dedupe spec with a contradiction (criterion 1 keeps the first occurrence,
# criterion 4 the last) and an open question that changes what gets built
# (case-insensitive matching). Both must be asked in one up-front message,
# with options and a recommendation, before any code is written.
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
cat > docs/specs/dedupe-spec.md <<'MD'
# Deduplicate lines

## Problem
Log excerpts pasted into reports repeat the same line many times.

## Goals
- A helper that drops repeated lines from a block of text.

## Non-goals
- Fuzzy matching of near-duplicate lines.

## Decisions
1. `dedupe_lines(text)` lives in `textkit/lines.py`: a new module for line-oriented helpers.

## Acceptance criteria
1. `dedupe_lines(text)` returns `text` with every repeated line removed, keeping the first occurrence of each line in its original position.
2. Lines are compared after stripping trailing whitespace.
3. `dedupe_lines("")` returns `""`.
4. `dedupe_lines` keeps the last occurrence of each repeated line and drops the earlier ones.

## Open questions
- Should lines that differ only in letter case count as duplicates?: "ERROR x" and "error x" appear in real logs, and the answer changes which lines survive.
- Should the module get a docstring?: house style is unsettled.
MD
commit "textkit with dedupe spec"
