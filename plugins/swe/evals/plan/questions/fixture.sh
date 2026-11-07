#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# A top-words spec that leaves the order of tied words open (it changes the
# output) and asks a trivial docstring question (it doesn't). Only the first
# goes to the user, before any plan is written.
cat > docs/specs/top-words-spec.md <<'MD'
# Top words

Source: the conversation

## Problem
Users of `count_words` sort its result by hand to find the most common words.

## Goals
- A helper that returns the most frequent words in a text.

## Decisions
1. `top_words` builds on `count_words`: counting stays in one place.

## Acceptance criteria
1. `top_words(text, n)` in `tally/counter.py` returns the `n` most frequent words in `text` as `(word, count)` pairs, most frequent first.
2. `top_words(text, 0)` returns `[]`.

## Open questions
- How should words that tie on count be ordered?: "b a b a" has two words with count 2, and the answer changes which comes first.
- Should `top_words` get a docstring?: house style is unsettled.
MD
commit "tally with top-words spec"
