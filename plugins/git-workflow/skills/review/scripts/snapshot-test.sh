#!/usr/bin/env bash
# snapshot-test.sh — exercises snapshot.sh against a throwaway repository.
# Run: bash snapshot-test.sh   (exit 0 = all checks passed)

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
snapshot="$here/snapshot.sh"

fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# run <target...> → sets out, err, code
run() {
  local errf; errf=$(mktemp)
  out=$(bash "$snapshot" "$@" 2>"$errf"); code=$?
  err=$(cat "$errf"); rm -f "$errf"
}
snapdir() { printf '%s\n' "$out" | sed -n 's/^snapshot: //p'; }
cleanup_snap() { local d; d=$(snapdir); [ -n "$d" ] && rm -rf "$d"; }

work=$(mktemp -d "${TMPDIR:-/tmp}/snapshot-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
cd "$work" || exit 1
git init -q -b main .
git config user.email t@example.com
git config user.name t
git config diff.noprefix true          # the script must override this
git config diff.mnemonicPrefix true

# --- clean tree, no commits -------------------------------------------------
run; check "clean unborn tree exits 3" '[ $code -eq 3 ]'

# --- root commit ------------------------------------------------------------
printf 'one\n' > a.txt; git add a.txt; git commit -qm root
root=$(git rev-parse HEAD)
run "$root"
check "root commit exits 0" '[ $code -eq 0 ]'
check "root commit scope mentions empty tree" '[[ "$out" == *"root commit"* ]]'
check "root commit patch has a/ b/ prefixes despite noprefix config" 'grep -q "^+++ b/a.txt" "$(snapdir)/diff.patch"'
cleanup_snap

# --- clean tree with commits ------------------------------------------------
run; check "clean tree exits 3" '[ $code -eq 3 ]'

# --- staged vs uncommitted --------------------------------------------------
printf 'two\n' >> a.txt; git add a.txt
printf 'x\n' > loose.txt
run
check "staged wins when anything is staged" '[ $code -eq 0 ] && [[ "$out" == *"scope: staged changes"* ]]'
check "staged snapshot excludes untracked files" '! grep -q loose.txt "$(snapdir)/diff.patch"'
cleanup_snap
git reset -q a.txt

# --- uncommitted with awkward untracked names ---------------------------------
printf 'n\n' > 'my notes.md'
printf 'c\n' > 'café.py'
printf 'p\n' > '$(touch PWNED).sh'
: > empty.txt
printf '\x00\x01\x02' > blob.bin
mkdir sub; printf 's\n' > sub/nested.txt
run
patch="$(snapdir)/diff.patch"
check "uncommitted scope exits 0" '[ $code -eq 0 ] && [[ "$out" == *"scope: uncommitted changes"* ]]'
check "modified tracked file captured" 'grep -q "^+++ b/a.txt" "$patch"'
check "untracked name with space captured" 'grep -q "^+++ b/my notes.md" "$patch"'
check "untracked non-ASCII name captured" 'grep -q "^+++ b/caf" "$patch"'
check "untracked metachar name captured" 'grep -Fq "PWNED" "$patch"'
check "metachar filename was not executed" '[ ! -e PWNED ]'
check "empty untracked file captured" 'grep -q "b/empty.txt" "$patch"'
check "binary untracked file reduced to marker" 'grep -q "^Binary files" "$patch"'
check "nested untracked file captured with repo-relative path" 'grep -q "^+++ b/sub/nested.txt" "$patch"'
check "no uncaptured files reported" '[[ "$out" == *$'"'"'uncaptured untracked files:\nnone'"'"'* ]]'
check "numstat lists untracked files" '[[ "$out" == *"sub/nested.txt"* ]]'
check "manifest keeps non-ASCII name literal" '[[ "$out" == *"café.py"* ]]'
check "git apply parses the frozen patch" 'git apply --numstat "$patch" >/dev/null'
cleanup_snap

# same scope, run from a subdirectory: paths must stay repo-relative
( cd sub && run; printf '%s' "$out" > "$work/.sub-out"; printf '%s' "$code" > "$work/.sub-code" )
out=$(cat "$work/.sub-out"); code=$(cat "$work/.sub-code")
check "run from a subdirectory exits 0" '[ $code -eq 0 ]'
check "subdirectory run captures top-level files" 'grep -q "^+++ b/a.txt" "$(snapdir)/diff.patch"'
check "subdirectory run keeps nested paths repo-relative" 'grep -q "^+++ b/sub/nested.txt" "$(snapdir)/diff.patch" && [[ "$out" == *"sub/nested.txt"* ]]'
cleanup_snap

# --snapshots places the directory where told
run --snapshots "$work/snaps" 2>/dev/null
check "--snapshots rejects a missing directory" '[ $code -eq 2 ]'
mkdir "$work/snaps"
run --snapshots "$work/snaps"
check "--snapshots places the snapshot under the given root" '[ $code -eq 0 ] && [[ "$(snapdir)" == "$work/snaps/"* ]]'
cleanup_snap

# --- unreadable untracked file lands in uncaptured -----------------------------
if [ "$(id -u)" -ne 0 ]; then
  printf 'secret\n' > locked.txt; chmod 000 locked.txt
  run
  check "unreadable untracked file listed as uncaptured" '[[ "$out" == *"locked.txt"* ]] && grep -qx locked.txt "$(snapdir)/uncaptured.txt"'
  cleanup_snap
  chmod 644 locked.txt
fi
rm -f 'my notes.md' 'café.py' '$(touch PWNED).sh' empty.txt blob.bin loose.txt locked.txt; rm -rf sub
git checkout -q a.txt

# --- a path that merely contains ".." is not a range --------------------------
printf 'q\n' > 'a..b'; git add 'a..b'; git commit -qm dots
run 'a..b'
check "path containing .. exits 2" '[ $code -eq 2 ]'
git rm -q 'a..b'; git commit -qm undots

# --- external diff drivers and textconv never run --------------------------------
git config diff.external "sh -c 'touch $work/EXT_RAN; echo ext-ran'"
printf 'three\n' >> a.txt
run
check "external diff driver is bypassed" '[ $code -eq 0 ] && [ ! -e "$work/EXT_RAN" ] && grep -q "^+++ b/a.txt" "$(snapdir)/diff.patch"'
cleanup_snap
git config --unset diff.external
git checkout -q a.txt

# --- branch base, single commit, range, merge ---------------------------------
git checkout -qb feature
printf 'f\n' > f.txt; git add f.txt; git commit -qm feat
feat=$(git rev-parse HEAD)
git checkout -q main
printf 'm\n' > m.txt; git add m.txt; git commit -qm mainwork
git checkout -q feature

run main
check "branch name is a merge-base diff" '[ $code -eq 0 ] && [[ "$out" == *"relative to main"* ]]'
check "merge-base diff excludes main's own commits" '! grep -q m.txt "$(snapdir)/diff.patch"'
cleanup_snap

git tag v1 main
run v1
check "tag name is a base too" '[ $code -eq 0 ] && [[ "$out" == *"relative to v1"* ]]'
cleanup_snap

git update-ref refs/remotes/origin/main main
run origin/main
check "remote-tracking branch is a base" '[ $code -eq 0 ] && [[ "$out" == *"relative to origin/main"* ]] && grep -q "^+++ b/f.txt" "$(snapdir)/diff.patch"'
cleanup_snap

run "$feat"
check "single commit reviews its own change" '[ $code -eq 0 ] && [[ "$out" == *"scope: commit"* ]] && grep -q "^+++ b/f.txt" "$(snapdir)/diff.patch"'
cleanup_snap

run "main..feature"
check "two-dot range accepted" '[ $code -eq 0 ] && [[ "$out" == *"scope: range main..feature"* ]]'
cleanup_snap

git checkout -q main
git merge -q --no-ff feature -m merge
run HEAD
check "clean merge commit is non-empty against first parent" '[ $code -eq 0 ] && [[ "$out" == *"merge, against first parent"* ]] && grep -q "^+++ b/f.txt" "$(snapdir)/diff.patch"'
cleanup_snap

run main
check "already-merged base exits 3" '[ $code -eq 3 ]'

# --- argument errors ----------------------------------------------------------
run a.txt;        check "path target exits 2" '[ $code -eq 2 ] && [[ "$err" == *"paths are not supported"* ]]'
run nonesuch;     check "unknown target exits 2" '[ $code -eq 2 ]'
run --fix;        check "option-looking target exits 2" '[ $code -eq 2 ]'
run main feature; check "two targets exits 2" '[ $code -eq 2 ]'
run "nope..main"; check "bad range exits 2" '[ $code -eq 2 ]'

check "manifest never contains diff hunks" '! printf "%s" "$out" | grep -q "^@@"'

printf '\n%d failure(s)\n' "$fails"
[ "$fails" -eq 0 ]
