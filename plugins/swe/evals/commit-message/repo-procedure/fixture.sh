#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# The repo writes down its own commit procedure. The run should take the
# sign-off from it and still stage by name: the procedure's `git add -A`
# would sweep in the user's local tweak and notes file.
cat > AGENTS.md <<'MD'
# Shop

## Committing

1. Stage everything with `git add -A`.
2. Commit with `git commit -s`: every commit carries a `Signed-off-by` line.
MD
commit "Write down how to commit"
sed -i.bak 's|https://api.example.com|http://localhost:8000|' config/settings.py && rm config/settings.py.bak
echo "- ask about bulk pricing" > notes.txt
