---
type: llm
focus: last_message
---
The repository's `.github/pull_request_template.md` has the sections `## What`, `## Why`,
`## How to test`, and `## Checklist` (two checkbox items). The branch adds `apply_discount(prices, rate)`
to `src/cart.py`. PASS only if all of these hold:
1. The final message gives a PR title and a description whose sections are the template's four, in the
   template's order, with the checklist's items kept.
2. The description has no `## Summary` or `## Changes` heading.
3. The description covers adding the discount function.
FAIL if any of these fails.
