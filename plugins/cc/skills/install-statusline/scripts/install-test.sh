#!/usr/bin/env bash
# install-test.sh — exercises install.sh against throwaway config dirs.
# Run: bash install-test.sh   (exit 0 = all checks passed)
# install.ps1 has no automated test; it is checked by hand on Windows.

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
installer="$here/install.sh"
bundled="$here/statusline-command.sh"

fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# run <args...> → sets out, err, code (installs into $CLAUDE_CONFIG_DIR)
run() {
  local errf; errf=$(mktemp)
  out=$(bash "$installer" "$@" 2>"$errf"); code=$?
  err=$(cat "$errf"); rm -f "$errf"
}
baks() { find "$1" -maxdepth 1 -name "$2.*.bak" | wc -l | tr -d ' '; }
mode() { stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"; }

work=$(mktemp -d "${TMPDIR:-/tmp}/install-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

# --- fresh config dir ---------------------------------------------------------
export CLAUDE_CONFIG_DIR="$work/fresh"
run --check
check "--check on a missing dir exits 0" '[ $code -eq 0 ]'
check "--check reports absent / missing" '[[ "$out" == *"statusline: absent"* && "$out" == *"script: missing"* ]]'
check "--check writes nothing" '[ ! -e "$CLAUDE_CONFIG_DIR" ]'
run
want=$(jq -nc --arg c "bash \"$CLAUDE_CONFIG_DIR/statusline-command.sh\"" '{type: "command", command: $c}')
check "fresh install exits 0" '[ $code -eq 0 ] && [[ "$out" == *"result: installed"* ]]'
check "fresh install sets exactly type + command" '[ "$(jq -c .statusLine "$CLAUDE_CONFIG_DIR/settings.json")" = "$want" ]'
check "fresh install copies the bundled script" 'cmp -s "$bundled" "$CLAUDE_CONFIG_DIR/statusline-command.sh"'
check "fresh install makes no backups" '[ -z "$(find "$CLAUDE_CONFIG_DIR" -name "*.bak")" ]'
before=$(ls -l "$CLAUDE_CONFIG_DIR")
run
check "re-run is a no-op" '[ $code -eq 0 ] && [[ "$out" == *"result: already up to date"* ]] && [ "$(ls -l "$CLAUDE_CONFIG_DIR")" = "$before" ]'

# --- someone else's statusLine ----------------------------------------------
export CLAUDE_CONFIG_DIR="$work/other"
mkdir -p "$CLAUDE_CONFIG_DIR"
settings="$CLAUDE_CONFIG_DIR/settings.json"
printf '{\n  "model": "opus",\n  "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "a && b"}]}]},\n  "statusLine": {"type": "command", "command": "~/mine.sh", "padding": 1}\n}\n' >"$settings"
chmod 640 "$settings"
original=$(cat "$settings")
run
check "a different statusLine without --replace exits 3" '[ $code -eq 3 ] && [[ "$err" == *"--replace"* ]]'
check "refusing leaves settings.json untouched" '[ "$(cat "$settings")" = "$original" ] && [ "$(baks "$CLAUDE_CONFIG_DIR" settings.json)" = 0 ]'
run --replace
check "--replace installs" '[ $code -eq 0 ] && [[ "$out" == *"result: installed"* ]]'
check "--replace backs up the original settings.json" '[ "$(cat "$CLAUDE_CONFIG_DIR"/settings.json.*.bak)" = "$original" ]'
check "unrelated keys survive" '[ "$(jq -S "del(.statusLine)" "$settings")" = "$(printf "%s" "$original" | jq -S "del(.statusLine)")" ]'
check "statusLine padding survives" '[ "$(jq .statusLine.padding "$settings")" = 1 ]'
check "the old command is replaced" '[ "$(jq -r .statusLine.command "$settings")" = "bash \"$CLAUDE_CONFIG_DIR/statusline-command.sh\"" ]'
check "settings.json keeps its mode" '[ "$(mode "$settings")" = 640 ]'

# --- a statusline-command.sh the user wrote ---------------------------------
export CLAUDE_CONFIG_DIR="$work/foreign"
mkdir -p "$CLAUDE_CONFIG_DIR"
target="$CLAUDE_CONFIG_DIR/statusline-command.sh"
printf 'echo mine\n' >"$target"
run --check
check "a user-written script is reported as foreign" '[[ "$out" == *"script: foreign"* ]]'
run
check "a foreign script without --replace exits 3" '[ $code -eq 3 ] && [ "$(cat "$target")" = "echo mine" ]'
run --replace
check "--replace backs up the user's script" '[ $code -eq 0 ] && [ "$(cat "$CLAUDE_CONFIG_DIR"/statusline-command.sh.*.bak)" = "echo mine" ]'

# --- updating an older bundled version --------------------------------------
# Same second as the --replace above, so this also covers backup-name clashes.
{ cat "$bundled"; echo '# older version'; } >"$target"
run --check
check "an older bundled script is reported as differs" '[[ "$out" == *"statusline: ours"* && "$out" == *"script: differs"* ]]'
run
check "updating needs no --replace" '[ $code -eq 0 ] && cmp -s "$bundled" "$target"'
check "updating keeps every earlier backup" '[ "$(baks "$CLAUDE_CONFIG_DIR" statusline-command.sh)" = 2 ] && grep -qx "echo mine" "$CLAUDE_CONFIG_DIR"/statusline-command.sh.*.bak'

# --- symlinked settings.json ------------------------------------------------
export CLAUDE_CONFIG_DIR="$work/linked"
mkdir -p "$CLAUDE_CONFIG_DIR" "$work/dotfiles"
printf '{"model": "opus"}\n' >"$work/dotfiles/settings.json"
ln -s "$work/dotfiles/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"
run
check "a symlinked settings.json stays a symlink" '[ $code -eq 0 ] && [ -L "$CLAUDE_CONFIG_DIR/settings.json" ]'
check "the symlink target gets the statusLine" '[ "$(jq -r .statusLine.type "$work/dotfiles/settings.json")" = command ]'

# --- default location -------------------------------------------------------
unset CLAUDE_CONFIG_DIR
HOME="$work/home" run
check "the default location uses the portable \$HOME form" \
  '[ $code -eq 0 ] && [ "$(jq -r .statusLine.command "$work/home/.claude/settings.json")" = "bash \"\$HOME/.claude/statusline-command.sh\"" ]'

# --- errors -----------------------------------------------------------------
export CLAUDE_CONFIG_DIR="$work/broken"
mkdir -p "$CLAUDE_CONFIG_DIR"
printf '{bad' >"$CLAUDE_CONFIG_DIR/settings.json"
run --check
check "invalid settings.json exits 1" '[ $code -eq 1 ] && [[ "$err" == *"not valid JSON"* ]]'
run --nope
check "an unknown flag exits 1 and names the supported ones" '[ $code -eq 1 ] && [[ "$err" == *"--check, --replace"* ]]'

[ "$fails" -eq 0 ] && echo "all checks passed" || echo "$fails check(s) failed"
[ "$fails" -eq 0 ]
