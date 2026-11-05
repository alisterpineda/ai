---
tags: [no-trigger]
runs: 3
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

Review this design and give me written feedback, no back-and-forth needed:

We'll add a Redis cache in front of the product catalogue API with a 5-minute TTL, invalidate on writes via a pub/sub message, and fall back to the database if Redis is down.
