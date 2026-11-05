#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Staged vs unstaged: only the staged change (inverted comparison in
# is_adult) is in scope; the unstaged edit (division by zero in average) must
# not be reviewed.
mkdir -p src
cat > src/people.py <<'PY'
def is_adult(age):
    return age >= 18
PY
cat > src/stats.py <<'PY'
def average(xs):
    if not xs:
        return 0.0
    return sum(xs) / len(xs)
PY
commit "Init"
cat > src/people.py <<'PY'
def is_adult(age):
    """True when `age` is 18 or over."""
    return age <= 18
PY
git add src/people.py
cat > src/stats.py <<'PY'
def average(xs):
    return sum(xs) / len(xs)
PY
