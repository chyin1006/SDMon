Set-StrictMode -Version 3.0

function Invoke-SDMonEventLogCollector {
    $events = @()

    if (-not (Get-Command Get-WinEvent -ErrorAction SilentlyContinue)) {
        $events += New-SDMonEvent -Category "event_log" -Type "collector_status" -Action "not_available" -Target "Get-WinEvent" -Severity "Info" -Message "Event log collector command is not available."
        return $events
    }

    $since = (Get-Date).AddDays(-1)
    $logs = @("Application", "System", "Security")

    foreach ($logName in $logs) {
        try {
            $eventErrors = @()
            $recentEvents = @(Get-WinEvent -FilterHashtable @{ LogName = $logName; StartTime = $since } -MaxEvents 2000 -ErrorAction SilentlyContinue -ErrorVariable eventErrors)
            if ($eventErrors -and @($recentEvents).Count -eq 0) {
                $errorText = [string]$eventErrors[0].Exception.Message
                if ($errorText -notmatch "No events were found") {
                    throw $eventErrors[0].Exception
                }
            }
            $count = @($recentEvents).Count
            $events += New-SDMonEvent -Category "event_log" -Type "recent_event_count" -Action "counted" -Target $logName -Severity "Info" -Message "Recent Windows event log count collected." -Details @{
                log_name       = $logName
                since          = $since.ToUniversalTime().ToString("o")
                count          = $count
                sample_limited = ($count -ge 2000)
            }
        } catch {
            $events += New-SDMonEvent -Category "event_log" -Type "permission_warning" -Action "permission_denied" -Target $logName -Severity "Info" -Message "Recent Windows event log count could not be read." -Details @{ log_name = $logName; error = $_.Exception.Message }
        }
    }

    return $events
}
