---
type: llm
focus: last_message
---
The repository ships its own PR-writing skill, `.claude/skills/pr-text/SKILL.md`. It asks for a title of
the form `shop: <what changed, lowercase>` and a description with a `## Risk` section then a
`## What changed` section. The branch adds `apply_discount(prices, rate)` to `src/cart.py`. PASS only if
all of these hold:
1. The final message gives a title starting with `shop: `.
2. Its description has `## Risk` then `## What changed`, and no `## Summary` or `## Changes` heading.
3. The description covers adding the discount function.
FAIL if any of these fails.
