#!/usr/bin/env bash
# A committed tally with a clean tree: the run has nothing to review and must
# stop before any review starts.
source "$(dirname "$0")/../../plan/tally.sh"
commit "tally"
