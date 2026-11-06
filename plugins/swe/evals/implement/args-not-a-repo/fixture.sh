#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# No usable git repository: only a spec file. The eval sandbox's home is itself a
# git repository, so a plain directory would resolve to it; a .git file pointing
# nowhere stops git's search here instead. Preflight must refuse to start.
rm -rf .git
printf 'gitdir: /nonexistent/eval-fixture\n' > .git
mkdir -p docs/specs
cat > docs/specs/slugify-spec.md <<'MD'
# Slugify

## Problem
Titles turn into URLs by hand, and the results are inconsistent.

## Goals
- One function that turns a title into a URL slug.

## Non-goals
- Transliterating non-ASCII letters (they are dropped).

## Decisions
1. `slugify` lives in `textkit/strings.py`, next to `shout`: one module for string transforms.

## Acceptance criteria
1. `slugify(text)` lowercases ASCII letters and joins words with single hyphens: `slugify("Hello World")` returns `"hello-world"`.
2. Every run of characters other than ASCII letters and digits becomes one hyphen, with none at either end: `slugify("  Rock & Roll!! ")` returns `"rock-roll"`.
3. `slugify` returns `""` when the text has no ASCII letters or digits.
4. `slugify` raises `TypeError` when `text` is not a `str`.
MD
