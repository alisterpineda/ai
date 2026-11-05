#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Default target with nothing staged: one small untracked file with a bug
# (mutable default argument accumulates across calls) and one 300 KB untracked
# dump that must be listed as uncaptured, not reviewed.
mkdir -p src
echo "# tags" > README.md
commit "Init"
cat > src/tags.py <<'PY'
def add_tag(tag, tags=[]):
    """Return a new list holding `tag`, appended to `tags` if given."""
    tags.append(tag)
    return tags
PY
python3 -c "print('x' * 300000)" > dump.log
