Set-StrictMode -Version 3.0

function Invoke-SDMonSystemCollector {
    $events = @()

    $hostname = $env:COMPUTERNAME
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $localTime = (Get-Date).ToString("o")
    $timezone = [System.TimeZoneInfo]::Local.DisplayName

    $osCaption = "unknown"
    $osVersion = "unknown"
    $architecture = "unknown"
    $uptime = "unknown"
    $cpuName = "unknown"
    $memoryGb = "unknown"

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $osCaption = [string]$os.Caption
        $osVersion = [string]$os.Version
        $architecture = [string]$os.OSArchitecture
        if ($os.LastBootUpTime) {
            $uptimeSpan = (Get-Date) - $os.LastBootUpTime
            $uptime = ("{0}d {1}h {2}m" -f $uptimeSpan.Days, $uptimeSpan.Hours, $uptimeSpan.Minutes)
        }
        if ($os.TotalVisibleMemorySize) {
            $memoryGb = ("{0:N1} GB" -f ($os.TotalVisibleMemorySize / 1MB))
        }
    } catch {
        $events += New-SDMonEvent -Category "system" -Type "permission_warning" -Action "system_info_partial" -Target "Win32_OperatingSystem" -Severity "Info" -Message "System information was partially unavailable." -Details @{ error = $_.Exception.Message }
    }

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpu.Name) {
            $cpuName = [string]$cpu.Name
        }
    } catch {
        $events += New-SDMonEvent -Category "system" -Type "permission_warning" -Action "cpu_info_partial" -Target "Win32_Processor" -Severity "Info" -Message "CPU information was partially unavailable." -Details @{ error = $_.Exception.Message }
    }

    $events += New-SDMonEvent -Category "system" -Type "system_summary" -Action "collected" -Target $hostname -Severity "Info" -Message "Windows system summary collected." -Details @{
        hostname           = $hostname
        current_user       = $currentUser
        windows_caption    = $osCaption
        windows_version    = $osVersion
        os_architecture    = $architecture
        powershell_version = $psVersion
        local_time         = $localTime
        timezone           = $timezone
        uptime             = $uptime
        cpu_name           = $cpuName
        memory             = $memoryGb
    }

    return $events
}
