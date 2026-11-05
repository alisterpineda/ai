#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# A correct, tested, documented change. Any confirmed finding is a false positive.
mkdir -p src tests
cat > README.md <<'MD'
# itertools-extra

Small iteration helpers.
MD
cat > src/__init__.py <<'PY'
PY
cat > src/iters.py <<'PY'
def first(iterable, default=None):
    """Return the first item of `iterable`, or `default` if it is empty."""
    for item in iterable:
        return item
    return default
PY
cat > tests/test_iters.py <<'PY'
from src.iters import first


def test_first():
    assert first([3, 4]) == 3
    assert first([], default=0) == 0
PY
commit "Add first()"
cat > README.md <<'MD'
# itertools-extra

Small iteration helpers.

- `first(iterable, default=None)`: the first item, or `default` when empty.
- `chunked(iterable, size)`: successive lists of at most `size` items; raises `ValueError` when `size` is not a positive integer.
MD
cat > src/iters.py <<'PY'
def first(iterable, default=None):
    """Return the first item of `iterable`, or `default` if it is empty."""
    for item in iterable:
        return item
    return default


def chunked(iterable, size):
    """Return an iterator over successive lists of at most `size` items.

    Raises ValueError immediately when `size` is not a positive integer.
    """
    if isinstance(size, bool) or not isinstance(size, int) or size < 1:
        raise ValueError(f"size must be a positive integer, got {size!r}")
    return _chunks(iterable, size)


def _chunks(iterable, size):
    chunk = []
    for item in iterable:
        chunk.append(item)
        if len(chunk) == size:
            yield chunk
            chunk = []
    if chunk:
        yield chunk
PY
cat > tests/test_iters.py <<'PY'
import pytest

from src.iters import chunked, first


def test_first():
    assert first([3, 4]) == 3
    assert first([], default=0) == 0


def test_chunked_even_and_remainder():
    assert list(chunked(range(4), 2)) == [[0, 1], [2, 3]]
    assert list(chunked(range(5), 2)) == [[0, 1], [2, 3], [4]]


def test_chunked_empty():
    assert list(chunked([], 3)) == []


@pytest.mark.parametrize("bad", [0, -1, 1.5, True, "2"])
def test_chunked_rejects_bad_size_eagerly(bad):
    with pytest.raises(ValueError):
        chunked([1, 2], bad)
PY
commit "Add chunked()"
