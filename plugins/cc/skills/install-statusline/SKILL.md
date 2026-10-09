---
name: install-statusline
description: "Installs this plugin's Claude Code status line (model and effort, context usage, 5h/7d rate-limit pace with reset countdowns, right-aligned session name) into the user's Claude config: copies the script and points settings.json's statusLine at it, backing up anything it replaces. Re-run to update after a plugin upgrade. Usage: /cc:install-statusline. Takes no arguments. User-invoked only — never invoke this skill on your own initiative."
compatibility: "Claude Code only: the status line is a Claude Code feature, and the body relies on ${CLAUDE_PLUGIN_ROOT}. macOS/Linux need bash and jq; Windows uses Windows PowerShell 5.1+ and needs nothing extra."

# Non-spec extension. It writes to the user's global settings.json, so it must
# start because the user asked, never because the model decided to.
disable-model-invocation: true
user-invocable: true
---

# Install Status Line

Install the bundled status line into the user's Claude Code config. The installers do all the file work and are idempotent; your job is to pick the right one, show the user what will change, and get consent before replacing someone else's status line.

The scripts live in `${CLAUDE_PLUGIN_ROOT}/skills/install-statusline/scripts/`:

| Platform | Installer | Installs |
|---|---|---|
| macOS, Linux | `bash "<scripts>/install.sh"` | `statusline-command.sh` |
| Windows (native, not WSL) | `powershell -NoProfile -ExecutionPolicy Bypass -File "<scripts>/install.ps1"` | `statusline-command.ps1` |

Pick by the platform in your environment info. On Windows, always use the PowerShell installer, even when Git Bash is present; the command above works from both Bash and PowerShell tools. Use forward slashes in the path.

Both installers take the same flags (`--check`, `--replace`) and print the same `key: value` lines.

## Step 1: Check

Run the installer with `--check`. It changes nothing and reports:

- `statusline:` — `absent` (none set), `ours` (already points at this script), or `other` (a different command).
- `current_command:` — the command currently set, if any.
- `script:` — the installed `statusline-command` script is `missing`, the `same` as the bundled one, an older bundled version (`differs`), or one the user wrote themselves (`foreign`).

If it exits non-zero, stop and relay the error. On macOS/Linux the likely cause is a missing `jq`.

## Step 2: Confirm if replacing

Ask before overwriting anything that isn't ours, naming each thing that will be replaced:

- `statusline: other` — show the `current_command`; `settings.json` will be pointed at the bundled script.
- `script: foreign` — the user's own script at that path will be overwritten.

Mention that each replaced file is first backed up beside it as `<file>.<timestamp>.bak`. Ask once, covering both if both apply. If they decline, stop.

Otherwise go straight to Step 3: installing fresh or updating an older bundled version needs no confirmation.

## Step 3: Install

Run the installer with no flags, or with `--replace` if the user approved replacing in Step 2. Exit code 3 means something not ours would be overwritten and `--replace` was missing — go back to Step 2 rather than adding the flag yourself.

## Step 4: Report

Summarize from the output: what was written, what was backed up (`backed_up:` lines), or that everything was already up to date. Then tell the user:

- The status line appears on the next refresh, after the next message.
- On macOS/Linux it needs `jq` at runtime as well.
- On Windows, if the installer updated `settings.json`, it rewrote it in PowerShell's JSON style, which re-indents it and may escape characters like `&` as `\u0026`. The meaning is unchanged, and the original is in the `settings.json.<timestamp>.bak` it reported.
- To pick up future versions, update the plugin and run `/cc:install-statusline` again.
