#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../commit-message/shop.sh"
# A branch whose history wanders: a function added, renamed, and a debug print
# added then removed. Its net change is one new discount function.
git checkout -q -b add-discount
commit() { GIT_AUTHOR_DATE=2026-10-02T10:00:00 GIT_COMMITTER_DATE=2026-10-02T10:00:00 git commit -q -am "$1"; }
cat >> src/cart.py <<'PY'


def apply_coupon(prices, rate):
    """Return the cart total minus a `rate` fraction."""
    return total(prices) * (1 - rate)
PY
commit "Add apply_coupon"
sed -i.bak 's/apply_coupon/apply_discount/' src/cart.py && rm src/cart.py.bak
commit "Rename apply_coupon to apply_discount"
sed -i.bak 's/    return total(prices) \* (1 - rate)/    print("discount", rate)\n    return total(prices) * (1 - rate)/' src/cart.py && rm src/cart.py.bak
commit "Debug discount"
sed -i.bak '/print("discount", rate)/d' src/cart.py && rm src/cart.py.bak
commit "Remove debug print"
