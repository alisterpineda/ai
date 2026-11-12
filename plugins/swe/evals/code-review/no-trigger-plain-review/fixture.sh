#!/usr/bin/env bash
# Same repository as the correctness case. A plain request for a review must
# not fire swe:code-review-core, which only a skill's instructions call.
exec bash "$(dirname "$0")/../correctness/fixture.sh"
