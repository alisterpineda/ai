#!/usr/bin/env bash
# preflight.sh — parse implement's arguments and check that the run may start.
#
# Usage: preflight.sh [--review] [--slice N|all] [--review-model NAME]
#                     [--review-effort LEVEL] [<word> …]
#
#   Flags may come in any order, before, between, or after the words; valued flags
#   take `--flag value` or `--flag=value`. The skill passes its arguments here
#   unchanged, so every argument rule lives in this script.
#
#   --review              run the review-and-fix loop after building.
#   --slice N|all         build slice N of the spec, or every unfinished slice.
#   --review-model NAME   reviewer/verifier model; needs --review. Passed to
#                         code-review-core's --model, not validated here.
#   --review-effort LEVEL low, medium, high, xhigh, or max; needs --review.
#
#   <word> …  everything that isn't a flag: the targets (spec files, Azure
#             DevOps work-item URLs, GitHub issue URLs) and any context after
#             them, or nothing for the plan agreed in the conversation.
#             Reading them is the skill's job, by judgment; this script only
#             passes them on, in order, one `text:` line per argument, so a
#             quoted path with a space stays whole. Whether
#             a --slice number exists in the spec is checked by the skill too,
#             once the spec is settled.
#
# The working tree may hold uncommitted changes: the skill records the tree
# before it builds (scripts/start-tree.sh) and reviews only what changed since.
#
# Prints a manifest on stdout. It ends with the changes already uncommitted
# when the run was invoked (git status lines; an untracked directory is listed
# once, not file by file), or none: the report names them, so nobody takes them for the run's work. The
# list comes from here, before the run writes its spec or runs the project's
# checks, so neither shows up in it.
#
# Exit codes: 0 ready · 2 argument error · 3 not a git repository ·
#             1 unexpected failure

set -u

die() { local code=$1; shift; printf 'implement: %s\n' "$*" >&2; exit "$code"; }

flags_help="supported flags: --review, --slice <n|all>, --review-model <name>, --review-effort <level>, in any order around the targets"
words=()
review=0 slice="" review_model="" review_effort=""
have_slice=0 have_model=0 have_effort=0
while [ $# -gt 0 ]; do
  case "$1" in
    --review=*) die 2 "--review takes no value ($flags_help)";;
    --*=*) flag=${1%%=*}; value=${1#*=}; shift; set -- "$flag" "$value" "$@"; continue;;
  esac
  case "$1" in
    --review) review=1; shift;;
    --slice|--review-model|--review-effort)
      { [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != --* ]]; } || die 2 "$1 needs a value ($flags_help)"
      case "$1" in
        --slice) slice=$2; have_slice=1;;
        --review-model) review_model=$2; have_model=1;;
        --review-effort) review_effort=$2; have_effort=1;;
      esac
      shift 2;;
    -*) die 2 "unknown flag '$1' ($flags_help)";;
    *) words+=("$1"); shift;;
  esac
done

# Flag values, checked before any git work so an argument error never waits on
# the repository.
if [ "$review" -eq 0 ]; then
  [ "$have_model" -eq 0 ] || die 2 "--review-model needs --review ($flags_help)"
  [ "$have_effort" -eq 0 ] || die 2 "--review-effort needs --review ($flags_help)"
fi
if [ "$have_effort" -eq 1 ]; then
  case "$review_effort" in
    low|medium|high|xhigh|max) ;;
    *) die 2 "'$review_effort' is not a valid --review-effort level: use low, medium, high, xhigh, or max";;
  esac
fi
if [ "$have_slice" -eq 1 ]; then
  [[ "$slice" == all || "$slice" =~ ^[1-9][0-9]*$ ]] || die 2 "--slice takes a slice number or 'all', got '$slice'"
fi

toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die 3 "not inside a git repository"
cd "$toplevel" || die 1 "cannot enter $toplevel"

uncommitted=$(git -c core.quotePath=false status --porcelain --untracked-files=normal) || die 1 "git status failed"

branch=$(git symbolic-ref --quiet --short HEAD) || branch="(detached)"
head=$(git rev-parse --verify --quiet HEAD^{commit}) || head="(no commits)"

printf 'repo: %s\n' "$toplevel"
printf 'branch: %s\n' "$branch"
printf 'head: %s\n' "$head"
if [ "${#words[@]}" -gt 0 ]; then printf 'text: %s\n' "${words[@]}"; else printf 'text: none\n'; fi
if [ "$review" -eq 1 ]; then printf 'review: yes\n'; else printf 'review: no\n'; fi
printf 'slice: %s\n' "${slice:-none}"
printf 'review-model: %s\n' "${review_model:-inherit}"
printf 'review-effort: %s\n' "${review_effort:-inherit}"
printf 'uncommitted:\n'
if [ -n "$uncommitted" ]; then printf '%s\n' "$uncommitted"; else printf 'none\n'; fi
