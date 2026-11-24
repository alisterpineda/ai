#!/usr/bin/env bash
# session-model-test.sh — exercises session-model.sh against throwaway session logs.
# Run: bash session-model-test.sh   (exit 0 = all checks passed; needs jq)

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script="$here/session-model.sh"

fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

work=$(mktemp -d "${TMPDIR:-/tmp}/session-model-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

# run <stdin text> → sets out, code, secs (uses $COPILOT_HOME)
run() {
  local t0=$SECONDS
  out=$(printf '%s' "$1" | sh "$script" 2>/dev/null); code=$?
  secs=$((SECONDS - t0))
}
start_line() { printf '{"type":"session.start","data":{"selectedModel":"%s"}}\n' "$1"; }
change_line() { printf '{"type":"session.model_change","data":{"previousModel":"x","newModel":"%s"}}\n' "$1"; }
other_line() { printf '{"type":"user.message","data":{"content":"hi"}}\n'; }
# log <root> <id> → reads the log text from stdin
log() { mkdir -p "$1/session-state/$2"; cat >"$1/session-state/$2/events.jsonl"; }
tag() { printf "<session_model at=\"%s\">This session's model ID is %s. When several session_model tags are present, the one with the latest time is current.</session_model>" "$1" "$2"; }
# says <model>: the output is a JSON object whose additionalContext is the tag for <model>
says() {
  local ctx; ctx=$(printf '%s' "$out" | jq -r .additionalContext 2>/dev/null) || return 1
  local at; at=$(printf '%s' "$ctx" | sed -n 's/^<session_model at="\([^"]*\)">.*/\1/p')
  printf '%s' "$at" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || return 1
  [ "$ctx" = "$(tag "$at" "$1")" ]
}

export COPILOT_HOME="$work/home"

# --- one start line ---------------------------------------------------------
start_line model-a | log "$COPILOT_HOME" s1
run '{"sessionId":"s1","source":"new"}'
check "a start line names its selected model" '[ $code -eq 0 ] && says model-a'
check "output is a single JSON object" '[ "$(printf "%s" "$out" | jq -c "keys")" = "[\"additionalContext\"]" ]'

# --- the last of either event type wins -------------------------------------
{ start_line model-a; change_line model-b; other_line; change_line model-c; } | log "$COPILOT_HOME" s2
run '{"sessionId":"s2"}'
check "the last change line wins" '[ $code -eq 0 ] && says model-c'

{ start_line model-a; change_line model-b; start_line model-d; } | log "$COPILOT_HOME" s3
run '{"sessionId":"s3"}'
check "a later start line beats an earlier change line" '[ $code -eq 0 ] && says model-d'

# --- stdin shapes -----------------------------------------------------------
run '{"session_id":"s1"}'
check "session_id is accepted" '[ $code -eq 0 ] && says model-a'
run '{ "sessionId" : "s1", "source" : "resume" }'
check "spaces around the colon are accepted" '[ $code -eq 0 ] && says model-a'

# --- HOME fallback ----------------------------------------------------------
( unset COPILOT_HOME
  export HOME="$work/fakehome"
  start_line model-h | log "$HOME/.copilot" s4
  printf '%s' '{"sessionId":"s4"}' | sh "$script" ) >"$work/h.out" 2>/dev/null
code=$?; out=$(cat "$work/h.out")
check "without COPILOT_HOME the log is under HOME/.copilot" '[ $code -eq 0 ] && says model-h'

# --- log appears late -------------------------------------------------------
( sleep 1; start_line model-late | log "$COPILOT_HOME" s5 ) &
run '{"sessionId":"s5"}'
wait
check "a log that appears within the wait is read" '[ $code -eq 0 ] && says model-late'

# --- nothing to print -------------------------------------------------------
run '{"sessionId":"nodir"}'
check "a session with no log prints nothing after waiting" '[ $code -eq 0 ] && [ -z "$out" ] && [ $secs -ge 4 ]'
run 'not json'
check "stdin that is not JSON prints nothing" '[ $code -eq 0 ] && [ -z "$out" ]'
run '{}'
check "stdin without a session ID prints nothing" '[ $code -eq 0 ] && [ -z "$out" ]'
{ other_line; other_line; } | log "$COPILOT_HOME" s6
run '{"sessionId":"s6"}'
check "a log with no model event prints nothing" '[ $code -eq 0 ] && [ -z "$out" ]'

if [ $fails -eq 0 ]; then echo "all checks passed"; else echo "$fails check(s) failed"; fi
[ $fails -eq 0 ]
