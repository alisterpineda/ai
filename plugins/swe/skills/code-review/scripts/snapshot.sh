#!/usr/bin/env bash
# snapshot.sh — parse /swe:code-review's arguments, resolve the review target,
# and freeze its diff.
#
# Usage: snapshot.sh [--snapshots DIR] [--spec PATH|URL] [--slice N]
#                    [--model NAME] [--effort LEVEL] [<target>]
#
#   Flags may come in any order and on either side of the target, as
#   `--flag value` or `--flag=value`. The orchestrator passes the review's
#   arguments here unchanged, so every argument rule lives in this script.
#
#   --snapshots DIR  parent directory for the snapshot. Agent harnesses that
#                    give the session a scratchpad don't expose it to scripts,
#                    so pass it here. Without it: $REVIEW_SNAPSHOT_DIR, then
#                    $TMPDIR, then /tmp, the first one that is writable
#                    (sandboxes often make $TMPDIR read-only).
#   --spec PATH|URL  spec to review against: a readable file, or a GitHub
#                    issue or Azure DevOps work-item URL (printed as given;
#                    the orchestrator fetches it).
#   --slice N        a slice number; needs --spec. The spec reviewer finds the
#                    slice in whatever shape the spec uses.
#   --model NAME     reviewer/verifier model; passed through, not validated.
#   --effort LEVEL   low, medium, high, xhigh, or max.
#
#   (none)        staged changes if anything is staged, else all uncommitted
#                 changes including untracked files
#   <branch|tag>  what HEAD adds relative to that ref (merge-base diff)
#   <A..B|A...B>  that range's diff
#   <commit>      that commit's own change (merge: against first parent;
#                 root: against the empty tree)
#
# Creates a fresh temporary directory and writes:
#   diff.patch      git's patch, for machines (git apply parses it)
#   numbered.diff   the same patch with each hunk line prefixed by its old and
#                   new line numbers; reviewers read and cite this one
#   log.txt         the commit messages behind a committed target (none for
#                   staged or uncommitted changes)
#   uncaptured.txt  untracked files that could not be captured, if any
# Prints a manifest on stdout (the parsed flags included) and never prints the
# diff or the log.
#
# An untracked file over $REVIEW_UNTRACKED_MAX_BYTES (default 262144) is left
# out and listed as uncaptured with its size: it is usually a generated file,
# dump, or log the user never meant to add, and every reviewer would read it.
#
# Exit codes: 0 snapshot ready · 2 argument error · 3 nothing to review ·
#             1 unexpected failure

set -u

die() { local code=$1; shift; printf 'snapshot: %s\n' "$*" >&2; exit "$code"; }

flags_help="supported flags: --spec <path or ticket URL>, --slice <n>, --model <name>, --effort <level>, in any order around one target"
log_max_commits="${REVIEW_LOG_MAX_COMMITS:-100}"
untracked_max_bytes="${REVIEW_UNTRACKED_MAX_BYTES:-262144}"
target=""
have_target=0
snapshots="" spec="" slice="" model="" effort=""
have_spec=0 have_slice=0
while [ $# -gt 0 ]; do
  case "$1" in
    --*=*) flag=${1%%=*}; value=${1#*=}; shift; set -- "$flag" "$value" "$@"; continue;;
  esac
  case "$1" in
    --snapshots|--spec|--slice|--model|--effort)
      { [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != --* ]]; } || die 2 "$1 needs a value ($flags_help)"
      case "$1" in
        --snapshots) snapshots=$2;;
        --spec) spec=$2; have_spec=1;;
        --slice) slice=$2; have_slice=1;;
        --model) model=$2;;
        --effort) effort=$2;;
      esac
      shift 2;;
    -*) die 2 "unknown flag '$1' ($flags_help)";;
    *) [ "$have_target" -eq 0 ] || die 2 "expected at most one target, got '$target' and '$1' ($flags_help)"
       target=$1; have_target=1; shift;;
  esac
done

