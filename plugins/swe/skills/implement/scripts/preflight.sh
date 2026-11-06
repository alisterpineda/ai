#!/usr/bin/env bash
# preflight.sh — parse implement's arguments and check that the run may start.
#
# Usage: preflight.sh [--review] [--slice N|all] [--review-model NAME]
#                     [--review-effort LEVEL] [<target>]
#
#   Flags may come in any order and on either side of the target; valued flags
#   take `--flag value` or `--flag=value`. The skill passes its arguments here
#   unchanged, so every argument rule lives in this script.
#
#   --review              run the review-and-fix loop after building.
#   --slice N|all         build slice N of the spec, or every unfinished slice.
#   --review-model NAME   reviewer/verifier model; needs --review. Passed to
#                         code-review-core's --model, not validated here.
#   --review-effort LEVEL low, medium, high, xhigh, or max; needs --review.
#
#   <target>  a spec file path, an Azure DevOps work-item URL, or a GitHub
#             issue URL. None means the plan agreed in the conversation.
#             Classifying it is the skill's job. This script only requires
#             --slice to come with a readable spec file (tickets and the
#             conversation become specs without slices) and checks the slice
#             number against it.
#
# Then checks that the working tree is clean: nothing staged, nothing
# modified, no untracked files (ignored files don't count). An untracked
# directory is listed once, not file by file. The review reads
# every uncommitted change as the run's own work, so the run may only start
# from a clean tree.
#
# Prints a manifest on stdout.
#
# Exit codes: 0 ready · 2 argument error · 3 cannot start (not a git
#             repository, or the tree is not clean) · 1 unexpected failure

set -u

die() { local code=$1; shift; printf 'implement: %s\n' "$*" >&2; exit "$code"; }

flags_help="supported flags: --review, --slice <n|all>, --review-model <name>, --review-effort <level>, in any order around at most one target"
target=""
have_target=0
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
    *) [ "$have_target" -eq 0 ] || die 2 "expected at most one target, got '$target' and '$1' ($flags_help)"
       target=$1; have_target=1; shift;;
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
  { [ "$have_target" -eq 1 ] && [ -f "$target" ] && [ -r "$target" ]; } ||
    die 2 "--slice needs a spec file as the target; tickets and the conversation have no slices ($flags_help)"
  # Slice numbers are the numbered items under the spec's `## Slices` heading.
  # This parser is a copy of the one in code-review-core's scripts/snapshot.sh,
  # which the review loop calls with --slice: change both together.
  slices=$(awk '
    /^##[^#]/ { ins = ($0 ~ /^##[[:space:]]+Slices[[:space:]]*$/); next }
    ins && /^[[:space:]]*[0-9]+\./ { s = $0; sub(/^[[:space:]]*/, "", s); sub(/\..*/, "", s); print s + 0 }
  ' "$target")
  [ -n "$slices" ] || die 2 "--slice $slice: '$target' has no slices (no numbered items under a '## Slices' heading)"
  if [ "$slice" != all ]; then
    printf '%s\n' "$slices" | grep -qx "$slice" ||
      die 2 "--slice $slice: '$target' has no slice $slice; its slices are $(printf '%s\n' "$slices" | paste -sd, - | sed 's/,/, /g')"
  fi
fi

toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die 3 "not inside a git repository; implement starts from a clean git working tree"
cd "$toplevel" || die 1 "cannot enter $toplevel"

dirty=$(git -c core.quotePath=false status --porcelain --untracked-files=normal) || die 1 "git status failed"
if [ -n "$dirty" ]; then
  {
    printf 'implement: the working tree is not clean. Commit or stash these first, then run again:\n'
    printf '%s\n' "$dirty" | sed 's/^/  /'
  } >&2
  exit 3
fi

branch=$(git symbolic-ref --quiet --short HEAD) || branch="(detached)"
head=$(git rev-parse --verify --quiet HEAD^{commit}) || head="(no commits)"

printf 'repo: %s\n' "$toplevel"
printf 'branch: %s\n' "$branch"
printf 'head: %s\n' "$head"
if [ "$have_target" -eq 1 ]; then printf 'target: %s\n' "$target"; else printf 'target: conversation\n'; fi
if [ "$review" -eq 1 ]; then printf 'review: yes\n'; else printf 'review: no\n'; fi
printf 'slice: %s\n' "${slice:-none}"
printf 'review-model: %s\n' "${review_model:-inherit}"
printf 'review-effort: %s\n' "${review_effort:-inherit}"
