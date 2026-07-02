Set-StrictMode -Version 3.0

function New-SDMonEvent {
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Type,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Target,
        [string]$Severity = "Info",
        [string]$Message = "",
        [string]$Recommendation = "",
        [hashtable]$Details = @{}
    )

    [PSCustomObject]@{
        event_id       = [guid]::NewGuid().ToString()
        event_time     = (Get-Date).ToUniversalTime().ToString("o")
        platform       = "windows"
        category       = $Category
        type           = $Type
        action         = $Action
        target         = $Target
        severity       = $Severity
        message        = $Message
        recommendation = $Recommendation
        source         = "sdmon-windows"
        details        = $Details
    }
}

function Write-SDMonJsonFile {
    param(
        [Parameter(Mandatory = $true)]$Data,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Data | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}
