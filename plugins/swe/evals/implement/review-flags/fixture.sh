#!/usr/bin/env bash
# Same repository as the no-review case. --review-model and --review-effort
# must reach the review's subagent, the engine's arguments, and the report.
exec bash "$(dirname "$0")/../no-review/fixture.sh"
