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
        [AllowNull()][AllowEmptyCollection()]$Data,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $isEmptyCollection = ($null -ne $Data -and $Data -is [System.Collections.ICollection] -and -not ($Data -is [string]) -and $Data.Count -eq 0)
    if ($isEmptyCollection) {
        Set-Content -LiteralPath $Path -Value "[]" -Encoding UTF8
        return
    }

    ConvertTo-Json -InputObject $Data -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}
