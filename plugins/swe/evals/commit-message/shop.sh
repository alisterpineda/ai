# shop.sh: the base repository the commit-message eval fixtures share. A
# case's fixture.sh sources it, then adds its own uncommitted changes. It
# commits a small cart library in the current, empty directory. Eval runs
# switch off git hooks, so graders read commits from the reflog
# (.git/logs/HEAD, one "commit: <title>" line per commit) and from the run's
# own git commands.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
mkdir -p src config
cat > src/cart.py <<'PY'
def total(prices):
    """Sum the item prices in a cart."""
    result = 0
    for price in prices:
        result += price
    return result
PY
cat > config/settings.py <<'PY'
API_URL = "https://api.example.com"
DEBUG = False
PY
cat > README.md <<'MD'
# Shop

A small shopping cart library.

## Install

Run `pip install shop` to recieve the latest release.
MD
git add -A
GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "Init"
# commit <message>: commits every change, dated a day after Init, for fixtures
# that build history on top.
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-02T10:00:00 GIT_COMMITTER_DATE=2026-10-02T10:00:00 git commit -q -m "$1"; }
