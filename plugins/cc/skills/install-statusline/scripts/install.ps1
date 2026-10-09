# install.ps1 - install the bundled status line into Claude Code (Windows).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 --check
#       report the current state; change nothing
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 [--replace]
#       install; --replace is required to overwrite a statusLine that points
#       at some other command, or a statusline-command.ps1 the user wrote
#       themselves
#
# Copies statusline-command.ps1 into the Claude config dir
# ($env:CLAUDE_CONFIG_DIR, else ~/.claude) and points settings.json's
# statusLine at it. Anything it overwrites is first saved as
# <file>.<timestamp>.bak (with the original's ACL), so no backup is ever
# overwritten. settings.json is rewritten in place, which follows a symlink
# and keeps the file's ACL. Re-running when everything already matches writes
# nothing.
#
# Port of install.sh, which is the source of truth: same flags, states, output,
# and exit codes (install-test.sh covers install.sh only). Flags are parsed by
# hand (not param()) so both scripts take the same --check / --replace
# spelling. Must stay compatible with Windows PowerShell 5.1 and pure ASCII.
#
# Exit codes: 0 ok, 1 error, 3 something not ours would be overwritten and
# --replace was not given.

$ErrorActionPreference = 'Stop'

$mode = 'install'
$replace = $false
# One or two dashes: PowerShell's CLI may hand either spelling through.
foreach ($arg in $args) {
  switch -Regex ([string]$arg) {
    '^--?check$' { $mode = 'check' }
    '^--?replace$' { $replace = $true }
    default {
      [Console]::Error.WriteLine("error: unknown argument '$arg' (supported: --check, --replace)")
      exit 1
    }
  }
}

$utf8 = New-Object System.Text.UTF8Encoding $false

# Present in every version of the bundled script; see its header.
$marker = 'Installed by /cc:install-statusline'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# Copy-Backup PATH -> copies PATH to a fresh PATH.<stamp>[-N].bak. Copy-Item
# gives the copy the directory's inherited ACL, so carry the original's over.
function Copy-Backup([string]$path) {
  $bak = "$path.$stamp.bak"
  $n = 1
  while (Test-Path -LiteralPath $bak) { $bak = "$path.$stamp-$n.bak"; $n++ }
  Copy-Item -LiteralPath $path -Destination $bak
  try {
    Set-Acl -LiteralPath $bak -AclObject (Get-Acl -LiteralPath $path)
  } catch {
    [Console]::Error.WriteLine("warning: could not copy the ACL of $path to its backup: $($_.Exception.Message)")
  }
  Write-Output "backed_up: $bak"
}

$src = Join-Path $PSScriptRoot 'statusline-command.ps1'
if ($env:CLAUDE_CONFIG_DIR) { $configDir = $env:CLAUDE_CONFIG_DIR } else { $configDir = Join-Path $HOME '.claude' }
$settings = Join-Path $configDir 'settings.json'
$target = Join-Path $configDir 'statusline-command.ps1'

# Claude Code's Windows docs require forward slashes in statusLine paths
# (backslashes break when the command runs through Git Bash).
$targetFwd = $target -replace '\\', '/'
$wantCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$targetFwd`""

$json = $null
$currentCmd = ''
$currentType = ''
if (Test-Path -LiteralPath $settings -PathType Leaf) {
  try {
    $json = [IO.File]::ReadAllText($settings, $utf8) | ConvertFrom-Json
  } catch {
    $json = $null
  }
  if ($null -eq $json) {
    # 5.1's ConvertFrom-Json also rejects valid JSON with keys that differ
    # only in case, so don't claim the file is invalid.
    [Console]::Error.WriteLine("error: could not parse $settings as JSON; fix it (or install by hand) before installing.")
    exit 1
  }
  if ($null -ne $json.statusLine) {
    $currentCmd = [string]$json.statusLine.command
    $currentType = [string]$json.statusLine.type
  }
}

if (-not $currentCmd) {
  $state = 'absent'
} elseif ($currentCmd -eq $wantCmd -and $currentType -eq 'command') {
  $state = 'ours'
} else {
  $state = 'other'
}

if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
  $scriptState = 'missing'
} elseif ((Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $target).Hash) {
  $scriptState = 'same'
} elseif (Select-String -LiteralPath $target -SimpleMatch -Pattern $marker -Quiet) {
  # An older bundled version.
  $scriptState = 'differs'
} else {
  # A script the user wrote.
  $scriptState = 'foreign'
}

Write-Output "config_dir: $configDir"
Write-Output "statusline: $state"
if ($currentCmd) { Write-Output "current_command: $currentCmd" }
Write-Output "script: $scriptState"

if ($mode -eq 'check') { exit 0 }

if (-not $replace) {
  if ($state -eq 'other') {
    [Console]::Error.WriteLine('error: statusLine already runs a different command; re-run with --replace to overwrite it (the old settings are backed up).')
    exit 3
  }
  if ($scriptState -eq 'foreign') {
    [Console]::Error.WriteLine("error: $target was not installed by this skill; re-run with --replace to overwrite it (the old script is backed up).")
    exit 3
  }
}

if ($state -eq 'ours' -and $scriptState -eq 'same') {
  Write-Output 'result: already up to date'
  exit 0
}

New-Item -ItemType Directory -Force -Path $configDir | Out-Null

if ($scriptState -ne 'same') {
  if ($scriptState -ne 'missing') { Copy-Backup $target }
  Copy-Item -LiteralPath $src -Destination $target -Force
  Write-Output "wrote: $target"
}

if ($state -ne 'ours') {
  if ($null -eq $json) {
    $json = New-Object PSObject
  } else {
    Copy-Backup $settings
  }

  # Merge into any existing statusLine so fields like padding survive.
  $statusLine = $json.statusLine
  if ($null -eq $statusLine) {
    $statusLine = New-Object PSObject
    $json | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
  }
  $statusLine | Add-Member -NotePropertyName type -NotePropertyValue 'command' -Force
  $statusLine | Add-Member -NotePropertyName command -NotePropertyValue $wantCmd -Force

  # Truncate and write through the existing path rather than renaming a temp
  # file over it: a rename would replace a symlinked settings.json and drop
  # its ACL. The new content is complete before this point, and the backup
  # covers the rest.
  $out = ConvertTo-Json -InputObject $json -Depth 100
  [IO.File]::WriteAllText($settings, $out, $utf8)
  Write-Output "updated: $settings"
}

Write-Output 'result: installed'
