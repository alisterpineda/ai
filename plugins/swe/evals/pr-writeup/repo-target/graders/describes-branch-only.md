---
type: llm
focus: last_message
---
The repository's `AGENTS.md` says pull requests target `develop`. The branch adds
`apply_discount(prices, rate)` on top of `develop`, which already holds a `with_tax` function that `main`
lacks. PASS only if both hold:
1. The final message gives a PR title and a description that cover adding the discount function.
2. Neither the title nor the description presents the tax function (`with_tax`) as part of this PR's
   change. A note to the user outside them, such as which branches were compared, may mention it.
FAIL if either fails.
