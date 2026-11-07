#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# A plain request for a plan must not fire swe:plan, which is user-invoked only.
top_words_spec
commit "tally with top-words spec"
