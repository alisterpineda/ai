# session-model.ps1 — Copilot sessionStart hook: tells the session its model ID.
# The PowerShell twin of session-model.sh, for hosts without sh (Windows); the
# two print the same tag and must change together.
# Reads the hook's JSON from stdin, finds the session's log
# (<COPILOT_HOME or ~/.copilot>/session-state/<id>/events.jsonl), and prints an
# additionalContext tag naming the model of the log's latest model event.
# Prints nothing and exits 0 when the ID or the model can't be found.

$ErrorActionPreference = 'Stop'
try {
    $in = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $id = if ($in.sessionId) { $in.sessionId } else { $in.session_id }
    if (-not $id) { exit 0 }
    $root = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $HOME '.copilot' }
    $events = Join-Path $root "session-state/$id/events.jsonl"

    # A new session's log can appear a moment after the hook starts.
    $model = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $model -and $sw.ElapsedMilliseconds -lt 5000) {
        if (Test-Path -LiteralPath $events) {
            # Opened for shared read and write: the host is still appending to the log.
            $fs = [System.IO.FileStream]::new($events, 'Open', 'Read', 'ReadWrite')
            $reader = [System.IO.StreamReader]::new($fs)
            try {
                while ($null -ne ($line = $reader.ReadLine())) {
                    if ($line.Contains('"type":"session.model_change"')) {
                        if ($line -match '"newModel":"([^"\\]+)') { $model = $Matches[1] }
                    } elseif ($line.Contains('"type":"session.start"')) {
                        if ($line -match '"selectedModel":"([^"\\]+)') { $model = $Matches[1] }
                    }
                }
            } finally { $reader.Dispose(); $fs.Dispose() }
        }
        if (-not $model) { Start-Sleep -Milliseconds 100 }
    }
    if (-not $model) { exit 0 }

    $at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    $text = "<session_model at=`"$at`">This session's model ID is $model. When several session_model tags are present, the one with the latest time is current.</session_model>"
    @{ additionalContext = $text } | ConvertTo-Json -Compress
} catch { }
exit 0
