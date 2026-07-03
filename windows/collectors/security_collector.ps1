Set-StrictMode -Version 3.0

function Test-SDMonIsAdministrator {
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Invoke-SDMonSecurityCollector {
    $events = @()
    $isAdmin = Test-SDMonIsAdministrator

    $events += New-SDMonEvent -Category "security" -Type "elevation_status" -Action "checked" -Target "current_user" -Severity "Info" -Message "Current user elevation status checked." -Details @{
        is_administrator = $isAdmin
    }

    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        try {
            $defender = Get-MpComputerStatus -ErrorAction Stop
            $enabled = [bool]$defender.AntivirusEnabled
            $severity = if ($enabled) { "Info" } else { "Medium" }
            $message = if ($enabled) { "Windows Defender appears enabled." } else { "Windows Defender appears disabled; review recommended." }
            $recommendation = if ($enabled) { "" } else { "Review Microsoft Defender status and confirm endpoint protection policy." }
            $events += New-SDMonEvent -Category "security" -Type "defender_status" -Action "checked" -Target "Windows Defender" -Severity $severity -Message $message -Recommendation $recommendation -Details @{
                antivirus_enabled = $enabled
                real_time_enabled = [bool]$defender.RealTimeProtectionEnabled
            }
        } catch {
            $events += New-SDMonEvent -Category "security" -Type "permission_warning" -Action "permission_denied" -Target "Windows Defender" -Severity "Info" -Message "Windows Defender status could not be read." -Details @{ error = $_.Exception.Message }
        }
    } else {
        $events += New-SDMonEvent -Category "security" -Type "defender_status" -Action "not_available" -Target "Windows Defender" -Severity "Medium" -Message "Windows Defender status command is not available; review recommended." -Recommendation "Confirm endpoint protection status through enterprise management tools."
    }

    if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
        try {
            $profiles = Get-NetFirewallProfile -ErrorAction Stop
            foreach ($profile in $profiles) {
                $enabled = [bool]$profile.Enabled
                $severity = if ($enabled) { "Info" } else { "Medium" }
                $message = if ($enabled) { "Firewall profile is enabled." } else { "Firewall profile appears disabled; review recommended." }
                $recommendation = if ($enabled) { "" } else { "Enable or validate Windows Firewall policy for this profile." }
                $events += New-SDMonEvent -Category "security" -Type "firewall_status" -Action "checked" -Target ([string]$profile.Name) -Severity $severity -Message $message -Recommendation $recommendation -Details @{
                    profile = [string]$profile.Name
                    enabled = $enabled
                }
            }
        } catch {
            $events += New-SDMonEvent -Category "security" -Type "permission_warning" -Action "permission_denied" -Target "Windows Firewall" -Severity "Info" -Message "Firewall profile status could not be read." -Details @{ error = $_.Exception.Message }
        }
    } else {
        $events += New-SDMonEvent -Category "security" -Type "firewall_status" -Action "not_available" -Target "Windows Firewall" -Severity "Medium" -Message "Firewall status command is not available; review recommended." -Recommendation "Confirm Windows Firewall profile status through approved management tools."
    }

    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        try {
            $volumes = Get-BitLockerVolume -ErrorAction Stop
            foreach ($volume in $volumes) {
                $protected = ([string]$volume.ProtectionStatus -eq "On")
                $severity = if ($protected) { "Info" } else { "Low" }
                $message = if ($protected) { "BitLocker protection appears enabled." } else { "BitLocker protection appears off or unavailable; review recommended." }
                $recommendation = if ($protected) { "" } else { "Review BitLocker policy and recovery key management." }
                $events += New-SDMonEvent -Category "security" -Type "bitlocker_status" -Action "checked" -Target ([string]$volume.MountPoint) -Severity $severity -Message $message -Recommendation $recommendation -Details @{
                    mount_point       = [string]$volume.MountPoint
                    protection_status = [string]$volume.ProtectionStatus
                    volume_status     = [string]$volume.VolumeStatus
                }
            }
        } catch {
            $events += New-SDMonEvent -Category "security" -Type "permission_warning" -Action "permission_denied" -Target "BitLocker" -Severity "Info" -Message "BitLocker status could not be read." -Details @{ error = $_.Exception.Message }
        }
    } else {
        $events += New-SDMonEvent -Category "security" -Type "bitlocker_status" -Action "not_available" -Target "BitLocker" -Severity "Low" -Message "BitLocker status command is not available; review recommended." -Recommendation "Confirm disk encryption status through enterprise policy."
    }

    try {
        $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $uac = Get-ItemProperty -Path $uacPath -Name EnableLUA -ErrorAction Stop
        $enabled = ([int]$uac.EnableLUA -eq 1)
        $severity = if ($enabled) { "Info" } else { "Medium" }
        $message = if ($enabled) { "UAC appears enabled." } else { "UAC appears disabled; review recommended." }
        $recommendation = if ($enabled) { "" } else { "Review User Account Control policy." }
        $events += New-SDMonEvent -Category "security" -Type "uac_status" -Action "checked" -Target "EnableLUA" -Severity $severity -Message $message -Recommendation $recommendation -Details @{
            registry_path = $uacPath
            enable_lua    = [int]$uac.EnableLUA
        }
    } catch {
        $events += New-SDMonEvent -Category "security" -Type "permission_warning" -Action "permission_denied" -Target "UAC" -Severity "Info" -Message "UAC registry value could not be read." -Details @{ error = $_.Exception.Message }
    }

    return $events
}
