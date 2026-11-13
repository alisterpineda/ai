#!/usr/bin/env bash
# Same repository as the clean case. Run on a Fable session, with no --model:
# the reviewers must run on Opus, the delegate model for Fable.
exec bash "$(dirname "$0")/../clean/fixture.sh"
