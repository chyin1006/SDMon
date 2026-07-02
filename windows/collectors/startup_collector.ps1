Set-StrictMode -Version 3.0

function Add-SDMonStartupFolderEvents {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Scope
    )

    $events = @()
    if (-not (Test-Path -LiteralPath $Path)) {
        $events += New-SDMonEvent -Category "startup" -Type "startup_folder" -Action "not_found" -Target $Path -Severity "Info" -Message "Startup folder does not exist." -Details @{ scope = $Scope; path = $Path }
        return $events
    }

    try {
        $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop
        if (-not $items) {
            $events += New-SDMonEvent -Category "startup" -Type "startup_folder" -Action "empty" -Target $Path -Severity "Info" -Message "Startup folder is empty." -Details @{ scope = $Scope; path = $Path }
            return $events
        }

        foreach ($item in $items) {
            $events += New-SDMonEvent -Category "startup" -Type "startup_folder_item" -Action "found" -Target $item.FullName -Severity "Low" -Message "Startup folder item found; review recommended." -Recommendation "Confirm startup item is expected and approved." -Details @{
                scope = $Scope
                name = $item.Name
                path = $item.FullName
                item_type = if ($item.PSIsContainer) { "directory" } else { "file" }
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "startup" -Type "permission_warning" -Action "permission_denied" -Target $Path -Severity "Info" -Message "Startup folder could not be read." -Details @{ scope = $Scope; error = $_.Exception.Message }
    }

    return $events
}

function Add-SDMonRunKeyEvents {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Scope
    )

    $events = @()
    try {
        if (-not (Test-Path -Path $Path)) {
            $events += New-SDMonEvent -Category "startup" -Type "run_key" -Action "not_found" -Target $Path -Severity "Info" -Message "Run key does not exist." -Details @{ scope = $Scope; path = $Path }
            return $events
        }

        $props = Get-ItemProperty -Path $Path -ErrorAction Stop
        $names = $props.PSObject.Properties | Where-Object {
            $_.Name -notmatch '^PS(ChildName|Drive|ParentPath|Path|Provider)$'
        }

        if (-not $names) {
            $events += New-SDMonEvent -Category "startup" -Type "run_key" -Action "empty" -Target $Path -Severity "Info" -Message "Run key has no startup values." -Details @{ scope = $Scope; path = $Path }
            return $events
        }

        foreach ($prop in $names) {
            $events += New-SDMonEvent -Category "startup" -Type "run_key_item" -Action "found" -Target ([string]$prop.Name) -Severity "Low" -Message "Run key startup item found; review recommended." -Recommendation "Confirm startup registry value is expected and approved." -Details @{
                scope = $Scope
                registry_path = $Path
                name = [string]$prop.Name
                value = [string]$prop.Value
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "startup" -Type "permission_warning" -Action "permission_denied" -Target $Path -Severity "Info" -Message "Run key could not be read." -Details @{ scope = $Scope; error = $_.Exception.Message }
    }

    return $events
}

function Invoke-SDMonStartupCollector {
    $events = @()

    $userStartup = [Environment]::GetFolderPath("Startup")
    $commonStartup = [Environment]::GetFolderPath("CommonStartup")

    if ($userStartup) {
        $events += Add-SDMonStartupFolderEvents -Path $userStartup -Scope "user"
    }
    if ($commonStartup) {
        $events += Add-SDMonStartupFolderEvents -Path $commonStartup -Scope "common"
    }

    $events += Add-SDMonRunKeyEvents -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Scope "user"
    $events += Add-SDMonRunKeyEvents -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Scope "machine"

    return $events
}