# Flag values, checked before any git work so an argument error never waits on
# the repository. Relative paths resolve against the caller's directory.
if [ -n "$effort" ]; then
  case "$effort" in
    low|medium|high|xhigh|max) ;;
    *) die 2 "'$effort' is not a valid --effort level: use low, medium, high, xhigh, or max";;
  esac
fi
if [ "$have_slice" -eq 1 ] && [ "$have_spec" -eq 0 ]; then
  die 2 "--slice needs --spec ($flags_help)"
fi
github_issue='^https://github\.com/[^/]+/[^/]+/issues/[0-9]+([?#].*)?$'
ado_item='^https://(dev\.azure\.com/[^/]+|[^/.]+\.visualstudio\.com)/[^/]+/_workitems/edit/[0-9]+([?#].*)?$'
if [ "$have_spec" -eq 1 ]; then
  if [[ "$spec" =~ $github_issue ]] || [[ "$spec" =~ $ado_item ]]; then
    spec_abs=$spec
  elif [[ "$spec" =~ ^https?:// ]]; then
    die 2 "--spec '$spec' is not a GitHub issue or Azure DevOps work-item URL; pass one of those or a file path"
  else
    { [ -f "$spec" ] && [ -r "$spec" ]; } || die 2 "--spec '$spec' is not a readable file"
    spec_abs="$(cd "$(dirname "$spec")" && pwd)/$(basename "$spec")"
  fi
fi
if [ "$have_slice" -eq 1 ]; then
  [[ "$slice" =~ ^[1-9][0-9]*$ ]] || die 2 "--slice takes a slice number, got '$slice'"
fi
if [ -n "$snapshots" ]; then
  [ -d "$snapshots" ] || die 2 "snapshot root '$snapshots' is not a directory"
  snapshots="$(cd "$snapshots" && pwd)"
fi

toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die 2 "not inside a git repository"
cd "$toplevel" || die 1 "cannot enter $toplevel"

# Standard a/ b/ prefixes and no color, whatever the user's git config says —
# git apply --numstat and the reviewers' file:line citations depend on them.
# quotePath off keeps non-ASCII filenames literal instead of octal-escaped.
# suppressBlankEmpty off keeps every context line's leading space, which the
# numbering below relies on.
git=(git -c diff.noprefix=false -c diff.mnemonicPrefix=false -c color.diff=false
     -c core.quotePath=false -c diff.suppressBlankEmpty=false)
# Never run a repo-configured external diff driver or textconv filter: the
# snapshot must be git's own patch, and this script runs unattended.
diffopts=(--no-ext-diff --no-textconv)
empty_tree=$(git hash-object -t tree /dev/null)

is_ref() {
  git show-ref --verify --quiet "refs/heads/$1" ||
  git show-ref --verify --quiet "refs/remotes/$1" ||
  git show-ref --verify --quiet "refs/tags/$1"
}

# logcmd selects the commits whose messages state the change's intent; it stays
# empty for staged and uncommitted changes, which have no messages yet.
untracked=0
logcmd=()
if [ -z "$target" ]; then
  if ! git diff --cached --quiet 2>/dev/null; then
    scope="staged changes"
    cmd=(diff --cached)
  else
    base=$(git rev-parse --verify --quiet HEAD^{commit}) || base=$empty_tree
    scope="uncommitted changes"
    cmd=(diff "$base")
    untracked=1
  fi
elif [[ "$target" == *..* ]]; then
  # Validate each endpoint as a commit; a bare rev-parse of the whole token would
  # happily accept a path that merely contains "..".
  left=${target%%..*}; right=${target#"$left"..}; right=${right#.}
  for side in "${left:-HEAD}" "${right:-HEAD}"; do
    git rev-parse --verify --quiet "$side^{commit}" >/dev/null || die 2 "cannot resolve '$side' in range '$target'"
  done
  scope="range $target"
  cmd=(diff "$target")
  if [[ "$target" == *...* ]]; then
    # A three-dot diff runs from the merge base, so its log does too.
    mb=$(git merge-base "${left:-HEAD}" "${right:-HEAD}") || die 2 "'$target' has no merge base"
    logcmd=("$mb..${right:-HEAD}")
  else
    logcmd=("${left:-HEAD}..${right:-HEAD}")
  fi
elif is_ref "$target"; then
  git rev-parse --verify --quiet HEAD^{commit} >/dev/null || die 2 "no HEAD to compare against '$target'"
  scope="changes on HEAD relative to $target (merge base)"
  cmd=(diff "$target...HEAD")
  logcmd=("$target..HEAD")
elif commit=$(git rev-parse --verify --quiet "$target^{commit}"); then
  short=$(git rev-parse --short "$commit")
  parents=$(git rev-list --parents -n 1 "$commit" | wc -w)
  parents=$((parents - 1))
  if [ "$parents" -eq 0 ]; then
    scope="commit $short (root commit, against the empty tree)"
    cmd=(diff "$empty_tree" "$commit")
    logcmd=(-1 "$commit")
  elif [ "$parents" -ge 2 ]; then
    scope="commit $short (merge, against first parent)"
    cmd=(diff "$commit^1" "$commit")
    # The diff carries everything the merge brought in, so the log does too.
    logcmd=("$commit^1..$commit")
  else
    scope="commit $short"
    cmd=(diff "$commit^1" "$commit")
    logcmd=(-1 "$commit")
  fi
else
  die 2 "'$target' is not a branch, tag, commit, or commit range (paths are not supported)"
fi

# The first candidate root where a directory can actually be created wins. An
# explicit --snapshots is the only candidate when given.
if [ -n "$snapshots" ]; then
  roots=("$snapshots")
else
  roots=()
  [ -n "${REVIEW_SNAPSHOT_DIR:-}" ] && roots+=("$REVIEW_SNAPSHOT_DIR")
  [ -n "${TMPDIR:-}" ] && roots+=("$TMPDIR")
  roots+=(/tmp)
fi
snap=""
for root in "${roots[@]}"; do
  [ -d "$root" ] || continue
  snap=$(mktemp -d "$root/code-review-snapshot.XXXXXX" 2>/dev/null) && break
  snap=""
done
[ -n "$snap" ] || die 1 "cannot create a snapshot directory in any of: ${roots[*]}"
patch="$snap/diff.patch"

"${git[@]}" "${cmd[@]}" "${diffopts[@]}" > "$patch" || { rm -rf "$snap"; die 1 "git ${cmd[*]} failed"; }

if [ "$untracked" -eq 1 ]; then
  # Each path goes through a variable, never into command text: filenames are
  # untrusted and may hold spaces, non-ASCII bytes, or shell metacharacters.
  # `git diff --no-index` exits 1 both when it wrote a hunk and when it could
  # not read the file, so success is judged by bytes appended.
  while IFS= read -r -d '' p; do
    size=$(wc -c < "$p" 2>/dev/null | tr -d ' ')
    if [ -n "$size" ] && [ "$size" -gt "$untracked_max_bytes" ]; then
      printf '%s (%s bytes, over %s)\n' "$p" "$size" "$untracked_max_bytes" >> "$snap/uncaptured.txt"
      continue
    fi
    before=$(wc -c < "$patch")
    "${git[@]}" diff "${diffopts[@]}" --no-index -- /dev/null "$p" >> "$patch" 2>/dev/null
    after=$(wc -c < "$patch")
    [ "$after" -gt "$before" ] || printf '%s\n' "$p" >> "$snap/uncaptured.txt"
  done < <(git ls-files -z --others --exclude-standard)
fi

if [ ! -s "$patch" ]; then
  if [ -s "$snap/uncaptured.txt" ]; then
    skipped=$(paste -sd ';' "$snap/uncaptured.txt")
    rm -rf "$snap"
    die 3 "nothing to review: the only changes are untracked files that could not be captured: $skipped"
  fi
  rm -rf "$snap"
  [ -z "$target" ] && die 3 "nothing to review: the working tree is clean (pass a branch, commit, or commit range to review something else)"
  die 3 "nothing to review: '$target' resolves to an empty diff ($scope)"
fi

# File map from the frozen patch. Prefixes and quoting are forced above, so
# git apply always parses it; if it ever does not, the snapshot is unusable.
files=$("${git[@]}" apply --numstat "$patch") || { rm -rf "$snap"; die 1 "git apply could not parse $patch"; }

# Numbered copy for reviewers: "<old> <new> | <patch line>". Hunk bodies are
# walked by the counts in their @@ header, never by pattern, because a removed
# line whose text starts with "-- " reads as "--- " and would pass for a file
# header. Lines outside hunks get blank number columns.
awk '
  function cols(o, n) { return sprintf("%6s %6s | ", o, n) }
  BEGIN { print "#  old    new | patch line  (cite the new number for + and context lines, the old number for - lines)" }
  rem_old > 0 || rem_new > 0 {
    c = substr($0, 1, 1)
    if (c == "+") { printf "%s%s\n", cols("", new), $0; new++; rem_new--; next }
    if (c == "-") { printf "%s%s\n", cols(old, ""), $0; old++; rem_old--; next }
    if (c == "\\") { printf "%s%s\n", cols("", ""), $0; next }
    printf "%s%s\n", cols(old, new), $0; old++; new++; rem_old--; rem_new--; next
  }
  /^@@ -[0-9]/ {
    h = $0; sub(/^@@ -/, "", h); split(h, part, " ")
    k = split(part[1], o, ","); old = o[1] + 0; rem_old = (k > 1) ? o[2] + 0 : 1
    sub(/^\+/, "", part[2])
    k = split(part[2], n, ","); new = n[1] + 0; rem_new = (k > 1) ? n[2] + 0 : 1
  }
  { printf "%s%s\n", cols("", ""), $0 }
' "$patch" > "$snap/numbered.diff" || { rm -rf "$snap"; die 1 "could not number $patch"; }

# Size from the same numstat. Binary rows carry "-" for both counts.
read -r nfiles added deleted < <(printf '%s\n' "$files" | awk '
  { n++; if ($1 != "-") a += $1; if ($2 != "-") d += $2 }
  END { printf "%d %d %d\n", n, a, d }')
lines=$((added + deleted))

# Commit messages, oldest first so they read as the change's story. Capped:
# a long branch's early messages say little about its final state.
if [ "${#logcmd[@]}" -gt 0 ]; then
  ncommits=$(git rev-list --count "${logcmd[@]}") || { rm -rf "$snap"; die 1 "git rev-list ${logcmd[*]} failed"; }
  "${git[@]}" log --reverse --format='commit %h%n%B' --max-count="$log_max_commits" "${logcmd[@]}" > "$snap/log.txt" ||
    { rm -rf "$snap"; die 1 "git log ${logcmd[*]} failed"; }
  if [ "$ncommits" -gt "$log_max_commits" ]; then
    log="$snap/log.txt ($ncommits commits; the newest $log_max_commits kept)"
  else
    log="$snap/log.txt ($ncommits commits)"
  fi
else
  log="none ($scope have no commit messages)"
fi

printf 'snapshot: %s\n' "$snap"
printf 'scope: %s\n' "$scope"
printf 'diff: %s\n' "$snap/numbered.diff"
printf 'size: %d files, %d lines changed (%d added, %d deleted)\n' "$nfiles" "$lines" "$added" "$deleted"
printf 'log: %s\n' "$log"
if [ "$have_spec" -eq 1 ]; then printf 'spec: %s\n' "$spec_abs"; else printf 'spec: none\n'; fi
printf 'slice: %s\n' "${slice:-none}"
printf 'model: %s\n' "${model:-default}"
printf 'effort: %s\n' "${effort:-inherit}"
printf 'files (added\tdeleted\tpath; - for binary):\n%s\n' "$files"
printf 'uncaptured untracked files:\n'
if [ -s "$snap/uncaptured.txt" ]; then cat "$snap/uncaptured.txt"; else printf 'none\n'; fi
