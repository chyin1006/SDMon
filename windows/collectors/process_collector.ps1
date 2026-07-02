Set-StrictMode -Version 3.0

function Get-SDMonFileVersionInfo {
    param([AllowNull()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [PSCustomObject]@{
            company = ""
            product = ""
        }
    }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return [PSCustomObject]@{
            company = [string]$item.VersionInfo.CompanyName
            product = [string]$item.VersionInfo.ProductName
        }
    } catch {
        return [PSCustomObject]@{
            company = ""
            product = ""
        }
    }
}

function Invoke-SDMonProcessCollector {
    $events = @()

    if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
        $events += New-SDMonEvent -Category "process" -Type "collector_status" -Action "not_available" -Target "Get-CimInstance" -Severity "Info" -Message "Process collector command is not available."
        return $events
    }

    try {
        $processes = Get-CimInstance -ClassName Win32_Process -ErrorAction Stop
        foreach ($process in $processes) {
            $processName = [string]$process.Name
            $processId = [int]$process.ProcessId
            $parentProcessId = [int]$process.ParentProcessId
            $processPath = [string]$process.ExecutablePath
            $versionInfo = Get-SDMonFileVersionInfo -Path $processPath
            $message = if ([string]::IsNullOrWhiteSpace($processPath)) { "Process path is not available; review if unexpected." } else { "Process observed." }

            $events += New-SDMonEvent -Category "process" -Type "process_observed" -Action "observed" -Target $processName -Severity "Info" -Message $message -Recommendation "Review process metadata if the process is unexpected." -Details @{
                process_name      = $processName
                pid               = $processId
                parent_pid        = $parentProcessId
                path              = $processPath
                company           = [string]$versionInfo.company
                product           = [string]$versionInfo.product
                path_available    = (-not [string]::IsNullOrWhiteSpace($processPath))
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "process" -Type "permission_warning" -Action "permission_denied" -Target "Win32_Process" -Severity "Info" -Message "Process information could not be read." -Details @{ error = $_.Exception.Message }
    }

    return $events
}
