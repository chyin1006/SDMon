Set-StrictMode -Version 3.0

function ConvertTo-SDMonHtml {
    param([AllowNull()][object]$Value)
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function New-SDMonHtmlRows {
    param(
        [AllowNull()][AllowEmptyCollection()][array]$Rows,
        [Parameter(Mandatory = $true)][string[]]$Columns
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return "<tr><td colspan=`"$($Columns.Count)`">No items found.</td></tr>"
    }

    $htmlRows = New-Object System.Collections.ArrayList
    foreach ($row in $Rows) {
        $cells = foreach ($column in $Columns) {
            "<td>{0}</td>" -f (ConvertTo-SDMonHtml $row.$column)
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

    Write-SDMonJsonFile -Data $Events -Path $eventsPath
    Write-SDMonJsonFile -Data $Analysis.timeline -Path $timelinePath
    Write-SDMonJsonFile -Data $Analysis -Path $reportJsonPath

    $csvRows = New-Object System.Collections.ArrayList
    [void]$csvRows.Add([PSCustomObject]@{
        type = "summary"
        title = "Security Score"
        severity = $Analysis.overall_risk
        target = "Windows endpoint"
        recommendation = "Review findings and permission warnings."
        event_id = ""
    })
    foreach ($finding in $Analysis.top_findings) {
        [void]$csvRows.Add([PSCustomObject]@{
            type = "finding"
            title = $finding.title
            severity = $finding.severity
            target = $finding.target
            recommendation = $finding.recommendation
            event_id = $finding.event_id
        })
    }
    $csvRows | Export-Csv -LiteralPath $reportCsvPath -NoTypeInformation -Encoding UTF8

    $findingLines = @($Analysis.top_findings | ForEach-Object { "- $($_.severity) | $($_.title) | $($_.target)" })
    if ($findingLines.Count -eq 0) {
        $findingLines = @("No findings.")
    }

    $summary = @(
        "==============================",
        "SDMon Windows Endpoint Assessment",
        "==============================",
        "Security Score : $($Analysis.security_score)",
        "Overall Risk   : $($Analysis.overall_risk)",
        "Total Events   : $($Analysis.total_events)",
        "Matched Rules  : $($Analysis.matched_rules)",
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

    $device = $Analysis.device
    $deviceMetrics = [ordered]@{
        "Hostname" = $device.hostname
        "Current User" = $device.current_user
        "Windows" = ("{0} {1}" -f $device.windows_caption, $device.windows_version)
        "Architecture" = $device.os_architecture
        "PowerShell" = $device.powershell_version
        "Uptime" = $device.uptime
    }

    $summaryMetrics = [ordered]@{
        "Security Score" = $Analysis.security_score
        "Overall Risk" = $Analysis.overall_risk
        "Total Events" = $Analysis.total_events
        "Matched Rules" = $Analysis.matched_rules
    }

    $riskMetrics = [ordered]@{
        "High" = $Analysis.risk_distribution.High
        "Medium" = $Analysis.risk_distribution.Medium
        "Low" = $Analysis.risk_distribution.Low
        "Info" = $Analysis.risk_distribution.Info
    }

    $findingRows = New-SDMonHtmlRows -Rows $Analysis.top_findings -Columns @("severity", "title", "target", "recommendation")
    $permissionRows = New-SDMonHtmlRows -Rows $Analysis.permission_warnings -Columns @("event_time", "category", "target", "message")
    $timelineRows = New-SDMonHtmlRows -Rows $Analysis.timeline -Columns @("time", "category", "action", "target", "severity", "message")
    $technicalRows = New-SDMonHtmlRows -Rows $Events -Columns @("event_time", "category", "type", "action", "target", "severity")

    $deductions = if ($Analysis.deductions.Count -gt 0) {
        "<ul>" + (($Analysis.deductions | ForEach-Object { "<li>{0}</li>" -f (ConvertTo-SDMonHtml $_) }) -join "") + "</ul>"
    } else {
        "<p>No score deductions.</p>"
    }

    $template = Get-Content -LiteralPath $TemplatePath -Raw
    $html = $template.
        Replace("{{TITLE}}", "SDMon Windows Endpoint Assessment").
        Replace("{{GENERATED_AT}}", (ConvertTo-SDMonHtml $Analysis.generated_at)).
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
