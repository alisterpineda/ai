#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# A one-step plan built while the index already holds a change of the user's:
# a staged edit to the Makefile, a file the step doesn't touch. The review
# still runs, with --uncommitted, on all the uncommitted changes. The commit
# does not: it would take the staged Makefile along. The Makefile stays staged.
echo ".scratch/" > .gitignore
commit "tally"
mkdir -p .scratch
cat > .scratch/usage-plan.md <<'MD'
# Plan: Usage section

Source: the conversation

## Goal

The README shows how to call `count_words`.

## Acceptance criteria

1. The README has a `## Usage` section, above `## Development`, with a Python example that calls `count_words("the cat saw the cat")` and shows its result, `{'the': 2, 'cat': 2, 'saw': 1}`.

## Decisions

- None.

## Cautious readings

- None.

## Checks

- test: `make test`
- lint: not configured
- typecheck: not configured

## Steps

1. Add the Usage section to the README. Criteria: 1
   - Files: `README.md`
   - Test first: none, documentation.
   - Done when: `grep -n "^## Usage" README.md` shows the heading above `## Development` and `make test` stays green.
MD
printf '\n.PHONY: test\n' >> Makefile
git add Makefile
