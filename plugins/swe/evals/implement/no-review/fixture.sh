#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# The settled top-words spec, built with --no-review: no review may start,
# the work stays uncommitted, and the report hands over the /swe:code-review
# command instead.
top_words_spec
commit "tally with top-words spec"
