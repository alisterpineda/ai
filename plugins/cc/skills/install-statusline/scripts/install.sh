#!/usr/bin/env bash
# install.sh — install the bundled status line into Claude Code (macOS / Linux).
#
# Usage:
#   install.sh --check     report the current state; change nothing
#   install.sh [--replace] install; --replace is required to overwrite a
#                          statusLine that points at some other command, or a
#                          statusline-command.sh the user wrote themselves
#
# Copies statusline-command.sh into the Claude config dir
# (${CLAUDE_CONFIG_DIR:-$HOME/.claude}) and points settings.json's statusLine
# at it. Anything it overwrites is first saved as <file>.<timestamp>.bak, so
# no backup is ever overwritten. settings.json is rewritten in place, which
# follows a symlink and keeps the file's mode. Re-running when everything
# already matches writes nothing.
#
# Windows counterpart: install.ps1. Keep flags, states, and output in step.
# Tests: install-test.sh.
#
# Exit codes: 0 ok, 1 error, 3 something not ours would be overwritten and
# --replace was not given.

set -euo pipefail

mode=install
replace=0
for arg in "$@"; do
  case "$arg" in
    --check) mode=check ;;
    --replace) replace=1 ;;
    *) echo "error: unknown argument '$arg' (supported: --check, --replace)" >&2; exit 1 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (the status line itself also needs it). Install it, e.g. 'brew install jq' or 'apt install jq'." >&2
  exit 1
fi

# Present in every version of the bundled script; see its header.
marker='Installed by /cc:install-statusline'

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statusline-command.sh"
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
settings="$config_dir/settings.json"
target="$config_dir/statusline-command.sh"
stamp=$(date +%Y%m%d-%H%M%S)

# backup PATH -> copies PATH to a fresh PATH.<stamp>[-N].bak, keeping its mode.
backup() {
  local bak="$1.$stamp.bak" n=1
  while [ -e "$bak" ]; do bak="$1.$stamp-$n.bak"; n=$((n + 1)); done
  cp -p "$1" "$bak"
  echo "backed_up: $bak"
}

# Keep the portable $HOME form for the default location so settings.json
# stays valid if it is synced between machines.
if [ "$config_dir" = "$HOME/.claude" ]; then
  want_cmd='bash "$HOME/.claude/statusline-command.sh"'
else
  want_cmd="bash \"$target\""
fi

if [ -f "$settings" ]; then
  if ! jq -e . "$settings" >/dev/null 2>&1; then
    echo "error: $settings is not valid JSON; fix it before installing." >&2
    exit 1
  fi
  current_cmd=$(jq -r '.statusLine.command // empty' "$settings")
  current_type=$(jq -r '.statusLine.type // empty' "$settings")
else
  current_cmd=""
  current_type=""
fi

if [ -z "$current_cmd" ]; then
  state=absent
elif [ "$current_cmd" = "$want_cmd" ] && [ "$current_type" = "command" ]; then
  state=ours
else
  state=other
fi

# differs: an older bundled version. foreign: a script the user wrote.
if [ ! -f "$target" ]; then
  script_state=missing
elif cmp -s "$src" "$target"; then
  script_state=same
elif grep -qF "$marker" "$target"; then
  script_state=differs
else
  script_state=foreign
fi

echo "config_dir: $config_dir"
echo "statusline: $state"
[ -n "$current_cmd" ] && echo "current_command: $current_cmd"
echo "script: $script_state"

[ "$mode" = check ] && exit 0

if [ "$replace" -ne 1 ]; then
  if [ "$state" = other ]; then
    echo "error: statusLine already runs a different command; re-run with --replace to overwrite it (the old settings are backed up)." >&2
    exit 3
  fi
  if [ "$script_state" = foreign ]; then
    echo "error: $target was not installed by this skill; re-run with --replace to overwrite it (the old script is backed up)." >&2
    exit 3
  fi
fi

if [ "$state" = ours ] && [ "$script_state" = same ]; then
  echo "result: already up to date"
  exit 0
fi

mkdir -p "$config_dir"

if [ "$script_state" != same ]; then
  if [ "$script_state" != missing ]; then backup "$target"; fi
  cp "$src" "$target"
  chmod +x "$target"
  echo "wrote: $target"
fi

if [ "$state" != ours ]; then
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  if [ -f "$settings" ]; then
    backup "$settings"
    jq --arg cmd "$want_cmd" '.statusLine = ((.statusLine // {}) + {type: "command", command: $cmd})' "$settings" >"$tmp"
  else
    jq -n --arg cmd "$want_cmd" '{statusLine: {type: "command", command: $cmd}}' >"$tmp"
  fi
  # Write through the existing path rather than renaming over it: a rename
  # would replace a symlinked settings.json and reset its mode. The new
  # content is complete before this point, and the backup covers the rest.
  cat "$tmp" >"$settings"
  echo "updated: $settings"
fi

echo "result: installed"
