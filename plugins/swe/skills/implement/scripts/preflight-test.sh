#!/usr/bin/env bash
# preflight-test.sh — exercises preflight.sh and start-tree.sh against a
# throwaway repository, and start-tree.sh's tree as code-review-core's
# snapshot.sh diffs it.
# Run: bash preflight-test.sh   (exit 0 = all checks passed)

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
preflight="$here/preflight.sh"
start_tree="$here/start-tree.sh"
snapshot="$here/../../code-review-core/scripts/snapshot.sh"

fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# run <args...> → sets out, err, code
run() {
  local errf; errf=$(mktemp)
  out=$(bash "$preflight" "$@" 2>"$errf"); code=$?
  err=$(cat "$errf"); rm -f "$errf"
}

work=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/preflight-test.XXXXXX")" && pwd -P)   # physical path, as git reports it
trap 'rm -rf "$work"' EXIT

# --- outside a repository ---------------------------------------------------
mkdir "$work/norepo"; cd "$work/norepo" || exit 1
run; check "outside a git repository exits 3" '[ $code -eq 3 ] && [[ "$err" == *"not inside a git repository"* ]]'
run --frobnicate; check "argument errors come before the repository check" '[ $code -eq 2 ]'
out=$(bash "$start_tree" 2>&1); code=$?
check "start-tree outside a git repository exits 3" '[ $code -eq 3 ] && [[ "$out" == *"not inside a git repository"* ]]'

mkdir "$work/repo"; cd "$work/repo" || exit 1
git init -q -b main .
git config user.email t@example.com
git config user.name t

# --- a repository with no commits yet ----------------------------------------
run; check "an empty repository with no commits is clean" '[ $code -eq 0 ] && [[ "$out" == *$'"'"'\nhead: (no commits)\n'"'"'* ]] && [[ "$out" == *$'"'"'\nbranch: main\n'"'"'* ]]'

printf 'one\n' > a.txt; git add a.txt; git commit -qm root

cat > "$work/spec.md" <<'MD'
# Spec

## Acceptance criteria
1. One.
2. Two.

## Slices
1. First: one. Criteria: 1
2. Second: two. Criteria: 2

## Notes
3. Not a slice.
MD
printf '# No slices\n\n## Acceptance criteria\n1. One.\n' > "$work/flat.md"

# --- manifest ---------------------------------------------------------------
run
check "no arguments exits 0" '[ $code -eq 0 ]'
check "a clean tree lists nothing uncommitted" '[[ "$out" == *$'"'"'\nuncommitted:\nnone'"'"' ]]'
check "no words means text: none" '[[ "$out" == *$'"'"'\ntext: none\n'"'"'* ]]'
check "review defaults to no" '[[ "$out" == *"review: no"* ]]'
check "slice defaults to none" '[[ "$out" == *"slice: none"* ]]'
check "review model and effort default to inherit" '[[ "$out" == *"review-model: inherit"* ]] && [[ "$out" == *"review-effort: inherit"* ]]'
check "manifest names the branch" '[[ "$out" == *$'"'"'\nbranch: main\n'"'"'* ]]'
check "manifest gives the repository root exactly" '[[ "$out" == "repo: $work/repo"$'"'"'\n'"'"'* ]]'
check "manifest gives HEAD" '[[ "$out" == *$'"'"'\nhead: '"'"'"$(git rev-parse HEAD)"$'"'"'\n'"'"'* ]]'
for level in low medium high xhigh max; do
  run --review --review-effort "$level"
  check "--review-effort $level is accepted" '[ $code -eq 0 ] && [[ "$out" == *"review-effort: $level"* ]]'
done

run --review-effort=high "$work/spec.md" --slice 2 --review --review-model sonnet
check "flags in any order around the target, = form included" '[ $code -eq 0 ] && [[ "$out" == *"text: $work/spec.md"$'"'"'\n'"'"'* ]] && [[ "$out" == *"review: yes"* ]] && [[ "$out" == *"slice: 2"* ]] && [[ "$out" == *"review-model: sonnet"* ]] && [[ "$out" == *"review-effort: high"* ]]'

