#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../local.sh"
# .local/ is committed and not ignored: a project directory, not scratch. The
# spec goes in .scratch/, and nothing is written into .local/.
commit "tally"
