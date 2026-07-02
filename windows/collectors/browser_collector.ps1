Set-StrictMode -Version 3.0

function Add-SDMonBrowserExtensionEvents {
    param(
        [Parameter(Mandatory = $true)][string]$Browser,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $events = @()
    if (-not (Test-Path -LiteralPath $Path)) {
        $events += New-SDMonEvent -Category "browser" -Type "extension_directory" -Action "not_found" -Target $Browser -Severity "Info" -Message "Browser extension directory was not found." -Details @{ browser = $Browser; path = $Path }
        return $events
    }

    try {
        $extensionDirs = Get-ChildItem -LiteralPath $Path -Directory -ErrorAction Stop
        if (-not $extensionDirs) {
            $events += New-SDMonEvent -Category "browser" -Type "extension_directory" -Action "empty" -Target $Browser -Severity "Info" -Message "Browser extension directory exists but no extension IDs were found." -Details @{ browser = $Browser; path = $Path }
            return $events
        }

        foreach ($dir in $extensionDirs) {
            $events += New-SDMonEvent -Category "browser" -Type "browser_extension" -Action "found" -Target $dir.Name -Severity "Info" -Message "Browser extension ID found; review recommended." -Recommendation "Review installed browser extensions against the approved software list." -Details @{
                browser = $Browser
                extension_id = $dir.Name
                extension_path = $dir.FullName
            }
        }
    } catch {
        $events += New-SDMonEvent -Category "browser" -Type "permission_warning" -Action "permission_denied" -Target $Browser -Severity "Info" -Message "Browser extension directory could not be read." -Details @{ browser = $Browser; path = $Path; error = $_.Exception.Message }
    }

    return $events
}

function Invoke-SDMonBrowserCollector {
    $events = @()
    $localAppData = $env:LOCALAPPDATA

    if (-not $localAppData) {
        $events += New-SDMonEvent -Category "browser" -Type "environment_warning" -Action "not_available" -Target "LOCALAPPDATA" -Severity "Info" -Message "LOCALAPPDATA is not available; browser extension check skipped."
        return $events
    }

    $chromePath = Join-Path $localAppData "Google\Chrome\User Data\Default\Extensions"
    $edgePath = Join-Path $localAppData "Microsoft\Edge\User Data\Default\Extensions"

    $events += Add-SDMonBrowserExtensionEvents -Browser "Chrome" -Path $chromePath
    $events += Add-SDMonBrowserExtensionEvents -Browser "Edge" -Path $edgePath

    return $events
}
