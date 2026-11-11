#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../shop.sh"
# A plan in a gitignored directory, whose labels ("Milestone 2", "step 3")
# no committed file explains. The run's commit message must not use them.
# The reflog is emptied at the end so the grader sees only the run's commit.
# The step is small and names no label in what it asks for, so the code has
# no reason to carry one and the case tests only the message.
echo '.scratch/' > .gitignore
cat >> src/cart.py <<'PY'


def apply_discount(amount, percent):
    """Reduce an amount by a percentage."""
    return round(amount * (1 - percent / 100), 2)
PY
commit "Add percentage discounts to the cart"
mkdir .scratch
cat > .scratch/plan.md <<'MD'
# Cart plan

## Milestone 1: totals

1. Add `total(prices)` to `src/cart.py`. Done: 2026-10-01.

## Milestone 2: discounts

2. Add `apply_discount(amount, percent)` to `src/cart.py`. Done: 2026-10-02.
3. Make `apply_discount` raise `ValueError` when `percent` is below 0 or
   above 100.
4. Add a `DISCOUNT_CODES` setting to `config/settings.py`.
MD
: > .git/logs/HEAD
