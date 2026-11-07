#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# Unsliced slugify spec, built with --review and a review model and effort.
# The loop must call swe:code-review-core with --spec and the passed-through
# --model/--effort, and report its rounds.
slugify_spec
commit "textkit with slugify spec"
