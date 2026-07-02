Set-StrictMode -Version 3.0

function Test-SDMonLikelyMicrosoftServicePath {
    param([AllowNull()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    $windowsRoot = $env:windir
    if ([string]::IsNullOrWhiteSpace($windowsRoot)) {
        $windowsRoot = "C:\Windows"
    }

    $normalizedPath = $Path.Trim().Trim('"')
    if ($normalizedPath.StartsWith("%SystemRoot%", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    if ($normalizedPath.StartsWith("%windir%", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $normalizedPath.StartsWith($windowsRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Invoke-SDMonServiceCollector {
    $events = @()

    if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
        $events += New-SDMonEvent -Category "service" -Type "collector_status" -Action "not_available" -Target "Get-CimInstance" -Severity "Info" -Message "Service collector command is not available."
        return $events
    }

    try {
        $services = Get-CimInstance -ClassName Win32_Service -ErrorAction Stop
        foreach ($service in $services) {
            $pathName = [string]$service.PathName
            $isAutoStart = ([string]$service.StartMode -eq "Auto")
            $isMicrosoftPath = Test-SDMonLikelyMicrosoftServicePath -Path $pathName
            $message = if ($isAutoStart -and -not $isMicrosoftPath) { "Auto-start service observed; review recommended." } else { "Service observed." }

            $events += New-SDMonEvent -Category "service" -Type "service_observed" -Action "observed" -Target ([string]$service.Name) -Severity "Info" -Message $message -Recommendation "Review service metadata if the service is unexpected." -Details @{
                name           = [string]$service.Name
                display_name   = [string]$service.DisplayName
                state          = [string]$service.State
                status         = [string]$service.Status
                start_type     = [string]$service.StartMode
                path           = $pathName
                auto_start     = $isAutoStart
                microsoft_path = $isMicrosoftPath
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "service" -Type "permission_warning" -Action "permission_denied" -Target "Win32_Service" -Severity "Info" -Message "Service information could not be read." -Details @{ error = $_.Exception.Message }
    }

    return $events
}
