#!/usr/bin/env bash
# session-model-test.sh — exercises session-model.sh and session-model.ps1
# against throwaway session logs. The same checks run on each; the .ps1 is
# skipped, with a note, when pwsh isn't on PATH.
# Run: bash session-model-test.sh   (exit 0 = all checks passed; needs jq)

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

fails=0
impl=
pass() { printf 'ok   %s: %s\n' "$impl" "$1"; }
fail() { printf 'FAIL %s: %s\n' "$impl" "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

work=$(mktemp -d "${TMPDIR:-/tmp}/session-model-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

# run <stdin text> → sets out, code, secs (uses $COPILOT_HOME and the hook array)
run() {
  local t0=$SECONDS
  out=$(printf '%s' "$1" | "${hook[@]}" 2>/dev/null); code=$?
  secs=$((SECONDS - t0))
}
start_line() { printf '{"type":"session.start","data":{"selectedModel":"%s"}}\n' "$1"; }
change_line() { printf '{"type":"session.model_change","data":{"previousModel":"x","newModel":"%s"}}\n' "$1"; }
other_line() { printf '{"type":"user.message","data":{"content":"hi"}}\n'; }
# log <root> <id> → reads the log text from stdin
log() { mkdir -p "$1/session-state/$2"; cat >"$1/session-state/$2/events.jsonl"; }
tag() { printf "<session_model>This session's model ID is %s.</session_model>" "$1"; }
# says <model>: the output is a JSON object whose additionalContext is the tag for <model>
says() {
  local ctx; ctx=$(printf '%s' "$out" | jq -r .additionalContext 2>/dev/null) || return 1
  [ "$ctx" = "$(tag "$1")" ]
}

# suite <name> <command...> → runs every check against that hook command
suite() {
  impl=$1; shift
  hook=("$@")
  export COPILOT_HOME="$work/$impl/home"

  # --- one start line -------------------------------------------------------
  start_line model-a | log "$COPILOT_HOME" s1
  run '{"sessionId":"s1","source":"new"}'
  check "a start line names its selected model" '[ $code -eq 0 ] && says model-a'
  check "output is a single JSON object" '[ "$(printf "%s" "$out" | jq -c "keys")" = "[\"additionalContext\"]" ]'

  # --- the last of either event type wins -----------------------------------
  { start_line model-a; change_line model-b; other_line; change_line model-c; } | log "$COPILOT_HOME" s2
  run '{"sessionId":"s2"}'
  check "the last change line wins" '[ $code -eq 0 ] && says model-c'

  { start_line model-a; change_line model-b; start_line model-d; } | log "$COPILOT_HOME" s3
  run '{"sessionId":"s3"}'
  check "a later start line beats an earlier change line" '[ $code -eq 0 ] && says model-d'

  # --- stdin shapes ---------------------------------------------------------
  run '{"session_id":"s1"}'
  check "session_id is accepted" '[ $code -eq 0 ] && says model-a'
  run '{ "sessionId" : "s1", "source" : "resume" }'
  check "spaces around the colon are accepted" '[ $code -eq 0 ] && says model-a'

  # --- HOME fallback --------------------------------------------------------
  # USERPROFILE too: on Windows that, not HOME, is PowerShell's home.
  ( unset COPILOT_HOME
    export HOME="$work/$impl/fakehome"
    export USERPROFILE="$HOME"
    start_line model-h | log "$HOME/.copilot" s4
    printf '%s' '{"sessionId":"s4"}' | "${hook[@]}" ) >"$work/h.out" 2>/dev/null
  code=$?; out=$(cat "$work/h.out")
  check "without COPILOT_HOME the log is under HOME/.copilot" '[ $code -eq 0 ] && says model-h'

  # --- log appears late -----------------------------------------------------
  ( sleep 1; start_line model-late | log "$COPILOT_HOME" s5 ) &
  run '{"sessionId":"s5"}'
  wait
  check "a log that appears within the wait is read" '[ $code -eq 0 ] && says model-late'

  # --- nothing to print -----------------------------------------------------
  run '{"sessionId":"nodir"}'
  check "a session with no log prints nothing after waiting" '[ $code -eq 0 ] && [ -z "$out" ] && [ $secs -ge 4 ]'
  run 'not json'
  check "stdin that is not JSON prints nothing" '[ $code -eq 0 ] && [ -z "$out" ]'
  run '{}'
  check "stdin without a session ID prints nothing" '[ $code -eq 0 ] && [ -z "$out" ]'
  { other_line; other_line; } | log "$COPILOT_HOME" s6
  run '{"sessionId":"s6"}'
  check "a log with no model event prints nothing" '[ $code -eq 0 ] && [ -z "$out" ]'
}

suite sh sh "$here/session-model.sh"
# An absolute path, so pwsh is still found when a check moves HOME.
if pwsh=$(command -v pwsh 2>/dev/null); then
  suite ps1 "$pwsh" -NoProfile -File "$here/session-model.ps1"
else
  echo "skip ps1: pwsh is not on PATH"
fi

if [ $fails -eq 0 ]; then echo "all checks passed"; else echo "$fails check(s) failed"; fi
[ $fails -eq 0 ]
