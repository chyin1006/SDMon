Set-StrictMode -Version 3.0

function Get-SDMonTaskActionCommand {
    param([AllowNull()][object]$Task)

    if ($null -eq $Task) {
        return ""
    }

    try {
        $commands = @()
        foreach ($action in @($Task.Actions)) {
            if ($null -ne $action -and $action.PSObject.Properties["Execute"]) {
                $commands += [string]$action.Execute
            }
        }
        return ($commands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 3) -join "; "
    } catch {
        return ""
    }
}

function Invoke-SDMonScheduledTaskCollector {
    $events = @()

    if (-not (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        $events += New-SDMonEvent -Category "scheduled_task" -Type "collector_status" -Action "not_available" -Target "Get-ScheduledTask" -Severity "Info" -Message "Scheduled task collector command is not available."
        return $events
    }

    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop
        foreach ($task in $tasks) {
            $taskPath = [string]$task.TaskPath
            $isMicrosoftTask = $taskPath.StartsWith("\Microsoft\", [System.StringComparison]::OrdinalIgnoreCase)
            $state = [string]$task.State
            $actionCommand = Get-SDMonTaskActionCommand -Task $task
            $message = if (-not $isMicrosoftTask -and $state -ne "Disabled") { "Enabled non-Microsoft scheduled task observed; review recommended." } else { "Scheduled task observed." }

            $events += New-SDMonEvent -Category "scheduled_task" -Type "task_observed" -Action "observed" -Target ("{0}{1}" -f $taskPath, $task.TaskName) -Severity "Info" -Message $message -Recommendation "Review scheduled tasks against approved endpoint configuration." -Details @{
                task_name       = [string]$task.TaskName
                task_path       = $taskPath
                state           = $state
                action_command  = $actionCommand
                microsoft_task  = $isMicrosoftTask
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "scheduled_task" -Type "permission_warning" -Action "permission_denied" -Target "Get-ScheduledTask" -Severity "Info" -Message "Scheduled task information could not be read." -Details @{ error = $_.Exception.Message }
    }

    return $events
}
