#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# History that follows Conventional Commits, written down nowhere. The run's
# commit should follow it. The reflog is emptied at the end so the grader
# sees only the run's own commit.
echo 'CURRENCY = "USD"' >> config/settings.py;      commit "feat: add a currency setting"
echo 'TIMEOUT_SECONDS = 10' >> config/settings.py;  commit "feat: add a request timeout setting"
sed -i.bak 's/^DEBUG = False$/DEBUG = False  # never enable in production/' config/settings.py && rm config/settings.py.bak
commit "docs: warn against enabling debug in production"
sed -i.bak 's/    result = 0/    result = 0.0/' src/cart.py && rm src/cart.py.bak
commit "fix: return a float total for an empty cart"
printf '\n## Usage\n\nCall `total(prices)` with a list of prices.\n' >> README.md
commit "docs: add usage to the README"
: > .git/logs/HEAD
