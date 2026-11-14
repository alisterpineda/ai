#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# No .gitignore on purpose: git would let .env in, so it stays out of the
# commit only if the run leaves it out.
