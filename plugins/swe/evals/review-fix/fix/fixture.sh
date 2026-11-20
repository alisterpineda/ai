#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# A committed tally with one uncommitted edit, the work under review. Planted
# in it: distinct_words counts every word, repeats included and case kept,
# though its docstring promises distinct words ignoring case. No spec: the
# docstring settles the fix, so the run fixes it and reviews again.
commit "tally"
cat >> tally/counter.py <<'PY'


def distinct_words(text):
    """Return the number of distinct words in `text`, ignoring case."""
    return len(_WORD.findall(text))
PY
