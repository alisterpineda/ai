#!/usr/bin/env bash
# Same repository as the no-review case. --review was the removed implement's
# flag: the run must stop on it and name the flags it takes.
exec bash "$(dirname "$0")/../no-review/fixture.sh"
