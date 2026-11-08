#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# The user's own staged change, which the commit must take as it is, next to
# an unstaged local tweak it must leave out.
cat > src/cart.py <<'PY'
def total(prices):
    """Sum the item prices in a cart, ignoring negative prices."""
    return sum(price for price in prices if price >= 0)
PY
git add src/cart.py
sed -i.bak 's|https://api.example.com|http://localhost:8000|' config/settings.py && rm config/settings.py.bak
