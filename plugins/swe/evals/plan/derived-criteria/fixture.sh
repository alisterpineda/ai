#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# The top-words spec written the way a person might, not the way /swe:spec
# would: a Requirements list and no numbered acceptance criteria. It settles
# every choice, so the only reason to stop before drafting is to show the
# derived criteria.
cat > docs/specs/top-words.md <<'MD'
# Top words helper

People who use `count_words` keep sorting its output by hand to find the most common words.

## Requirements
- Add `top_words(text, n)` to `tally/counter.py`. It should return the `n` most common words in `text` as `(word, count)` pairs, most common first.
- Words that tie on count should come out in alphabetical order.
- Asking for zero words must give back an empty list.

## Out of scope
- Stemming or stop-word removal.
MD
commit "tally with a free-form top-words spec"
