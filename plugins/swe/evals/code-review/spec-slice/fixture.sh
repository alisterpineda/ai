#!/usr/bin/env bash
# Builds this case's repository in the current (empty) directory.
set -euo pipefail
git init -q -b main
git config user.name "Fixture Dev"; git config user.email dev@example.com
git config commit.gpgsign false
commit() { git add -A && GIT_AUTHOR_DATE=2026-10-01T10:00:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00 git commit -q -m "$1"; }
# Spec with slices. Diff targets slice 1 (AC1-3). Planted: AC2 unmet (window
# resets after 3600s, not 60), scope creep against both non-goals (global
# limit, persisted state), AC5 delivered early via from_env().
mkdir -p src docs
cat > docs/rate-limit-spec.md <<'MD'
# Per-client rate limiting

## Problem
One noisy API client can exhaust the service for everyone; nothing limits how often a single client calls.

## Goals
- Limit each API client to a fixed number of requests per minute.

## Non-goals
- A global limit shared across all clients.
- Persisting limiter state across process restarts.

## Decisions
1. Fixed one-minute window per client: simplest to reason about, and bursts at window edges are acceptable for now.
2. In-memory state only: a restart forgiving every client is acceptable.

## Acceptance criteria
1. `RateLimiter.allow(client_id)` returns True for the first `limit` calls by a client within its window and False after that.
2. Each client's window resets 60 seconds after the first call in that window.
3. Limits are tracked per client: one client exhausting its limit does not affect any other client.
4. The HTTP middleware responds 429 with a `Retry-After` header (whole seconds until the window resets) when `allow` returns False.
5. The limit is read from the `RATE_LIMIT_PER_MINUTE` environment variable, defaulting to 60.

## Open questions
- Should limits differ per client tier?: paid clients may need more.

## Slices
1. Limiter core: the in-memory limiter class. Criteria: 1, 2, 3
2. HTTP integration: the middleware and configuration. Criteria: 4, 5
MD
cat > src/__init__.py <<'PY'
PY
commit "Add rate limiting spec"
cat > src/ratelimit.py <<'PY'
import json
import os
import time

WINDOW_SECONDS = 3600


class RateLimiter:
    def __init__(self, limit, global_limit=None, clock=time.monotonic):
        self.limit = limit
        self.global_limit = global_limit
        self.clock = clock
        self._windows = {}  # client_id -> [window_start, count]
        self._global_count = 0

    @classmethod
    def from_env(cls):
        return cls(int(os.environ.get("RATE_LIMIT_PER_MINUTE", "60")))

    def allow(self, client_id):
        now = self.clock()
        window = self._windows.get(client_id)
        if window is None or now - window[0] >= WINDOW_SECONDS:
            window = [now, 0]
            self._windows[client_id] = window
        if self.global_limit is not None and self._global_count >= self.global_limit:
            return False
        if window[1] >= self.limit:
            return False
        window[1] += 1
        self._global_count += 1
        return True

    def save_state(self, path):
        with open(path, "w") as f:
            json.dump({"windows": self._windows, "global": self._global_count}, f)

    def load_state(self, path):
        with open(path) as f:
            data = json.load(f)
        self._windows = data["windows"]
        self._global_count = data["global"]
PY
commit "Add the rate limiter core"
