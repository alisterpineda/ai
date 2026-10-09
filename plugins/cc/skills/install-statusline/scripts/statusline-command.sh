#!/bin/bash
# Claude Code statusline: model (effort), context usage, and 5h/7d rate limit usage with reset countdowns.
# Session name (if present) is right-aligned to the terminal width.
#
# Source of truth for statusline-command.ps1 (the Windows port). Change this
# file first, then mirror the change there so both render the same line.
#
# Installed by /cc:install-statusline. Keep this line: the installer uses it to
# tell its own (possibly older) script apart from one the user wrote.

export LC_ALL=C.UTF-8

# Claude Code insets the status line from the terminal edge.
right_margin=2

input=$(cat)
now=$(date +%s)

session_name=$(echo "$input" | jq -r '.session_name // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# format_countdown SECONDS -> "6d4h" / "2h15m" / "45m" / "now"
format_countdown() {
  local diff=$1
  if [ -z "$diff" ] || [ "$diff" -le 0 ]; then
    printf 'now'
    return
  fi
  local days=$((diff / 86400))
  if [ "$days" -ge 1 ]; then
    local hours=$(((diff % 86400) / 3600))
    printf '%dd%dh' "$days" "$hours"
    return
  fi
  local hours=$((diff / 3600))
  if [ "$hours" -ge 1 ]; then
    local mins=$(((diff % 3600) / 60))
    printf '%dh%dm' "$hours" "$mins"
    return
  fi
  local mins=$((diff / 60))
  printf '%dm' "$mins"
}

# colorize_pct PCT ROUNDED YELLOW_THRESHOLD RED_THRESHOLD [RESETS_AT WINDOW_SECONDS] -> "NN%" colored
# When RESETS_AT/WINDOW_SECONDS are given, green if PCT is below the expected
# pace for how much of the window has elapsed, resolved to whole hours (e.g. a
# 7-day window has 168 hour-buckets of 100%/168 = ~0.6% each, ~14% per day,
# so the started hour already grants 1/168; a 5h window grants 1/5 per
# started hour); otherwise
# falls back to yellow (YELLOW_THRESHOLD..<RED_THRESHOLD) or red
# (>=RED_THRESHOLD), plain below YELLOW_THRESHOLD.
colorize_pct() {
  local pct=$1
  local rounded=$2
  local yellow=$3
  local red=$4
  local resets_at=$5
  local window_seconds=$6
  local color=""

  if [ -n "$resets_at" ] && [ -n "$window_seconds" ]; then
    local elapsed=$((window_seconds - (resets_at - now)))
    if [ "$elapsed" -lt 0 ]; then elapsed=0; fi
    if [ "$elapsed" -gt "$window_seconds" ]; then elapsed=$window_seconds; fi
    local total_hours=$((window_seconds / 3600))
    local hours_elapsed=$(( (elapsed + 3599) / 3600 ))
    if [ "$hours_elapsed" -lt 0 ]; then hours_elapsed=0; fi
    if [ "$hours_elapsed" -gt "$total_hours" ]; then hours_elapsed=$total_hours; fi
    local expected_pct
    expected_pct=$(awk -v h="$hours_elapsed" -v t="$total_hours" 'BEGIN{printf "%.4f", (h/t)*100}')
    if awk -v p="$pct" -v e="$expected_pct" 'BEGIN{exit !(p<e)}'; then
      color=$'\033[32m'
    fi
  fi

  if [ -z "$color" ]; then
    if awk -v p="$pct" -v r="$red" 'BEGIN{exit !(p>=r)}'; then
      color=$'\033[31m'
    elif awk -v p="$pct" -v y="$yellow" 'BEGIN{exit !(p>=y)}'; then
      color=$'\033[33m'
    fi
  fi

  if [ -n "$color" ]; then
    printf '%s%d%%\033[0m' "$color" "$rounded"
  else
    printf '%d%%' "$rounded"
  fi
}

parts=()

if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    parts+=("$model ($effort)")
  else
    parts+=("$model")
  fi
fi

# Usage stats (ctx/5h/7d) always show, displaying "-" before any data exists
# (e.g. no messages sent yet, or before the first rate-limit report arrives).
if [ -n "$used_pct" ]; then
  used_rounded=$(printf '%.0f' "$used_pct")
  parts+=("ctx $(colorize_pct "$used_pct" "$used_rounded" 50 85)")
else
  parts+=("ctx -")
fi

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five_pct" ]; then
  five_rounded=$(printf '%.0f' "$five_pct")
  five_str="5h $(colorize_pct "$five_pct" "$five_rounded" 75 90 "$five_resets" 18000)"
  if [ -n "$five_resets" ] && awk -v p="$five_pct" 'BEGIN{exit !(p>=50)}'; then
    five_str="${five_str}/$(format_countdown $((five_resets - now)))"
  fi
else
  five_str="5h -"
fi
parts+=("$five_str")

week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ]; then
  week_rounded=$(printf '%.0f' "$week_pct")
  week_str="7d $(colorize_pct "$week_pct" "$week_rounded" 75 90 "$week_resets" 604800)"
  if [ -n "$week_resets" ] && awk -v p="$week_pct" 'BEGIN{exit !(p>=50)}'; then
    week_str="${week_str}/$(format_countdown $((week_resets - now)))"
  fi
else
  week_str="7d -"
fi
parts+=("$week_str")

left=""
for part in "${parts[@]}"; do
  if [ -z "$left" ]; then
    left="$part"
  else
    left="$left · $part"
  fi
done

if [ -n "$session_name" ]; then
  if [ "${#session_name}" -gt 24 ]; then
    session_name="${session_name:0:23}…"
  fi

  esc=$'\033'
  stripped_left=$(printf '%s' "$left" | sed -E "s/${esc}\[[0-9;]*m//g")
  width_left=${#stripped_left}
  width_name=${#session_name}

  cols="${COLUMNS:-0}"
  gap=$((cols - right_margin - width_left - width_name))

  if [ "$cols" -gt 0 ] && [ "$gap" -ge 2 ]; then
    printf '%s' "$left"
    printf '%*s' "$gap" ""
    printf '%s' "$session_name"
  else
    printf '%s · %s' "$left" "$session_name"
  fi
else
  printf '%s' "$left"
fi