run --slice all "$work/spec.md"; check "--slice all is accepted" '[ $code -eq 0 ] && [[ "$out" == *"slice: all"* ]]'
run --slice=1 "$work/spec.md"; check "--slice=<n> is accepted" '[ $code -eq 0 ] && [[ "$out" == *"slice: 1"* ]]'
run a b; check "several words pass through in order, one line each" '[ $code -eq 0 ] && [[ "$out" == *$'"'"'\ntext: a\ntext: b\n'"'"'* ]]'
run 'docs/my spec.md' only; check "a quoted argument with a space stays whole" '[ $code -eq 0 ] && [[ "$out" == *$'"'"'\ntext: docs/my spec.md\ntext: only\n'"'"'* ]]'
run https://github.com/o/r/issues/1 --review https://github.com/o/r/issues/2 only the parser
check "flags between words are taken out of the text" '[ $code -eq 0 ] && [[ "$out" == *$'"'"'text: https://github.com/o/r/issues/1\ntext: https://github.com/o/r/issues/2\ntext: only\ntext: the\ntext: parser\n'"'"'* ]] && [[ "$out" == *"review: yes"* ]]'
run 'https://github.com/o/r/issues/7?tab=comments&x=*'
check "a URL's ? & * reach the manifest unexpanded" '[ $code -eq 0 ] && [[ "$out" == *"text: https://github.com/o/r/issues/7?tab=comments&x=*"* ]]'
run --slice 9 "$work/spec.md"; check "a slice number the spec lacks is left to the skill" '[ $code -eq 0 ] && [[ "$out" == *"slice: 9"* ]]'
run --slice 1 "$work/flat.md"; check "--slice with a spec without slices is left to the skill" '[ $code -eq 0 ]'
run --slice 3 https://github.com/o/r/issues/1; check "--slice with a ticket target is left to the skill" '[ $code -eq 0 ] && [[ "$out" == *"slice: 3"* ]]'
run --slice 1; check "--slice with no target is accepted" '[ $code -eq 0 ] && [[ "$out" == *"text: none"* ]] && [[ "$out" == *"slice: 1"* ]]'
run --slice 1 "$work/missing.md"; check "--slice with a missing file is left to the skill" '[ $code -eq 0 ]'

# --- argument errors --------------------------------------------------------
help="supported flags: --review, --slice <n|all>, --review-model <name>, --review-effort <level>"
run --frobnicate; check "unknown flag exits 2 naming the supported flags" '[ $code -eq 2 ] && [[ "$err" == *"unknown flag '"'"'--frobnicate'"'"'"* ]] && [[ "$err" == *"$help"* ]]'
run --slice; check "--slice without a value exits 2" '[ $code -eq 2 ] && [[ "$err" == *"--slice needs a value"* ]]'
run --slice --review; check "a flag is not taken as a value" '[ $code -eq 2 ] && [[ "$err" == *"--slice needs a value"* ]]'
run --slice x; check "--slice takes a number or all" '[ $code -eq 2 ] && [[ "$err" == *"slice number or '"'"'all'"'"'"* ]]'
run --slice 0; check "--slice 0 exits 2" '[ $code -eq 2 ] && [[ "$err" == *"slice number or '"'"'all'"'"', got '"'"'0'"'"'"* ]]'
run --slice -2; check "--slice with a negative number exits 2" '[ $code -eq 2 ]'
run --review-model opus; check "--review-model needs --review" '[ $code -eq 2 ] && [[ "$err" == *"--review-model needs --review"* ]] && [[ "$err" == *"$help"* ]]'
run --review-effort low; check "--review-effort needs --review" '[ $code -eq 2 ] && [[ "$err" == *"--review-effort needs --review"* ]]'
run --review --review-effort huge; check "invalid effort exits 2 listing the levels" '[ $code -eq 2 ] && [[ "$err" == *"not a valid --review-effort level: use low, medium, high, xhigh, or max"* ]]'
run --review=no; check "--review=<value> exits 2" '[ $code -eq 2 ] && [[ "$err" == *"--review takes no value"* ]] && [[ "$err" == *"$help"* ]]'

# --- uncommitted changes don't stop the run -----------------------------------
mkdir .scratch; printf '*\n' > .scratch/.gitignore; printf 'spec\n' > .scratch/s.md
printf 'x\n' > new.txt
printf 'two\n' >> a.txt
run; check "a modified file and an untracked file don't stop the run" '[ $code -eq 0 ]'
git add a.txt
run; check "a staged file doesn't stop the run" '[ $code -eq 0 ]'
printf 'staged-later\n' > staged.txt; git add staged.txt; printf 'more\n' >> staged.txt
index_before=$(git diff --cached --raw; git ls-files -s)

