#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# A four-step plan, built with --no-review. Steps 1 to 3 each add a function
# to tally/counter.py and its tests to tests/test_counter.py, so they work in
# the same files and belong to one worker. Step 4 adds a command-line module
# in files of its own. A run that groups uses fewer workers than steps and
# still reports every step as a unit.
echo ".scratch/" > .gitignore
mkdir -p .scratch
cat > .scratch/text-stats-plan.md <<'MD'
# Plan: Text statistics

Source: the conversation

## Goal

`tally` answers three more questions about a text (its most frequent words, how many distinct words it has, and its longest words) and prints a summary of a file from the command line.

## Acceptance criteria

1. `top_words(text, n)` returns the `n` most frequent words in `text` as `(word, count)` pairs, most frequent first, with ties in alphabetical order. An `n` of 0 gives `[]`, and an `n` above the number of distinct words gives every word.
2. `distinct_words(text)` returns the number of different words in `text`, ignoring case.
3. `longest_words(text)` returns every word of the greatest length in `text`, each once, in alphabetical order, and `[]` for a text with no words.
4. `python3 -m tally.cli <path>` prints three lines for the file at `<path>`: `distinct: <n>`, `longest: <words joined by ", ">`, and `top: <word>=<count>` for the 3 most frequent words joined by `, `. With no path, or a path that is not a file, it prints a usage line to stderr and exits with status 2.

## Decisions

1. Every function builds on `_words` in `tally/counter.py`, so all of them agree on what a word is.
2. The command-line module only reads the file and formats: it calls the three functions and holds no counting of its own.

## Cautious readings

- None.

## Checks

- test: `make test`. One class: `python3 -m unittest tests.test_counter.<Class> -v`
- lint: not configured
- typecheck: not configured

## Steps

1. Add `top_words(text, n)`. Criteria: 1
   - Files: `tally/counter.py` (`top_words`, new), `tests/test_counter.py` (`TopWordsTest`, new)
   - Test first: `TopWordsTest`, through `top_words`: most frequent first, ties in alphabetical order, `n` of 0, and `n` above the number of distinct words.
   - Done when: `python3 -m unittest tests.test_counter.TopWordsTest -v` passes and `make test` stays green.

2. Add `distinct_words(text)`. Criteria: 2
   - Files: `tally/counter.py` (`distinct_words`, new), `tests/test_counter.py` (`DistinctWordsTest`, new)
   - Test first: `DistinctWordsTest`, through `distinct_words`: a text that repeats a word in two cases counts it once, and an empty text gives 0.
   - Done when: `python3 -m unittest tests.test_counter.DistinctWordsTest -v` passes and `make test` stays green.

3. Add `longest_words(text)`. Criteria: 3
   - Files: `tally/counter.py` (`longest_words`, new), `tests/test_counter.py` (`LongestWordsTest`, new)
   - Test first: `LongestWordsTest`, through `longest_words`: one longest word, two of the same length in alphabetical order, a longest word that repeats listed once, and an empty text.
   - Done when: `python3 -m unittest tests.test_counter.LongestWordsTest -v` passes and `make test` stays green.

4. Add the command-line module. Criteria: 4
   - Files: `tally/cli.py` (new: `main(argv)`, and the `__main__` guard that exits with its result), `tests/test_cli.py` (`CliTest`, new), `README.md` (a Usage section with the command and a sample of its output)
   - Test first: `CliTest`, through `main` with a temporary file and captured stdout and stderr: the three lines for a known text, the usage line and status 2 with no path, and the same for a path that does not exist.
   - Done when: `python3 -m unittest tests.test_cli -v` passes and `make test` stays green.
MD
commit "tally with a text-stats plan"
