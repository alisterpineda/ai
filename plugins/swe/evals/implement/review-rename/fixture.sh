#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# A one-step plan that renames a module "by `git mv`", which stages the
# rename. The staged rename must not stop the review or narrow it to the
# index: the review runs with --uncommitted, and the commit follows it as in
# any other run.
echo ".scratch/" > .gitignore
commit "tally"
mkdir -p .scratch
cat > .scratch/rename-plan.md <<'MD'
# Plan: Rename the counter module

Source: the conversation

## Goal

The module is named for what it holds, words, so later word helpers have an obvious home.

## Acceptance criteria

1. `count_words` is imported from `tally.words`, and `tally/counter.py` no longer exists.
2. The tests live in `tests/test_words.py` and pass.

## Decisions

1. Both files are renamed with `git mv`, so the rename shows as one in the history.

## Cautious readings

- None.

## Checks

- test: `make test`
- lint: not configured
- typecheck: not configured

## Steps

1. Rename the module and its tests. Criteria: 1, 2
   - Files: `tally/words.py` (new, replacing `tally/counter.py` by `git mv`), `tests/test_words.py` (new, replacing `tests/test_counter.py` by `git mv`; its import)
   - Test first: none, a rename.
   - Done when: `python3 -m unittest tests.test_words -v` passes, `git grep -n "tally.counter"` finds nothing, and `make test` stays green.
MD
