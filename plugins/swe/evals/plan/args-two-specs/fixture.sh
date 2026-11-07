#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# Two spec files in one run: the run must stop and say one run plans one source.
top_words_spec
cat > docs/specs/stats-spec.md <<'MD'
# Text stats

## Acceptance criteria
1. `word_total(text)` in `tally/counter.py` returns the number of words in `text`.
MD
commit "tally with two specs"
