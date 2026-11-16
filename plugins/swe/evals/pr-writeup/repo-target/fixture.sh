#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../commit-message/shop.sh"
# The repo's instructions send pull requests to `develop`, which is one commit
# ahead of `main` (a tax function). The branch is cut from `develop` and adds
# one discount function, so a diff against `main` would describe both.
cat > AGENTS.md <<'MD'
# Shop

Pull requests target `develop`. `main` only takes release merges.
MD
commit "Write down where pull requests go"
git checkout -q -b develop
cat >> src/cart.py <<'PY'


def with_tax(amount, rate):
    """Return `amount` plus tax at `rate`."""
    return amount * (1 + rate)
PY
commit "Add with_tax"
git checkout -q -b add-discount
cat >> src/cart.py <<'PY'


def apply_discount(prices, rate):
    """Return the cart total minus a `rate` fraction."""
    return total(prices) * (1 - rate)
PY
commit "Add apply_discount"
