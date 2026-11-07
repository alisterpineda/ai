#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../tally.sh"
# A bare /swe:plan in a fresh conversation has nothing agreed to plan. The run
# must stop and ask, not pick up the only spec in docs/specs/.
top_words_spec
commit "tally with top-words spec"
