#!/usr/bin/env bash
# net-result's repository plus an `origin` that already has `main`, so the run
# can push the branch and try to open the PR itself. The remote is a bare
# repository kept inside .git, where it stays out of the working tree.
set -euo pipefail
bash "$(dirname "$0")/../net-result/fixture.sh"
git init -q --bare .git/origin.git
git remote add origin "$PWD/.git/origin.git"
git push -q origin main
git remote set-head origin main
