#!/usr/bin/env bash
# start-tree.sh — record the working tree at the start of an implement build.
#
# Usage: start-tree.sh   (no arguments)
#
# Writes the working tree as it stands, every tracked and untracked file with
# ignored files left out, as a git tree object, through a temporary index: the
# real index is copied, never written, so nothing is staged, stashed, or
# committed. The review (code-review-core's scripts/snapshot.sh, given the tree
# id as its target) and the self-check diff against this tree, so changes that
# were already uncommitted when the run began never count as the run's work.
# snapshot.sh reads the working tree the same way: change both together.
#
# The tree object is unreachable, so `git gc` prunes it after its grace period
# (two weeks by default); it only has to outlive the run.
#
# Prints one line on stdout: `start-tree: <tree id>`.
#
# Exit codes: 0 recorded · 2 argument error · 3 not a git repository ·
#             1 unexpected failure

set -u

die() { local code=$1; shift; printf 'start-tree: %s\n' "$*" >&2; exit "$code"; }

[ $# -eq 0 ] || die 2 "takes no arguments, got '$1'"

toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die 3 "not inside a git repository"
cd "$toplevel" || die 1 "cannot enter $toplevel"

# The temporary index goes in the first writable temp root (sandboxes often
# make $TMPDIR read-only).
idx=""
for root in "${TMPDIR:-}" /tmp; do
  [ -n "$root" ] && [ -d "$root" ] || continue
  idx=$(mktemp "${root%/}/implement-start-index.XXXXXX" 2>/dev/null) && break
  idx=""
done
[ -n "$idx" ] || die 1 "cannot create a temporary index file"
trap 'rm -f "$idx"' EXIT

# The real index's stat cache spares rehashing unchanged files.
real_index=$(git rev-parse --git-path index)
if [ -f "$real_index" ]; then
  cp "$real_index" "$idx" || die 1 "cannot copy the index"
else
  GIT_INDEX_FILE=$idx git read-tree --empty || die 1 "git read-tree failed"
fi
# --ignore-errors: an unreadable file is left out rather than failing the run.
# git then exits 1; anything higher is a fatal error, and a tree written after
# it would miss the working tree's changes.
GIT_INDEX_FILE=$idx git add -A --ignore-errors -- . >/dev/null 2>&1
[ $? -le 1 ] || die 1 "git add into the temporary index failed"
tree=$(GIT_INDEX_FILE=$idx git write-tree) || die 1 "git write-tree failed"

printf 'start-tree: %s\n' "$tree"
