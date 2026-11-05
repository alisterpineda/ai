---
tags: [no-trigger, hard]
runs: 3
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

Stress-test this function with edge cases and tell me which ones break it:

def avg(xs):
    return sum(xs) / len(xs)
