Set-StrictMode -Version 3.0

function Get-SDMonCredentialMetadataTarget {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Path
    )

    [PSCustomObject]@{
        label = $Label
        path  = $Path
    }
}

function Get-SDMonCredentialTargets {
    $homePath = [Environment]::GetFolderPath("UserProfile")
    $targets = @()

    if (-not [string]::IsNullOrWhiteSpace($homePath)) {
        $targets += Get-SDMonCredentialMetadataTarget -Label "SSH directory" -Path (Join-Path $homePath ".ssh")
        $targets += Get-SDMonCredentialMetadataTarget -Label "AWS directory" -Path (Join-Path $homePath ".aws")
        $targets += Get-SDMonCredentialMetadataTarget -Label "Azure directory" -Path (Join-Path $homePath ".azure")
        $targets += Get-SDMonCredentialMetadataTarget -Label "Git credentials" -Path (Join-Path $homePath ".git-credentials")
        $targets += Get-SDMonCredentialMetadataTarget -Label "Docker config" -Path (Join-Path $homePath ".docker\config.json")
        $targets += Get-SDMonCredentialMetadataTarget -Label "Kube config" -Path (Join-Path $homePath ".kube\config")
        $targets += Get-SDMonCredentialMetadataTarget -Label "NPM config" -Path (Join-Path $homePath ".npmrc")
        $targets += Get-SDMonCredentialMetadataTarget -Label "Netrc config" -Path (Join-Path $homePath ".netrc")
    }

    try {
        if (Get-Command Get-PSReadLineOption -ErrorAction SilentlyContinue) {
            $historyPath = [string](Get-PSReadLineOption).HistorySavePath
            if (-not [string]::IsNullOrWhiteSpace($historyPath)) {
                $targets += Get-SDMonCredentialMetadataTarget -Label "PowerShell history" -Path $historyPath
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
            $targets += Get-SDMonCredentialMetadataTarget -Label "PowerShell history" -Path (Join-Path $env:APPDATA "Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt")
        }
    } catch {
        if (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
            $targets += Get-SDMonCredentialMetadataTarget -Label "PowerShell history" -Path (Join-Path $env:APPDATA "Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt")
        }
    }

    return $targets
}

function Invoke-SDMonCredentialMetadataCollector {
    $events = @()

    foreach ($target in Get-SDMonCredentialTargets) {
        $label = [string]$target.label
        $path = [string]$target.path

        try {
            if (-not (Test-Path -LiteralPath $path)) {
                $events += New-SDMonEvent -Category "credential_metadata" -Type "credential_path" -Action "not_found" -Target $label -Severity "Info" -Message "Credential-related path was not found." -Details @{ label = $label; path = $path; exists = $false }
                continue
            }

            $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
            $aclReadable = $false
            $owner = ""
            try {
                $acl = Get-Acl -LiteralPath $path -ErrorAction Stop
                $aclReadable = $true
                $owner = [string]$acl.Owner
            } catch {
                $aclReadable = $false
            }

            $itemType = if ($item.PSIsContainer) { "directory" } else { "file" }
            $sizeBytes = if ($item.PSIsContainer) { 0 } else { [int64]$item.Length }

            $events += New-SDMonEvent -Category "credential_metadata" -Type "credential_path" -Action "found" -Target $label -Severity "Info" -Message "Credential-related metadata found; review recommended." -Recommendation "Confirm credential file permissions and storage location meet enterprise policy." -Details @{
                label         = $label
                path          = $path
                exists        = $true
                item_type     = $itemType
                size_bytes    = $sizeBytes
                last_modified = $item.LastWriteTimeUtc.ToString("o")
                attributes    = [string]$item.Attributes
                acl_readable  = $aclReadable
                owner         = $owner
            }
        } catch {
            $events += New-SDMonEvent -Category "credential_metadata" -Type "permission_warning" -Action "permission_denied" -Target $label -Severity "Info" -Message "Credential-related metadata could not be read." -Details @{ label = $label; path = $path; error = $_.Exception.Message }
        }
    }

    return $events
}
