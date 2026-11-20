#!/usr/bin/env bash
# Same repository as the fix case. --fix is no flag of this skill: the run
# must stop on it and name the flags it takes.
exec bash "$(dirname "$0")/../fix/fixture.sh"
