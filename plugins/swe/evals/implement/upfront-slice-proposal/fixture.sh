#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# Stats spec: slice 1 is marked Done; slice 2 has no marker but the code and
# tests already meet criterion 3. With no --slice, the run proposes slice 3,
# explains why 1 and 2 count as finished, and waits.
stats_module
cat >> textkit/stats.py <<'PY'


def line_count(text):
    """Return the number of lines in `text`; a trailing newline adds none."""
    return len(text.splitlines())
PY
cat > tests/test_lines.py <<'PY'
import unittest

from textkit.stats import line_count


class LineCountTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(line_count(""), 0)

    def test_two_lines(self):
        self.assertEqual(line_count("a\nb"), 2)

    def test_trailing_newline(self):
        self.assertEqual(line_count("a\n"), 1)


if __name__ == "__main__":
    unittest.main()
PY
commit "textkit: counting and lines"
