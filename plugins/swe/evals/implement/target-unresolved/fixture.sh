#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# Clean textkit repo. The target is neither a file, a GitHub issue, nor an
# Azure DevOps work item.
slugify_spec
stats_module
commit "textkit with specs"
