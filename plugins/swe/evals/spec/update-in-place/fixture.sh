#!/usr/bin/env bash
# path-local's repository, plus an earlier spec in the gitignored .local/
# whose one open question the resumed conversation settles.
source "$(dirname "$0")/../path-local/fixture.sh"
cat > .local/20261101-top-words-spec.md <<'MD'
# Top words helper

Source: the design conversation of 2026-11-01.

## Problem

Callers who want the most common words in a text sort the dict from `count_words` by hand.

## Goals

- One helper that returns the most frequent words in a text.

## Non-goals

- Stemming and stop-word removal.

## Decisions

1. `top_words(text, n)` lives in `tally/counter.py` and is built on `count_words`: counting stays in one place.
2. It returns the `n` most frequent words as `(word, count)` pairs, most frequent first.
3. Ties are ordered alphabetically: the output is deterministic.
4. `n=0` returns `[]`, and an `n` larger than the number of distinct words returns every word.

## Acceptance criteria

1. `top_words("b a b", 1)` returns `[("b", 2)]`. (D1, D2)
2. `top_words("b a", 2)` returns `[("a", 1), ("b", 1)]`. (D3)
3. `top_words("a", 0)` returns `[]`, and `top_words("a", 5)` returns `[("a", 1)]`. (D4)

## Open questions

- What does a negative `n` do? The conversation never said, and the helper needs one behavior to test.
MD
