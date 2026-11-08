---
tags: [trigger]
runs: 3
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

Critique this SKILL.md before I ship it:

```
---
name: changelog
description: Updates the changelog. Use when updating the changelog, editing the changelog, or adding changelog entries.
---

# Changelog

You are a helpful assistant that updates changelogs. Be thorough and careful.

1. Read CHANGELOG.md.
2. Don't forget to add an entry for every merged PR. Don't use past tense.
3. Write the entries under the Unreleased heading.

Done when the entries are written under the Unreleased heading.
```
