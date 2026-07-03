Set-StrictMode -Version 3.0

function Get-SDMonObjectValue {
    param(
        [AllowNull()][object]$SourceObject,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Default = ""
    )

    if ($null -eq $SourceObject) {
        return $Default
    }

    $property = $SourceObject.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $Default
    }

    return [string]$property.Value
}

function Get-SDMonExtensionManifest {
    param([Parameter(Mandatory = $true)][string]$ExtensionPath)

    $manifestFiles = @()
    $rootManifest = Join-Path $ExtensionPath "manifest.json"
    if (Test-Path -LiteralPath $rootManifest) {
        $manifestFiles += Get-Item -LiteralPath $rootManifest -ErrorAction SilentlyContinue
    }

    try {
        $versionDirs = Get-ChildItem -LiteralPath $ExtensionPath -Directory -ErrorAction Stop
        foreach ($versionDir in $versionDirs) {
            $manifestPath = Join-Path $versionDir.FullName "manifest.json"
            if (Test-Path -LiteralPath $manifestPath) {
                $manifestFiles += Get-Item -LiteralPath $manifestPath -ErrorAction SilentlyContinue
            }
        }
    } catch {
        return [PSCustomObject]@{
            manifest_read = $false
            manifest_path = ""
            name          = ""
            version       = ""
            error         = $_.Exception.Message
        }
    }

    $manifestFile = @($manifestFiles | Where-Object { $null -ne $_ } | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    if (-not $manifestFile) {
        return [PSCustomObject]@{
            manifest_read = $false
            manifest_path = ""
            name          = ""
            version       = ""
            error         = "manifest.json not found"
        }
    }

    try {
        $manifest = Get-Content -LiteralPath $manifestFile[0].FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        return [PSCustomObject]@{
            manifest_read = $true
            manifest_path = [string]$manifestFile[0].FullName
            name          = Get-SDMonObjectValue -SourceObject $manifest -Name "name" -Default ""
            version       = Get-SDMonObjectValue -SourceObject $manifest -Name "version" -Default ""
            error         = ""
        }
    } catch {
        return [PSCustomObject]@{
            manifest_read = $false
            manifest_path = [string]$manifestFile[0].FullName
            name          = ""
            version       = ""
            error         = $_.Exception.Message
        }
    }
}

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
            $manifest = Get-SDMonExtensionManifest -ExtensionPath $dir.FullName
            $extensionName = if ($manifest.name) { $manifest.name } else { "" }
            $target = if ($extensionName) { ("{0} ({1})" -f $extensionName, $dir.Name) } else { $dir.Name }
            $message = if ($extensionName) { "Browser extension found: $extensionName; review recommended." } else { "Browser extension ID found; review recommended." }

            $events += New-SDMonEvent -Category "browser" -Type "browser_extension" -Action "found" -Target $target -Severity "Info" -Message $message -Recommendation "Review installed browser extensions against the approved software list." -Details @{
                browser = $Browser
                extension_id = $dir.Name
                extension_name = $extensionName
                version = [string]$manifest.version
                manifest_path = [string]$manifest.manifest_path
                manifest_read = [bool]$manifest.manifest_read
                manifest_error = [string]$manifest.error
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
