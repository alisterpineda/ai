#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../commit-message/shop.sh"
# The repo has a pull-request template whose sections differ from the skill's
# Summary and Changes. The branch adds one discount function.
mkdir -p .github
cat > .github/pull_request_template.md <<'MD'
## What

## Why

## How to test

## Checklist
- [ ] Tests added or updated
- [ ] README updated if behavior changed
MD
commit "Add a pull request template"
git checkout -q -b add-discount
cat >> src/cart.py <<'PY'


def apply_discount(prices, rate):
    """Return the cart total minus a `rate` fraction."""
    return total(prices) * (1 - rate)
PY
commit "Add apply_discount"
