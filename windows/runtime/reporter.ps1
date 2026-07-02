Set-StrictMode -Version 3.0

function ConvertTo-SDMonHtml {
    param([AllowNull()][object]$Value)
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-SDMonValue {
    param(
        [AllowNull()][object]$SourceObject,
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][object]$Default = "Unknown"
    )

    if ($null -eq $SourceObject) {
        return $Default
    }

    if ($SourceObject -is [System.Collections.IDictionary]) {
        if (-not $SourceObject.Contains($Name)) {
            return $Default
        }
        $value = $SourceObject[$Name]
    } else {
        $property = $SourceObject.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return $Default
        }
        $value = $property.Value
    }

    if ($null -eq $value) {
        return $Default
    }

    if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Get-SDMonArrayValue {
    param(
        [AllowNull()][object]$SourceObject,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $value = Get-SDMonValue -SourceObject $SourceObject -Name $Name -Default @()
    ConvertTo-SDMonArray -Value $value
}

function ConvertTo-SDMonArray {
    param([AllowNull()][object]$Value)

    if ($null -eq $value) {
        return
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string]) -and -not ($Value -is [System.Collections.IDictionary])) {
        foreach ($item in $Value) {
            if ($null -ne $item) {
                $item
            }
        }
        return
    }

    $Value
}

function Get-SDMonCount {
    param([AllowNull()][object]$Value)
    return @(ConvertTo-SDMonArray -Value $Value).Count
}

