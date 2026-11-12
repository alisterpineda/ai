#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# The settled top-words spec, with nothing planted. The work fits one session,
# so the prompt's context asks for the two slices this case grades.
top_words_spec
commit "tally with top-words spec"
