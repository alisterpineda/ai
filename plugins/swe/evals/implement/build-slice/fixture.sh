#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
source "$(dirname "$0")/../textkit.sh"
# Stats spec, slice 1 Done. --slice 2 must build only line_count (not
# top_words). Planted: tests/test_legacy.py already fails before the run; the
# baseline must show it, and the run must leave it alone.
stats_module
cat > textkit/legacy.py <<'PY'
def title_case(text):
    """Return `text` with every word capitalised."""
    return text.capitalize()
PY
cat > tests/test_legacy.py <<'PY'
import unittest

from textkit.legacy import title_case


class TitleCaseTest(unittest.TestCase):
    def test_every_word(self):
        self.assertEqual(title_case("hello big world"), "Hello Big World")


if __name__ == "__main__":
    unittest.main()
PY
commit "textkit: counting, plus legacy title_case"
