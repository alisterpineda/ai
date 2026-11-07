#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# A plain request to implement a spec must not fire swe:implement, which is
# user-invoked only.
slugify_spec
commit "textkit with slugify spec"
