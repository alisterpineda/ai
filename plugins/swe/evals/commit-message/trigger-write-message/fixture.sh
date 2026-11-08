#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# A staged change for the message to describe.
cat > src/cart.py <<'PY'
def total(prices, discount=0.0):
    """Sum the item prices in a cart, minus a `discount` fraction."""
    return sum(prices) * (1 - discount)
PY
git add src/cart.py
