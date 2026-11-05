#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Planted rule breaks: datetime.now() (rule 1), echo not registered in HANDLERS
# (rule 2, also a correctness bug: unroutable), print() (rule 4). Rule 3
# (VERSION bump) is FOLLOWED. Smell: validation block duplicated from ping.py.
mkdir -p src/handlers
cat > CLAUDE.md <<'MD'
# Message service

## Rules
- Use `now_utc()` from `src/clock.py` for every timestamp; never call `datetime.now()` or `datetime.utcnow()` directly (they produce naive or local times that break ordering across hosts).
- Every handler module in `src/handlers/` must be added to `HANDLERS` in `src/handlers/__init__.py`, or the dispatcher never routes to it.
- Bump `VERSION` in any commit that changes files under `src/`.
- Log through `get_logger(__name__)` from `src/log.py`; no `print()` anywhere in `src/`.
MD
echo "1.2.0" > VERSION
cat > src/clock.py <<'PY'
from datetime import datetime, timezone


def now_utc():
    return datetime.now(timezone.utc)
PY
cat > src/log.py <<'PY'
import logging


def get_logger(name):
    return logging.getLogger(name)
PY
cat > src/handlers/ping.py <<'PY'
from src.clock import now_utc
from src.log import get_logger

log = get_logger(__name__)


def handle(payload):
    if not isinstance(payload, dict):
        raise ValueError("payload must be an object")
    if "id" not in payload:
        raise ValueError("payload needs an id")
    log.info("ping %s", payload["id"])
    return {"id": payload["id"], "pong": True, "at": now_utc().isoformat()}
PY
cat > src/handlers/__init__.py <<'PY'
from src.handlers import ping

HANDLERS = {
    "ping": ping.handle,
}


def dispatch(kind, payload):
    try:
        handler = HANDLERS[kind]
    except KeyError:
        raise ValueError(f"no handler for {kind!r}")
    return handler(payload)
PY
commit "Message service with ping handler"
echo "1.3.0" > VERSION
cat > src/handlers/echo.py <<'PY'
from datetime import datetime


def handle(payload):
    if not isinstance(payload, dict):
        raise ValueError("payload must be an object")
    if "id" not in payload:
        raise ValueError("payload needs an id")
    print("echo", payload["id"])
    return {"id": payload["id"], "echo": payload.get("text", ""), "at": datetime.now().isoformat()}
PY
commit "Add echo handler"
