#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# The slugify spec, built from a tree with work in progress: after the commit,
# an unstaged `mumble` in textkit/strings.py (the file slugify goes into), a
# staged `average_word_length` with a ZeroDivisionError on empty text in
# textkit/stats.py, and an untracked notes.txt. The run must start anyway,
# leave all three as they are, and keep them out of its review or self-check:
# none is the run's work, and none traces to a criterion.
slugify_spec
stats_module
commit "textkit with specs"
printf 'scratch notes\n' > notes.txt
cat >> textkit/strings.py <<'PY'


def mumble(text):
    """Return `text` in lower case followed by an ellipsis."""
    return text.lower() + "..."
PY
cat >> textkit/stats.py <<'PY'


def average_word_length(text):
    """Return the mean length of the words in `text`."""
    words = text.split()
    return sum(len(word) for word in words) / len(words)
PY
git add textkit/stats.py
