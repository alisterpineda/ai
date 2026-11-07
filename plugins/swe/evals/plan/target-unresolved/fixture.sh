#!/usr/bin/env bash
# Same repository as target-no-plan. The prompt names a spec path with a typo
# (top-word for top-words): the run must stop and name it, not read it as
# context and plan from the empty conversation.
exec bash "$(dirname "$0")/../target-no-plan/fixture.sh"
