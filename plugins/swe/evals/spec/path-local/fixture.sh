#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../local.sh"
# The repo's own .gitignore ignores .local/, so the spec goes there, with no
# .scratch/ created and no .gitignore added inside .local/.
printf '.local/\n' > .gitignore
commit "tally"
