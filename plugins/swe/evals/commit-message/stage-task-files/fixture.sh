#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# The user's own work in progress, which the commit must leave out: a local
# tweak to a tracked file and an untracked notes file.
sed -i.bak 's|https://api.example.com|http://localhost:8000|' config/settings.py && rm config/settings.py.bak
echo "- ask about bulk pricing" > notes.txt
