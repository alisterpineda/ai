#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../../plan/tally.sh"
# A three-slice plan, resumed with --no-review. Slice 1's step is built,
# committed, and marked `Done:`; slices 2 and 3 are unbuilt. The run skips the
# done step, builds slice 2 only, leaves every step it builds unmarked (there
# is no commit), and hands over slice 3 on its `Next slice:` line.
echo ".scratch/" > .gitignore
cat >> tally/counter.py <<'PY'


def top_words(text, n):
    """Return the `n` most frequent words in `text` as (word, count) pairs."""
    ranked = sorted(count_words(text).items(), key=lambda pair: (-pair[1], pair[0]))
    return ranked[:n]
PY
cat > tests/test_counter.py <<'PY'
import unittest

from tally.counter import count_words, top_words


class CountWordsTest(unittest.TestCase):
    def test_counts_case_insensitively(self):
        self.assertEqual(count_words("The cat saw the CAT"), {"the": 2, "cat": 2, "saw": 1})

    def test_empty_text(self):
        self.assertEqual(count_words(""), {})


class TopWordsTest(unittest.TestCase):
    def test_most_frequent_first(self):
        self.assertEqual(top_words("b a b c b a", 2), [("b", 3), ("a", 2)])

    def test_ties_in_alphabetical_order(self):
        self.assertEqual(top_words("pear apple fig", 3), [("apple", 1), ("fig", 1), ("pear", 1)])

    def test_n_of_zero(self):
        self.assertEqual(top_words("a b c", 0), [])

    def test_n_above_distinct_words(self):
        self.assertEqual(top_words("a b a", 5), [("a", 2), ("b", 1)])


if __name__ == "__main__":
    unittest.main()
PY
commit "tally with top_words"
mark="$(git log -1 --format='%cs, %h')"
mkdir -p .scratch
# The plan is written in three parts, so step 1's first line can carry the
# commit's mark without an in-place edit.
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

### Slice 1: Most frequent words
Delivers criteria 1: `top_words` and its tests

MD
printf '%s\n' "1. Add \`top_words(text, n)\`. Criteria: 1 Done: $mark." >> .scratch/text-stats-plan.md
cat >> .scratch/text-stats-plan.md <<'MD'
   - Files: `tally/counter.py` (`top_words`, new), `tests/test_counter.py` (`TopWordsTest`, new)
   - Test first: `TopWordsTest`, through `top_words`: most frequent first, ties in alphabetical order, `n` of 0, and `n` above the number of distinct words.
   - Done when: `python3 -m unittest tests.test_counter.TopWordsTest -v` passes and `make test` stays green.

### Slice 2: Distinct and longest words
Delivers criteria 2, 3: `distinct_words` and `longest_words` with their tests

2. Add `distinct_words(text)`. Criteria: 2
   - Files: `tally/counter.py` (`distinct_words`, new), `tests/test_counter.py` (`DistinctWordsTest`, new)
   - Test first: `DistinctWordsTest`, through `distinct_words`: a text that repeats a word in two cases counts it once, and an empty text gives 0.
   - Done when: `python3 -m unittest tests.test_counter.DistinctWordsTest -v` passes and `make test` stays green.

3. Add `longest_words(text)`. Criteria: 3
   - Files: `tally/counter.py` (`longest_words`, new), `tests/test_counter.py` (`LongestWordsTest`, new)
   - Test first: `LongestWordsTest`, through `longest_words`: one longest word, two of the same length in alphabetical order, a longest word that repeats listed once, and an empty text.
   - Done when: `python3 -m unittest tests.test_counter.LongestWordsTest -v` passes and `make test` stays green.

### Slice 3: Command line
Delivers criteria 4: the `python3 -m tally.cli` summary

4. Add the command-line module. Criteria: 4
   - Files: `tally/cli.py` (new: `main(argv)`, and the `__main__` guard that exits with its result), `tests/test_cli.py` (`CliTest`, new), `README.md` (a Usage section with the command and a sample of its output)
   - Test first: `CliTest`, through `main` with a temporary file and captured stdout and stderr: the three lines for a known text, the usage line and status 2 with no path, and the same for a path that does not exist.
   - Done when: `python3 -m unittest tests.test_cli -v` passes and `make test` stays green.
MD
