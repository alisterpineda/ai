#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../commit-message/shop.sh"
# The repo ships its own PR-writing skill, whose format differs from this
# plugin's Summary and Changes. The branch adds one discount function.
mkdir -p .claude/skills/pr-text
cat > .claude/skills/pr-text/SKILL.md <<'MD'
---
name: pr-text
description: Write this repo's pull-request title and description. Use whenever the user asks for a PR title, description, or write-up.
---

# PR text

Read `git diff main...HEAD`, then print:

- a title of the form `shop: <what changed, lowercase>`
- a description with exactly these sections, in this order: `## Risk` (one of low, medium, high, with one sentence saying why), then `## What changed` (plain sentences, no bullets).
MD
commit "Add the PR text skill"
git checkout -q -b add-discount
cat >> src/cart.py <<'PY'


def apply_discount(prices, rate):
    """Return the cart total minus a `rate` fraction."""
    return total(prices) * (1 - rate)
PY
commit "Add apply_discount"
