#!/usr/bin/env bash
# snapshot.sh — resolve a review target and freeze its diff for the review skill.
#
# Usage: snapshot.sh [--snapshots DIR] [<target>]
#
#   --snapshots DIR  parent directory for the snapshot; overrides
#                    $REVIEW_SNAPSHOT_DIR, then $TMPDIR. Agent harnesses that give
#                    the session a scratchpad don't expose it to scripts, so pass
#                    it here.
#
#   (none)        staged changes if anything is staged, else all uncommitted
#                 changes including untracked files
#   <branch|tag>  what HEAD adds relative to that ref (merge-base diff)
#   <A..B|A...B>  that range's diff
#   <commit>      that commit's own change (merge: against first parent;
#                 root: against the empty tree)
#
# Creates a fresh temporary directory and writes <dir>/diff.patch (plus
# <dir>/uncaptured.txt when an untracked file could not be captured). Prints
# a manifest on stdout and never prints the diff itself.
#
# The manifest's `tier:` line sizes the review: `light` when the change is at
# most $REVIEW_LIGHT_MAX_FILES files (default 3) and $REVIEW_LIGHT_MAX_LINES
# changed lines, added plus deleted (default 40); `full` otherwise. A binary
# file counts as one file and zero lines.
#
# Exit codes: 0 snapshot ready · 2 argument error · 3 nothing to review ·
#             1 unexpected failure

set -u

die() { local code=$1; shift; printf 'snapshot: %s\n' "$*" >&2; exit "$code"; }

snap_root="${REVIEW_SNAPSHOT_DIR:-${TMPDIR:-/tmp}}"
light_max_files="${REVIEW_LIGHT_MAX_FILES:-3}"
light_max_lines="${REVIEW_LIGHT_MAX_LINES:-40}"
target=""
have_target=0
while [ $# -gt 0 ]; do
  case "$1" in
    --snapshots) [ $# -ge 2 ] || die 2 "--snapshots needs a directory"; snap_root=$2; shift 2;;
    -*) die 2 "unknown option '$1' (supported targets: branch, tag, commit, commit range)";;
    *) [ "$have_target" -eq 0 ] || die 2 "expected at most one target"; target=$1; have_target=1; shift;;
  esac
done

toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die 2 "not inside a git repository"
cd "$toplevel" || die 1 "cannot enter $toplevel"

# Standard a/ b/ prefixes and no color, whatever the user's git config says —
# git apply --numstat and the reviewers' file:line citations depend on them.
# quotePath off keeps non-ASCII filenames literal instead of octal-escaped.
git=(git -c diff.noprefix=false -c diff.mnemonicPrefix=false -c color.diff=false -c core.quotePath=false)
# Never run a repo-configured external diff driver or textconv filter: the
# snapshot must be git's own patch, and this script runs unattended.
diffopts=(--no-ext-diff --no-textconv)
empty_tree=$(git hash-object -t tree /dev/null)

is_ref() {
  git show-ref --verify --quiet "refs/heads/$1" ||
  git show-ref --verify --quiet "refs/remotes/$1" ||
  git show-ref --verify --quiet "refs/tags/$1"
}

untracked=0
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
elif is_ref "$target"; then
  git rev-parse --verify --quiet HEAD^{commit} >/dev/null || die 2 "no HEAD to compare against '$target'"
  scope="changes on HEAD relative to $target (merge base)"
  cmd=(diff "$target...HEAD")
elif commit=$(git rev-parse --verify --quiet "$target^{commit}"); then
  short=$(git rev-parse --short "$commit")
  parents=$(git rev-list --parents -n 1 "$commit" | wc -w)
  parents=$((parents - 1))
  if [ "$parents" -eq 0 ]; then
    scope="commit $short (root commit, against the empty tree)"
    cmd=(diff "$empty_tree" "$commit")
  elif [ "$parents" -ge 2 ]; then
    scope="commit $short (merge, against first parent)"
    cmd=(diff "$commit^1" "$commit")
  else
    scope="commit $short"
    cmd=(diff "$commit^1" "$commit")
  fi
else
  die 2 "'$target' is not a branch, tag, commit, or commit range (paths are not supported)"
fi

[ -d "$snap_root" ] || die 2 "snapshot root '$snap_root' is not a directory"
snap=$(mktemp -d "$snap_root/review-snapshot.XXXXXX") || die 1 "mktemp failed"
patch="$snap/diff.patch"

"${git[@]}" "${cmd[@]}" "${diffopts[@]}" > "$patch" || { rm -rf "$snap"; die 1 "git ${cmd[*]} failed"; }

if [ "$untracked" -eq 1 ]; then
  # Each path goes through a variable, never into command text: filenames are
  # untrusted and may hold spaces, non-ASCII bytes, or shell metacharacters.
  # `git diff --no-index` exits 1 both when it wrote a hunk and when it could
  # not read the file, so success is judged by bytes appended.
  while IFS= read -r -d '' p; do
    before=$(wc -c < "$patch")
    "${git[@]}" diff "${diffopts[@]}" --no-index -- /dev/null "$p" >> "$patch" 2>/dev/null
    after=$(wc -c < "$patch")
    [ "$after" -gt "$before" ] || printf '%s\n' "$p" >> "$snap/uncaptured.txt"
  done < <(git ls-files -z --others --exclude-standard)
fi

if [ ! -s "$patch" ]; then
  rm -rf "$snap"
  [ -z "$target" ] && die 3 "nothing to review: the working tree is clean (pass a branch, commit, or commit range to review something else)"
  die 3 "nothing to review: '$target' resolves to an empty diff ($scope)"
fi

# File map from the frozen patch. Prefixes and quoting are forced above, so
# git apply always parses it; if it ever does not, the snapshot is unusable.
files=$("${git[@]}" apply --numstat "$patch") || { rm -rf "$snap"; die 1 "git apply could not parse $patch"; }

# Size and tier from the same numstat. Binary rows carry "-" for both counts.
read -r nfiles added deleted < <(printf '%s\n' "$files" | awk '
  { n++; if ($1 != "-") a += $1; if ($2 != "-") d += $2 }
  END { printf "%d %d %d\n", n, a, d }')
lines=$((added + deleted))
if [ "$nfiles" -le "$light_max_files" ] && [ "$lines" -le "$light_max_lines" ]; then
  tier="light (at most $light_max_files files and $light_max_lines changed lines)"
else
  tier="full (over $light_max_files files or $light_max_lines changed lines)"
fi

printf 'snapshot: %s\n' "$snap"
printf 'scope: %s\n' "$scope"
printf 'size: %d files, %d lines changed (%d added, %d deleted)\n' "$nfiles" "$lines" "$added" "$deleted"
printf 'tier: %s\n' "$tier"
printf 'files (added\tdeleted\tpath; - for binary):\n%s\n' "$files"
printf 'uncaptured untracked files:\n'
if [ -s "$snap/uncaptured.txt" ]; then cat "$snap/uncaptured.txt"; else printf 'none\n'; fi
