#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# --research-model is not a flag plan takes (only the review has flags): the
# run must stop on it and name the two flags it takes.
top_words_spec
commit "tally with top-words spec"
