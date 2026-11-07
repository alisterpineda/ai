#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# The textkit repo with both specs, committed and clean. Two spec files end the
# run before anything is built: a run builds one spec.
slugify_spec
stats_module
commit "textkit with specs"
