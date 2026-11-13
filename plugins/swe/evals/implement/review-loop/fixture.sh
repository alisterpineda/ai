#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# The settled top-words spec, built and then reviewed. Planted, uncommitted:
# tally/stats.py, a file no unit of the build touches, whose function divides
# by zero on the empty list its docstring promises to handle. The review reads
# it with the run's work; the loop must defer its finding as in the tree
# before the run, and leave the file as it is. The commit that follows a clean
# review holds the run's files only, so stats.py stays out of it.
top_words_spec
commit "tally with top-words spec"
cat > tally/stats.py <<'PY'
def average_word_length(words):
    """Return the mean length of `words`, or 0.0 for an empty list."""
    return sum(len(word) for word in words) / len(words)
PY
