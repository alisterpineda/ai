#!/bin/sh
# session-model.sh — Copilot sessionStart hook: tells the session its model ID.
# Reads the hook's JSON from stdin, finds the session's log
# (<COPILOT_HOME or ~/.copilot>/session-state/<id>/events.jsonl), and prints an
# additionalContext tag naming the model of the log's latest model event.
# Prints nothing and exits 0 when the ID or the model can't be found.
# The tag holds nothing that changes between runs, such as a time: the host
# keeps only the latest output and puts it first in every model call, so a tag
# that read differently on each resume would end the prompt cache's reuse.
# POSIX sh, except that `sleep 0.1` takes a fraction of a second.

input=$(cat)
id=$(printf '%s' "$input" | sed -n 's/.*"sessionId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
if [ -z "$id" ]; then
  id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
fi
[ -n "$id" ] || exit 0

log="${COPILOT_HOME:-$HOME/.copilot}/session-state/$id/events.jsonl"

# Prints the model of the last model_change or start line in the log. grep and
# sed read the log, not a shell loop: some shells read a line a byte at a time,
# which is too slow for a long session's log.
latest_model() {
  grep -F -e '"type":"session.model_change"' -e '"type":"session.start"' "$log" 2>/dev/null |
    sed -n \
      -e '/"type":"session\.model_change"/{' \
      -e 's/.*"newModel":"\([^"\\]*\).*/\1/p' \
      -e 'd' \
      -e '}' \
      -e 's/.*"selectedModel":"\([^"\\]*\).*/\1/p' |
    sed '/^$/d' | tail -n 1
}

tries=0
while [ "$tries" -lt 50 ]; do
  if [ -f "$log" ]; then
    model=$(latest_model)
    if [ -n "$model" ]; then
      printf '{"additionalContext":"<session_model>This session'"'"'s model ID is %s.</session_model>"}\n' "$model"
      exit 0
    fi
  fi
  tries=$((tries + 1))
  sleep 0.1
done
exit 0
