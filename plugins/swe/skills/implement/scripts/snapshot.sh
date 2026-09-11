#!/usr/bin/env bash
# snapshot.sh — record the working tree at the start of an implement run, and
# later diff the current working tree against that record.
#
# Usage:
#   snapshot.sh start [--scratch DIR]   freeze the current working tree
#   snapshot.sh diff  <snapshot-dir>    unified diff from the frozen tree to now
#
# `start` builds a throwaway index from HEAD plus every tracked and untracked
# file (honouring .gitignore), writes it as a tree object, and records the tree
# id under DIR (default: $IMPLEMENT_SCRATCH_DIR, then $TMPDIR). Nothing is
# staged, stashed, or committed; the real index is untouched. Prints a short
# manifest: the snapshot directory, the tree id, HEAD, and the files that were
# already modified or untracked when the run began.
#
# `diff` reads the tree id from <snapshot-dir>/start-tree, builds the same kind
# of tree for the current working tree, and prints `git diff <start> <now>` —
# exactly what changed since `start`, including files created since, and
# excluding anything already dirty at start that has not changed further.
# Prints nothing when nothing changed. The snapshot directory itself is
# excluded from both trees, so it never appears even when it sits inside the
# repository.
#
# Exit codes: 0 ok · 2 argument error · 1 unexpected failure

set -u

die() { local code=$1; shift; printf 'snapshot: %s\n' "$*" >&2; exit "$code"; }

toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || die 2 "not inside a git repository"
cd "$toplevel" || die 1 "cannot enter $toplevel"

# Standard a/ b/ prefixes, no color, literal filenames, no external diff
# drivers: the diff is read by an agent, not a human, and runs unattended.
git=(git -c diff.noprefix=false -c diff.mnemonicPrefix=false -c color.diff=false -c core.quotePath=false)
diffopts=(--no-ext-diff --no-textconv)

# Pathspec that excludes the snapshot directory when it lives inside the repo;
# empty otherwise. Set once $snap is known.
exclude=()
set_exclude() {
  local abs rel
  abs=$(cd "$1" 2>/dev/null && pwd -P) || return 0
  case "$abs/" in
    "$toplevel"/*) rel=${abs#"$toplevel"/}; exclude=(":(exclude)$rel");;
  esac
}

# Write the working tree (tracked + untracked, .gitignore respected, snapshot
# dir excluded) as a tree object via a temporary index. The object is
# unreachable, so git will prune it eventually; it only needs to outlive the
# session.
tree_of_worktree() {
  local idx tree
  idx=$(mktemp) || die 1 "mktemp failed"
  if git rev-parse --verify --quiet HEAD^{commit} >/dev/null; then
    GIT_INDEX_FILE=$idx git read-tree HEAD || { rm -f "$idx"; die 1 "read-tree failed"; }
  else
    GIT_INDEX_FILE=$idx git read-tree --empty || { rm -f "$idx"; die 1 "read-tree failed"; }
  fi
  GIT_INDEX_FILE=$idx git add -A -- . ${exclude[@]+"${exclude[@]}"} >/dev/null 2>&1 || { rm -f "$idx"; die 1 "add to temporary index failed"; }
  tree=$(GIT_INDEX_FILE=$idx git write-tree) || { rm -f "$idx"; die 1 "write-tree failed"; }
  rm -f "$idx"
  printf '%s\n' "$tree"
}

[ $# -ge 1 ] || die 2 "usage: snapshot.sh start [--scratch DIR] | snapshot.sh diff <snapshot-dir>"
mode=$1; shift

case "$mode" in
  start)
    scratch="${IMPLEMENT_SCRATCH_DIR:-${TMPDIR:-/tmp}}"
    while [ $# -gt 0 ]; do
      case "$1" in
        --scratch) [ $# -ge 2 ] || die 2 "--scratch needs a directory"; scratch=$2; shift 2;;
        *) die 2 "unknown argument '$1' for start";;
      esac
    done
    [ -d "$scratch" ] || die 2 "scratch root '$scratch' is not a directory"
    snap=$(mktemp -d "$scratch/implement.XXXXXX") || die 1 "mktemp failed"
    set_exclude "$snap"
    tree=$(tree_of_worktree)
    printf '%s\n' "$tree" > "$snap/start-tree"
    head=$(git rev-parse --verify --quiet HEAD 2>/dev/null || printf 'none')
    printf 'snapshot: %s\n' "$snap"
    printf 'start_tree: %s\n' "$tree"
    printf 'head: %s\n' "$head"
    printf 'dirty at start (status, path):\n'
    status=$(git status --porcelain --untracked-files=all -- . ${exclude[@]+"${exclude[@]}"})
    if [ -n "$status" ]; then printf '%s\n' "$status"; else printf 'none\n'; fi
    ;;
  diff)
    [ $# -eq 1 ] || die 2 "diff needs exactly one argument: the snapshot directory printed by start"
    snap=$1
    [ -f "$snap/start-tree" ] || die 2 "'$snap' has no start-tree file (not a snapshot directory from start?)"
    start=$(cat "$snap/start-tree")
    git cat-file -e "$start^{tree}" 2>/dev/null || die 2 "start tree '$start' is gone (has git pruned it?)"
    set_exclude "$snap"
    now=$(tree_of_worktree)
    "${git[@]}" diff "${diffopts[@]}" "$start" "$now"
    ;;
  *) die 2 "unknown mode '$mode' (expected start or diff)";;
esac
