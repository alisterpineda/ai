---
type: llm
focus: last_message
---
The branch `add-discount` is four commits ahead of `main`: it adds `apply_coupon` to `src/cart.py`,
renames it to `apply_discount`, adds a debug `print`, then removes it. Its net change is one new
function, `apply_discount(prices, rate)`, that returns the cart total minus a `rate` fraction.
PASS only if all of these hold:
1. The final message gives a PR title on its own line, then a markdown codeblock holding a
   `## Summary` section and a `## Changes` section.
2. The description covers adding the discount function.
3. The title and description never mention `apply_coupon`, a rename, a debug print, individual
   commits, or commit hashes. Text addressed to the user outside the title and codeblock doesn't count.
4. `## Changes` has 1 to 3 bullets.
FAIL if any of these fails.
