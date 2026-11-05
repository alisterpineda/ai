#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Planted: SQL injection (search_users), off-by-one page_count, swallowed
# exception returning None into app.py's cfg["timeout"], ms-vs-s unit bug.
mkdir -p src tests
cat > src/store.py <<'PY'
import sqlite3


def connect(path):
    return sqlite3.connect(path)


def find_user(conn, name):
    cur = conn.execute("SELECT id, name FROM users WHERE name = ?", (name,))
    return cur.fetchone()
PY
cat > src/paging.py <<'PY'
def paginate(items, page, per_page=20):
    """Return the items on 1-based page `page`."""
    start = (page - 1) * per_page
    return items[start:start + per_page]
PY
cat > src/config.py <<'PY'
import json


def load_config(path):
    with open(path) as f:
        return json.load(f)
PY
cat > src/app.py <<'PY'
import time

from src.config import load_config


def run(config_path, job):
    cfg = load_config(config_path)
    retries = cfg["retries"]
    for attempt in range(retries + 1):
        if job():
            return True
        time.sleep(1)
    return False
PY
cat > tests/test_paging.py <<'PY'
from src.paging import paginate


def test_first_page():
    assert paginate(list(range(50)), 1, 20) == list(range(20))
PY
commit "Initial store, paging, config, and job runner"
cat > src/store.py <<'PY'
import sqlite3


def connect(path):
    return sqlite3.connect(path)


def find_user(conn, name):
    cur = conn.execute("SELECT id, name FROM users WHERE name = ?", (name,))
    return cur.fetchone()


def search_users(conn, prefix):
    """Return (id, name) rows whose name starts with `prefix`, used by the
    public /users/search?q= endpoint."""
    cur = conn.execute(f"SELECT id, name FROM users WHERE name LIKE '{prefix}%'")
    return cur.fetchall()
PY
cat > src/paging.py <<'PY'
def paginate(items, page, per_page=20):
    """Return the items on 1-based page `page`."""
    start = (page - 1) * per_page
    return items[start:start + per_page]


def page_count(total, per_page=20):
    """Return the number of pages needed to show `total` items."""
    return total // per_page
PY
cat > src/config.py <<'PY'
import json


def load_config(path):
    """Load the JSON config at `path`. A missing or malformed file is not
    fatal."""
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None


def retry_delay_seconds(cfg):
    """Delay between retries, in seconds."""
    return cfg.get("retry_delay_ms", 500)
PY
cat > src/app.py <<'PY'
import time

from src.config import load_config, retry_delay_seconds


def run(config_path, job):
    cfg = load_config(config_path)
    retries = cfg["retries"]
    for attempt in range(retries + 1):
        if job():
            return True
        time.sleep(retry_delay_seconds(cfg))
    return False
PY
cat > tests/test_paging.py <<'PY'
from src.paging import page_count, paginate


def test_first_page():
    assert paginate(list(range(50)), 1, 20) == list(range(20))


def test_page_count_exact():
    assert page_count(40, 20) == 2
PY
commit "Add user prefix search, page count, configurable retry delay, and tolerant config loading"
