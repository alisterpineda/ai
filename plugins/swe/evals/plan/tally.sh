# tally.sh: the base repository the plan and spec eval fixtures share. A case's
# fixture.sh sources it, then adds its own files and commits. It builds a
# tally repo (standard library only, tests run with `make test`) in the
# current, empty directory, and leaves everything uncommitted.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
mkdir -p tally tests docs/specs
cat > README.md <<'MD'
# tally

Word counting helpers, standard library only.

## Development

Run the tests with `make test` (that is, `python3 -m unittest discover -s tests -v`).
There is no linter or type checker.
MD
cat > Makefile <<'MK'
test:
	python3 -m unittest discover -s tests -v
MK
: > tally/__init__.py
: > tests/__init__.py
cat > tally/counter.py <<'PY'
import re

_WORD = re.compile(r"[a-z0-9']+")


def _words(text):
    return _WORD.findall(text.lower())


def count_words(text):
    """Return a dict mapping each word in `text`, lower-cased, to its count."""
    counts = {}
    for word in _words(text):
        counts[word] = counts.get(word, 0) + 1
    return counts
PY
cat > tests/test_counter.py <<'PY'
import unittest

from tally.counter import count_words


class CountWordsTest(unittest.TestCase):
    def test_counts_case_insensitively(self):
        self.assertEqual(count_words("The cat saw the CAT"), {"the": 2, "cat": 2, "saw": 1})

    def test_empty_text(self):
        self.assertEqual(count_words(""), {})


if __name__ == "__main__":
    unittest.main()
PY

# The settled spec: no open questions, one criterion no automated test can
# check (the README line), so a plan for it has a `Test first: none` step.
top_words_spec() {
cat > docs/specs/top-words-spec.md <<'MD'
# Top words

Source: the conversation

## Problem
Users of `count_words` sort its result by hand to find the most common words.

## Goals
- A helper that returns the most frequent words in a text.

## Non-goals
- Stemming or stop-word removal.

## Decisions
1. `top_words` builds on `count_words`: counting stays in one place, so both agree on what a word is.

## Acceptance criteria
1. `top_words(text, n)` in `tally/counter.py` returns the `n` most frequent words in `text` as `(word, count)` pairs, most frequent first.
2. Words that tie on count are ordered alphabetically.
3. `top_words(text, 0)` returns `[]`.
4. When `n` is larger than the number of distinct words, `top_words` returns every word.
5. The README's Development section names `top_words` as the way to find the most common words.

## Open questions
- None.
MD
}
