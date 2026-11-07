#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# Clean textkit repo and no conversation before the command: there is no
# agreed plan to build.
slugify_spec
stats_module
commit "textkit with specs"
