# Claude Code statusline: model (effort), context usage, and 5h/7d rate limit usage with reset countdowns.
# Session name (if present) is right-aligned to the terminal width.
#
# Windows port of statusline-command.sh, which is the source of truth: mirror
# its changes here so both render the same line. Must stay compatible with
# Windows PowerShell 5.1 (no ??, ?:, or other pwsh-only syntax).
#
# Installed by /cc:install-statusline. Keep this line: the installer uses it to
# tell its own (possibly older) script apart from one the user wrote.

$ErrorActionPreference = 'Stop'

try {
  [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch {}

# Claude Code insets the status line from the terminal edge.
$rightMargin = 2

$data = [Console]::In.ReadToEnd() | ConvertFrom-Json
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$esc = [char]27
# Built from code points: PowerShell 5.1 reads a BOM-less script as ANSI, so
# this file must stay pure ASCII.
$dot = [char]0x00B7
$ellipsis = [char]0x2026

$sessionName = [string]$data.session_name
$model = [string]$data.model.display_name
$effort = [string]$data.effort.level
$usedPct = $data.context_window.used_percentage

# Format-Countdown SECONDS -> "6d4h" / "2h15m" / "45m" / "now"
function Format-Countdown([long]$diff) {
  if ($diff -le 0) { return 'now' }
  $days = [math]::Floor($diff / 86400)
  if ($days -ge 1) {
    $hours = [math]::Floor(($diff % 86400) / 3600)
    return "${days}d${hours}h"
  }
  $hours = [math]::Floor($diff / 3600)
  if ($hours -ge 1) {
    $mins = [math]::Floor(($diff % 3600) / 60)
    return "${hours}h${mins}m"
  }
  $mins = [math]::Floor($diff / 60)
  return "${mins}m"
}

# Format-Pct PCT YELLOW_THRESHOLD RED_THRESHOLD [RESETS_AT WINDOW_SECONDS] -> "NN%" colored
# When RESETS_AT/WINDOW_SECONDS are given, green if PCT is below the expected
# pace for how much of the window has elapsed, resolved to whole hours (e.g. a
# 7-day window has 168 hour-buckets of 100%/168 = ~0.6% each, ~14% per day,
# so the started hour already grants 1/168; a 5h window grants 1/5 per
# started hour); otherwise
# falls back to yellow (YELLOW_THRESHOLD..<RED_THRESHOLD) or red
# (>=RED_THRESHOLD), plain below YELLOW_THRESHOLD.
function Format-Pct([double]$pct, [double]$yellow, [double]$red, $resetsAt, $windowSeconds) {
  $color = ''

  if ($null -ne $resetsAt -and $null -ne $windowSeconds) {
    $elapsed = [long]$windowSeconds - ([long]$resetsAt - $now)
    if ($elapsed -lt 0) { $elapsed = 0 }
    if ($elapsed -gt $windowSeconds) { $elapsed = [long]$windowSeconds }
    $totalHours = [math]::Floor($windowSeconds / 3600)
    $hoursElapsed = [math]::Floor(($elapsed + 3599) / 3600)
    if ($hoursElapsed -gt $totalHours) { $hoursElapsed = $totalHours }
    $expectedPct = [math]::Round(($hoursElapsed / $totalHours) * 100, 4)
    if ($pct -lt $expectedPct) { $color = "$esc[32m" }
  }

  if (-not $color) {
    if ($pct -ge $red) { $color = "$esc[31m" }
    elseif ($pct -ge $yellow) { $color = "$esc[33m" }
  }

  $rounded = [math]::Round($pct, [MidpointRounding]::ToEven)
  if ($color) { return "$color$rounded%$esc[0m" }
  return "$rounded%"
}

$parts = @()

if ($model) {
  if ($effort) { $parts += "$model ($effort)" } else { $parts += $model }
}

# Usage stats (ctx/5h/7d) always show, displaying "-" before any data exists
# (e.g. no messages sent yet, or before the first rate-limit report arrives).
if ($null -ne $usedPct) {
  $parts += "ctx $(Format-Pct $usedPct 50 85)"
} else {
  $parts += 'ctx -'
}

foreach ($window in @(
    @{ Label = '5h'; Data = $data.rate_limits.five_hour; Seconds = 18000 },
    @{ Label = '7d'; Data = $data.rate_limits.seven_day; Seconds = 604800 })) {
  $pct = $window.Data.used_percentage
  $resets = $window.Data.resets_at
  if ($null -ne $pct) {
    $str = "$($window.Label) $(Format-Pct $pct 75 90 $resets $window.Seconds)"
    if ($null -ne $resets -and $pct -ge 50) {
      $str += "/$(Format-Countdown ([long]$resets - $now))"
    }
  } else {
    $str = "$($window.Label) -"
  }
  $parts += $str
}

$left = $parts -join " $dot "

if ($sessionName) {
  if ($sessionName.Length -gt 24) {
    $sessionName = $sessionName.Substring(0, 23) + $ellipsis
  }

  $strippedLeft = $left -replace "$esc\[[0-9;]*m", ''
  $cols = 0
  [void][int]::TryParse([string]$env:COLUMNS, [ref]$cols)
  $gap = $cols - $rightMargin - $strippedLeft.Length - $sessionName.Length

  if ($cols -gt 0 -and $gap -ge 2) {
    [Console]::Out.Write($left + (' ' * $gap) + $sessionName)
  } else {
    [Console]::Out.Write("$left $dot $sessionName")
  }
} else {
  [Console]::Out.Write($left)
}
