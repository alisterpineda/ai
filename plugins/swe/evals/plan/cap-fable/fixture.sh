#!/usr/bin/env bash
# Same repository as the plan-shape case. Run on a Fable session, with no
# --review-model: every subagent must run on Opus, the delegate model for
# Fable.
exec bash "$(dirname "$0")/../plan-shape/fixture.sh"
