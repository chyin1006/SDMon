Set-StrictMode -Version 3.0

function Invoke-SDMonNetworkCollector {
    $events = @()

    if (-not (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue)) {
        $events += New-SDMonEvent -Category "network" -Type "collector_status" -Action "not_available" -Target "Get-NetTCPConnection" -Severity "Info" -Message "TCP connection collector command is not available."
        return $events
    }

    try {
        $connections = Get-NetTCPConnection -ErrorAction Stop
        if (-not $connections) {
            $events += New-SDMonEvent -Category "network" -Type "tcp_connection" -Action "empty" -Target "TCP" -Severity "Info" -Message "No TCP connections were returned."
            return $events
        }

        foreach ($connection in $connections) {
            $state = [string]$connection.State
            $action = if ([string]::IsNullOrWhiteSpace($state)) { "observed" } else { $state.ToLowerInvariant() }
            $target = ("{0}:{1} -> {2}:{3}" -f $connection.LocalAddress, $connection.LocalPort, $connection.RemoteAddress, $connection.RemotePort)
            $message = if ($state -eq "Listen") { "Listening TCP port observed; review recommended if unexpected." } else { "TCP connection observed." }

            $events += New-SDMonEvent -Category "network" -Type "tcp_connection" -Action $action -Target $target -Severity "Info" -Message $message -Recommendation "Review listening ports and connections against expected endpoint behavior." -Details @{
                local_address  = [string]$connection.LocalAddress
                local_port     = [int]$connection.LocalPort
                remote_address = [string]$connection.RemoteAddress
                remote_port    = [int]$connection.RemotePort
                state          = $state
                owning_pid     = [int]$connection.OwningProcess
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "network" -Type "permission_warning" -Action "permission_denied" -Target "Get-NetTCPConnection" -Severity "Info" -Message "TCP connection information could not be read." -Details @{ error = $_.Exception.Message }
    }

    return $events
}