# --- start-tree: the starting snapshot ----------------------------------------
out=$(bash "$start_tree" 2>&1); code=$?
tree=$(printf '%s\n' "$out" | sed -n 's/^start-tree: //p')
check "start-tree exits 0 and prints a tree id" '[ $code -eq 0 ] && [ "$(git cat-file -t "$tree" 2>/dev/null)" = tree ]'
check "start-tree leaves the real index exactly as it was" '[ "$(git diff --cached --raw; git ls-files -s)" = "$index_before" ]'
check "the tree holds a staged change" '[ "$(git show "$tree:a.txt")" = "$(printf "one\ntwo")" ]'
check "the tree holds the working copy of a staged file edited since" '[ "$(git show "$tree:staged.txt")" = "$(printf "staged-later\nmore")" ]'
check "the tree holds an untracked file" '[ "$(git show "$tree:new.txt")" = x ]'
check "the tree leaves ignored files out" '! git cat-file -e "$tree:.scratch/s.md" 2>/dev/null'
check "start-tree prints only the tree line" '[ "$(printf "%s\n" "$out" | wc -l | tr -d " ")" = 1 ]'
mkdir -p junk/deep; printf 'x\n' > junk/deep/f1
run
check "preflight lists uncommitted changes" '[[ "$out" == *$'"'"'\nuncommitted:\n'"'"'* ]] && [[ "$out" == *"?? new.txt"* ]] && [[ "$out" == *"M  a.txt"* ]] && [[ "$out" == *"AM staged.txt"* ]]'
check "an untracked directory is listed once" '[[ "$out" == *"?? junk/"* ]] && [[ "$out" != *"junk/deep"* ]]'
check "ignored files are not listed as uncommitted" '[[ "$out" != *".scratch"* ]]'
out=$(bash "$start_tree" extra 2>&1); code=$?
check "start-tree takes no arguments" '[ $code -eq 2 ]'

# --- the diff since the starting tree (code-review-core's snapshot.sh) ----------
mkdir -p docs; printf '# Spec\n\n## Acceptance criteria\n1. One.\n' > docs/spec.md
out=$(bash "$start_tree" 2>&1)
tree=$(printf '%s\n' "$out" | sed -n 's/^start-tree: //p')
printf 'run-line\n' >> a.txt             # the run edits a file that was already modified
printf 'made by the run\n' > run.txt     # and creates one
printf 'Done: today.\n' >> docs/spec.md  # and touches its spec
printf 'answer\n' >> .scratch/s.md
snaps="$work/snaps"; mkdir -p "$snaps"
sout=$(bash "$snapshot" --snapshots "$snaps" --spec docs/spec.md "$tree" 2>&1); scode=$?
sdir=$(printf '%s\n' "$sout" | sed -n 's/^snapshot: //p')
patch="$sdir/diff.patch"
check "the diff since the starting tree exits 0" '[ $scode -eq 0 ] && [[ "$sout" == *"scope: changes in the working tree since tree"* ]]'
check "only the run's hunk of an already-modified file is reviewed" 'grep -qx "+run-line" "$patch" && ! grep -qx "+two" "$patch"'
check "a file the run created is reviewed" 'grep -q "^+++ b/run.txt" "$patch"'
check "an untracked file from before the run is not reviewed" '! grep -q "new.txt" "$patch" && ! grep -q "junk/deep" "$patch"'
check "a staged file from before the run is not reviewed" '! grep -q "staged.txt" "$patch"'
check "the spec in a tracked-style location is not reviewed" '! grep -q "docs/spec.md" "$patch"'
check "the spec under .scratch/ is not reviewed" '! grep -q "\.scratch" "$patch"'
check "the real index is still as it was" '[ "$(git diff --cached --raw; git ls-files -s)" = "$index_before" ]'
rm -rf "$sdir"
out=$(bash "$start_tree" 2>&1)
tree=$(printf '%s\n' "$out" | sed -n 's/^start-tree: //p')
sout=$(bash "$snapshot" --snapshots "$snaps" "$tree" 2>&1); scode=$?
check "no change since the starting tree is nothing to review" '[ $scode -eq 3 ] && [[ "$sout" == *"nothing to review"* ]]'

git reset -q; rm -rf new.txt staged.txt run.txt junk docs; git checkout -q a.txt
printf 'two\n' >> a.txt; git commit -qam two
mkdir sub; printf 'x\n' > sub/s.txt; git add sub/s.txt; git commit -qm sub
cd sub || exit 1
run; check "runs from a subdirectory and reports the root" '[ $code -eq 0 ] && [[ "$out" == "repo: $work/repo"$'"'"'\n'"'"'* ]]'
cd ..
git checkout -q --detach
run; check "a detached HEAD is reported" '[ $code -eq 0 ] && [[ "$out" == *$'"'"'\nbranch: (detached)\n'"'"'* ]]'

printf '\n%d failure(s)\n' "$fails"
[ "$fails" -eq 0 ]
