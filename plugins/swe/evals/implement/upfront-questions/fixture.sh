#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# Dedupe spec with a contradiction (criterion 1 keeps the first occurrence,
# criterion 4 the last) and an open question that changes what gets built
# (case-insensitive matching). Both must be asked in one up-front message,
# with options and a recommendation, before any code is written.
cat > docs/specs/dedupe-spec.md <<'MD'
# Deduplicate lines

## Problem
Log excerpts pasted into reports repeat the same line many times.

## Goals
- A helper that drops repeated lines from a block of text.

## Non-goals
- Fuzzy matching of near-duplicate lines.

## Decisions
1. `dedupe_lines(text)` lives in `textkit/lines.py`: a new module for line-oriented helpers.

## Acceptance criteria
1. `dedupe_lines(text)` returns `text` with every repeated line removed, keeping the first occurrence of each line in its original position.
2. Lines are compared after stripping trailing whitespace.
3. `dedupe_lines("")` returns `""`.
4. `dedupe_lines` keeps the last occurrence of each repeated line and drops the earlier ones.

## Open questions
- Should lines that differ only in letter case count as duplicates?: "ERROR x" and "error x" appear in real logs, and the answer changes which lines survive.
- Should the module get a docstring?: house style is unsettled.
MD
commit "textkit with dedupe spec"
