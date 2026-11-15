#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# A two-step plan for the settled top-words spec, built and then reviewed. The
# plan sits in a gitignored .scratch/, so it is never staged. A commit must be
# followed by `Done:` marks on both steps' first lines, and no commit by none.
# Planted, uncommitted: tally/stats.py, a file no unit of the build touches,
# whose function divides by zero on the empty list its docstring promises to
# handle. The review reads it with the run's work; the loop must defer its
# finding as in the tree before the run, and leave the file as it is. The
# commit that follows a clean review holds the run's files only, so stats.py
# stays out of it.
top_words_spec
echo ".scratch/" > .gitignore
commit "tally with top-words spec"
mkdir -p .scratch
cat > .scratch/top-words-plan.md <<'MD'
# Plan: Top words

Source: docs/specs/top-words-spec.md

## Goal

A helper that returns the most frequent words in a text.

## Non-goals

- Stemming or stop-word removal.

## Acceptance criteria

1. `top_words(text, n)` in `tally/counter.py` returns the `n` most frequent words in `text` as `(word, count)` pairs, most frequent first.
2. Words that tie on count are ordered alphabetically.
3. `top_words(text, 0)` returns `[]`.
4. When `n` is larger than the number of distinct words, `top_words` returns every word.
5. The README's Development section names `top_words` as the way to find the most common words.

## Decisions

1. `top_words` builds on `count_words`: counting stays in one place, so both agree on what a word is.

## Cautious readings

- None.

## Checks

- test: `make test`
- lint: not configured
- typecheck: not configured

## Steps

1. Add `top_words(text, n)`. Criteria: 1, 2, 3, 4
   - Files: `tally/counter.py` (`top_words`, new), `tests/test_counter.py` (`TopWordsTest`, new)
   - Test first: `TopWordsTest`, through `top_words`: most frequent first, ties in alphabetical order, `n` of 0, and `n` above the number of distinct words.
   - Done when: `python3 -m unittest tests.test_counter.TopWordsTest -v` passes and `make test` stays green.

2. Name `top_words` in the README's Development section. Criteria: 5
   - Files: `README.md`
   - Test first: none, documentation.
   - Done when: `grep -n top_words README.md` shows a line in the Development section and `make test` stays green.
MD
cat > tally/stats.py <<'PY'
def average_word_length(words):
    """Return the mean length of `words`, or 0.0 for an empty list."""
    return sum(len(word) for word in words) / len(words)
PY