function New-SDMonHtmlRows {
    param(
        [AllowNull()][AllowEmptyCollection()][array]$Rows,
        [Parameter(Mandatory = $true)][string[]]$Columns
    )

    $safeRows = @(ConvertTo-SDMonArray -Value $Rows)
    $safeColumns = @(ConvertTo-SDMonArray -Value $Columns)

    if ((Get-SDMonCount -Value $safeRows) -eq 0) {
        return "<tr><td colspan=`"$(Get-SDMonCount -Value $safeColumns)`">No items found.</td></tr>"
    }

    $htmlRows = New-Object System.Collections.ArrayList
    foreach ($row in $safeRows) {
        $cells = foreach ($column in $safeColumns) {
            "<td>{0}</td>" -f (ConvertTo-SDMonHtml (Get-SDMonValue -SourceObject $row -Name $column -Default ""))
        }
        [void]$htmlRows.Add("<tr>{0}</tr>" -f ($cells -join ""))
    }
    return ($htmlRows -join "`n")
}

function New-SDMonMetricCards {
    param([System.Collections.IDictionary]$Metrics)

    $cards = New-Object System.Collections.ArrayList
    foreach ($key in $Metrics.Keys) {
        [void]$cards.Add("<div class=`"metric`"><div class=`"label`">$([System.Net.WebUtility]::HtmlEncode($key))</div><div class=`"value`">$([System.Net.WebUtility]::HtmlEncode([string]$Metrics[$key]))</div></div>")
    }
    return ($cards -join "`n")
}

function Invoke-SDMonReporter {
    param(
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [AllowNull()][AllowEmptyCollection()][array]$Events,
        [Parameter(Mandatory = $true)]$Analysis,
        [Parameter(Mandatory = $true)][string]$TemplatePath
    )

    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $eventsPath = Join-Path $OutputPath "events.json"
    $timelinePath = Join-Path $OutputPath "timeline.json"
    $reportJsonPath = Join-Path $OutputPath "report.json"
    $reportCsvPath = Join-Path $OutputPath "report.csv"
    $summaryPath = Join-Path $OutputPath "summary.txt"
    $reportHtmlPath = Join-Path $OutputPath "report.html"
    $zipPath = Join-Path $OutputPath "report.zip"

    $safeEvents = @(ConvertTo-SDMonArray -Value $Events)
    $analysisTimeline = @(Get-SDMonArrayValue -SourceObject $Analysis -Name "timeline")
    $topFindings = @(Get-SDMonArrayValue -SourceObject $Analysis -Name "top_findings")
    $permissionWarnings = @(Get-SDMonArrayValue -SourceObject $Analysis -Name "permission_warnings")
    $deductionsList = @(Get-SDMonArrayValue -SourceObject $Analysis -Name "deductions")
    $riskDistribution = Get-SDMonValue -SourceObject $Analysis -Name "risk_distribution" -Default @{}
    $device = Get-SDMonValue -SourceObject $Analysis -Name "device" -Default @{}

    Write-SDMonJsonFile -Data $safeEvents -Path $eventsPath

    $defaultTotalEvents = Get-SDMonCount -Value $safeEvents
    $defaultMatchedRules = Get-SDMonCount -Value $topFindings
    $defaultGeneratedAt = (Get-Date).ToUniversalTime().ToString("o")

    $securityScore = Get-SDMonValue -SourceObject $Analysis -Name "security_score" -Default 100
    $overallRisk = Get-SDMonValue -SourceObject $Analysis -Name "overall_risk" -Default "Low"
    $totalEvents = Get-SDMonValue -SourceObject $Analysis -Name "total_events" -Default $defaultTotalEvents
    $matchedRules = Get-SDMonValue -SourceObject $Analysis -Name "matched_rules" -Default $defaultMatchedRules
    $generatedAt = Get-SDMonValue -SourceObject $Analysis -Name "generated_at" -Default $defaultGeneratedAt

    Write-SDMonJsonFile -Data $analysisTimeline -Path $timelinePath
    Write-SDMonJsonFile -Data $Analysis -Path $reportJsonPath

    $csvRows = New-Object System.Collections.ArrayList
    [void]$csvRows.Add([PSCustomObject]@{
        type = "summary"
        title = "Security Score"
        severity = $overallRisk
        target = "Windows endpoint"
        recommendation = "Review findings and permission warnings."
        event_id = ""
    })
    foreach ($finding in $topFindings) {
        [void]$csvRows.Add([PSCustomObject]@{
            type = "finding"
            title = Get-SDMonValue -SourceObject $finding -Name "title" -Default ""
            severity = Get-SDMonValue -SourceObject $finding -Name "severity" -Default ""
            target = Get-SDMonValue -SourceObject $finding -Name "target" -Default ""
            recommendation = Get-SDMonValue -SourceObject $finding -Name "recommendation" -Default ""
            event_id = Get-SDMonValue -SourceObject $finding -Name "event_id" -Default ""
        })
    }
    $csvRows | Export-Csv -LiteralPath $reportCsvPath -NoTypeInformation -Encoding UTF8

    $findingLines = @($topFindings | ForEach-Object {
        "- {0} | {1} | {2}" -f (Get-SDMonValue -SourceObject $_ -Name "severity" -Default ""), (Get-SDMonValue -SourceObject $_ -Name "title" -Default ""), (Get-SDMonValue -SourceObject $_ -Name "target" -Default "")
    })
    if ((Get-SDMonCount -Value $findingLines) -eq 0) {
        $findingLines = @("No findings.")
    }

    $summary = @(
        "==============================",
        "SDMon Windows Endpoint Assessment",
        "==============================",
        "Security Score : $securityScore",
        "Overall Risk   : $overallRisk",
        "Total Events   : $totalEvents",
        "Matched Rules  : $matchedRules",
        "",
        "Output Files",
        "HTML    : $reportHtmlPath",
        "JSON    : $reportJsonPath",
        "CSV     : $reportCsvPath",
        "Summary : $summaryPath",
        "ZIP     : $zipPath",
        "",
        "Findings",
        ($findingLines -join "`n")
    ) -join "`n"
    Set-Content -LiteralPath $summaryPath -Value $summary -Encoding UTF8

    $windowsCaption = Get-SDMonValue -SourceObject $device -Name "windows_caption" -Default "Unknown"
    $windowsVersion = Get-SDMonValue -SourceObject $device -Name "windows_version" -Default "Unknown"
    $deviceMetrics = [ordered]@{
        "Hostname" = Get-SDMonValue -SourceObject $device -Name "hostname" -Default "Unknown"
        "Current User" = Get-SDMonValue -SourceObject $device -Name "current_user" -Default "Unknown"
        "Windows" = ("{0} {1}" -f $windowsCaption, $windowsVersion).Trim()
        "Architecture" = Get-SDMonValue -SourceObject $device -Name "os_architecture" -Default "Unknown"
        "PowerShell" = Get-SDMonValue -SourceObject $device -Name "powershell_version" -Default "Unknown"
        "Scan Time" = $generatedAt
        "Uptime" = Get-SDMonValue -SourceObject $device -Name "uptime" -Default "Unknown"
    }

    $summaryMetrics = [ordered]@{
        "Security Score" = $securityScore
        "Overall Risk" = $overallRisk
        "Total Events" = $totalEvents
        "Matched Rules" = $matchedRules
    }

    $riskMetrics = [ordered]@{
        "High" = Get-SDMonValue -SourceObject $riskDistribution -Name "High" -Default 0
        "Medium" = Get-SDMonValue -SourceObject $riskDistribution -Name "Medium" -Default 0
        "Low" = Get-SDMonValue -SourceObject $riskDistribution -Name "Low" -Default 0
        "Info" = Get-SDMonValue -SourceObject $riskDistribution -Name "Info" -Default 0
    }

    $findingRows = New-SDMonHtmlRows -Rows $topFindings -Columns @("severity", "title", "target", "recommendation")
    $permissionRows = New-SDMonHtmlRows -Rows $permissionWarnings -Columns @("event_time", "category", "target", "message")
    $timelineRows = New-SDMonHtmlRows -Rows $analysisTimeline -Columns @("time", "category", "action", "target", "severity", "message")
    $technicalRows = New-SDMonHtmlRows -Rows $safeEvents -Columns @("event_time", "category", "type", "action", "target", "severity", "message")

    $deductions = if ((Get-SDMonCount -Value $deductionsList) -gt 0) {
        "<ul>" + (($deductionsList | ForEach-Object { "<li>{0}</li>" -f (ConvertTo-SDMonHtml $_) }) -join "") + "</ul>"
    } else {
        "<p>No score deductions.</p>"
    }

    $template = Get-Content -LiteralPath $TemplatePath -Raw
    $html = $template.
        Replace("{{TITLE}}", "SDMon Windows Endpoint Assessment").
        Replace("{{GENERATED_AT}}", (ConvertTo-SDMonHtml $generatedAt)).
        Replace("{{DEVICE_CARDS}}", (New-SDMonMetricCards -Metrics $deviceMetrics)).
        Replace("{{SUMMARY_CARDS}}", (New-SDMonMetricCards -Metrics $summaryMetrics)).
        Replace("{{RISK_CARDS}}", (New-SDMonMetricCards -Metrics $riskMetrics)).
        Replace("{{SCORE_BREAKDOWN}}", $deductions).
        Replace("{{FINDING_ROWS}}", $findingRows).
        Replace("{{PERMISSION_ROWS}}", $permissionRows).
        Replace("{{TIMELINE_ROWS}}", $timelineRows).
        Replace("{{TECHNICAL_ROWS}}", $technicalRows)

    Set-Content -LiteralPath $reportHtmlPath -Value $html -Encoding UTF8

    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -LiteralPath @($reportHtmlPath, $reportJsonPath, $reportCsvPath, $summaryPath, $eventsPath, $timelinePath) -DestinationPath $zipPath -Force

    [PSCustomObject]@{
        report_html  = $reportHtmlPath
        report_json  = $reportJsonPath
        report_csv   = $reportCsvPath
        summary_txt  = $summaryPath
        report_zip   = $zipPath
        events_json  = $eventsPath
        timeline_json = $timelinePath
    }
}
