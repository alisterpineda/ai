#!/usr/bin/env bash
# preflight-test.sh — exercises preflight.sh against a throwaway repository.
# Run: bash preflight-test.sh   (exit 0 = all checks passed)

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
preflight="$here/preflight.sh"

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
check "no target means the conversation" '[[ "$out" == *"target: conversation"* ]]'
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
check "flags in any order around the target, = form included" '[ $code -eq 0 ] && [[ "$out" == *"target: $work/spec.md"* ]] && [[ "$out" == *"review: yes"* ]] && [[ "$out" == *"slice: 2"* ]] && [[ "$out" == *"review-model: sonnet"* ]] && [[ "$out" == *"review-effort: high"* ]]'

run --slice all "$work/spec.md"; check "--slice all is accepted" '[ $code -eq 0 ] && [[ "$out" == *"slice: all"* ]]'
run --slice=1 "$work/spec.md"; check "--slice=<n> is accepted" '[ $code -eq 0 ] && [[ "$out" == *"slice: 1"* ]]'

# --- argument errors --------------------------------------------------------
help="supported flags: --review, --slice <n|all>, --review-model <name>, --review-effort <level>"
run --frobnicate; check "unknown flag exits 2 naming the supported flags" '[ $code -eq 2 ] && [[ "$err" == *"unknown flag '"'"'--frobnicate'"'"'"* ]] && [[ "$err" == *"$help"* ]]'
run a b; check "two targets exit 2" '[ $code -eq 2 ] && [[ "$err" == *"at most one target"* ]]'
run --slice; check "--slice without a value exits 2" '[ $code -eq 2 ] && [[ "$err" == *"--slice needs a value"* ]]'
run --slice --review; check "a flag is not taken as a value" '[ $code -eq 2 ] && [[ "$err" == *"--slice needs a value"* ]]'
run --slice x; check "--slice takes a number or all" '[ $code -eq 2 ] && [[ "$err" == *"slice number or '"'"'all'"'"'"* ]]'
run --slice 0; check "--slice 0 exits 2" '[ $code -eq 2 ]'
run --review-model opus; check "--review-model needs --review" '[ $code -eq 2 ] && [[ "$err" == *"--review-model needs --review"* ]] && [[ "$err" == *"$help"* ]]'
run --review-effort low; check "--review-effort needs --review" '[ $code -eq 2 ] && [[ "$err" == *"--review-effort needs --review"* ]]'
run --review --review-effort huge; check "invalid effort exits 2 listing the levels" '[ $code -eq 2 ] && [[ "$err" == *"not a valid --review-effort level: use low, medium, high, xhigh, or max"* ]]'
run --review=no; check "--review=<value> exits 2" '[ $code -eq 2 ] && [[ "$err" == *"--review takes no value"* ]] && [[ "$err" == *"$help"* ]]'
run --slice 3 https://github.com/o/r/issues/1; check "--slice with a URL target exits 2" '[ $code -eq 2 ] && [[ "$err" == *"--slice needs a spec file"* ]] && [[ "$err" == *"$help"* ]]'
run --slice 1; check "--slice with no target is accepted for a Fix plan" '[ $code -eq 0 ] && [[ "$out" == *"target: conversation"* ]] && [[ "$out" == *"slice: 1"* ]]'
run --slice 1 "$work/missing.md"; check "--slice with a missing spec file exits 2" '[ $code -eq 2 ] && [[ "$err" == *"--slice needs a spec file"* ]]'
run --slice 3 "$work/spec.md"; check "missing slice exits 2 listing the slices" '[ $code -eq 2 ] && [[ "$err" == *"has no slice 3; its slices are 1, 2"* ]]'
run --slice 1 "$work/flat.md"; check "slice of a spec without slices exits 2" '[ $code -eq 2 ] && [[ "$err" == *"has no slices"* ]]'
run --slice all "$work/flat.md"; check "--slice all on a spec without slices exits 2" '[ $code -eq 2 ] && [[ "$err" == *"has no slices"* ]]'

# --- clean-tree check -------------------------------------------------------
mkdir .scratch; printf '*\n' > .scratch/.gitignore; printf 'spec\n' > .scratch/s.md
run; check "ignored files keep the tree clean" '[ $code -eq 0 ]'
printf 'x\n' > new.txt
run; check "an untracked file exits 3 and lists it" '[ $code -eq 3 ] && [[ "$err" == *"not clean"* ]] && [[ "$err" == *"?? new.txt"* ]]'
rm new.txt
mkdir -p junk/deep; for i in 1 2 3; do printf 'x\n' > "junk/deep/f$i"; done
run; check "an untracked directory is listed once" '[ $code -eq 3 ] && [[ "$err" == *"?? junk/"* ]] && [[ "$err" != *"f1"* ]]'
rm -rf junk
printf 'two\n' >> a.txt
run; check "a modified file exits 3" '[ $code -eq 3 ] && [[ "$err" == *" M a.txt"* ]]'
git add a.txt
run; check "a staged file exits 3" '[ $code -eq 3 ] && [[ "$err" == *"M  a.txt"* ]]'
git commit -qm two
mkdir sub; printf 'x\n' > sub/s.txt; git add sub/s.txt; git commit -qm sub
cd sub || exit 1
run; check "runs from a subdirectory and reports the root" '[ $code -eq 0 ] && [[ "$out" == "repo: $work/repo"$'"'"'\n'"'"'* ]]'
cd ..
git checkout -q --detach
run; check "a detached HEAD is reported" '[ $code -eq 0 ] && [[ "$out" == *$'"'"'\nbranch: (detached)\n'"'"'* ]]'

printf '\n%d failure(s)\n' "$fails"
[ "$fails" -eq 0 ]
