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
        $columnCount = Get-SDMonCount -Value $safeColumns
        return ('<tr><td colspan="' + $columnCount + '">No items found.</td></tr>')
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
        $encodedKey = [System.Net.WebUtility]::HtmlEncode([string]$key)
        $encodedValue = [System.Net.WebUtility]::HtmlEncode([string]$Metrics[$key])
        $cardHtml = '<div class="metric"><div class="label">' + $encodedKey + '</div><div class="value">' + $encodedValue + '</div></div>'
        [void]$cards.Add($cardHtml)
    }
    return ($cards -join "`n")
}

function Get-SDMonCollectorCategories {
    return @(
        "system",
        "security",
        "startup",
        "browser",
        "process",
        "network",
        "service",
        "scheduled_task",
        "credential_metadata",
        "event_log"
    )
}

function Get-SDMonCollectorSummary {
    param([AllowNull()][AllowEmptyCollection()][array]$Events)

    $safeEvents = @(ConvertTo-SDMonArray -Value $Events)
    $rows = New-Object System.Collections.ArrayList

    foreach ($category in Get-SDMonCollectorCategories) {
        $count = Get-SDMonCount -Value @($safeEvents | Where-Object {
            (Get-SDMonValue -SourceObject $_ -Name "category" -Default "") -eq $category
        })

        [void]$rows.Add([PSCustomObject]@{
            category = $category
            events   = $count
        })
    }

    return @($rows.ToArray())
}

function Get-SDMonTimelineDisplayRows {
    param([AllowNull()][AllowEmptyCollection()][array]$Timeline)

    $safeTimeline = @(ConvertTo-SDMonArray -Value $Timeline)
    $selected = New-Object System.Collections.ArrayList
    $infoCount = 0
    $maxInfo = 100

    foreach ($entry in $safeTimeline) {
        $severity = [string](Get-SDMonValue -SourceObject $entry -Name "severity" -Default "Info")
        if ($severity -in @("High", "Medium", "Low")) {
            [void]$selected.Add($entry)
            continue
        }

        if ($severity -eq "Info" -and $infoCount -lt $maxInfo) {
            [void]$selected.Add($entry)
            $infoCount += 1
        }
    }

    return @($selected.ToArray() | Sort-Object {
        Get-SDMonValue -SourceObject $_ -Name "time" -Default ""
    })
}

function Get-SDMonTechnicalDisplayRows {
    param([AllowNull()][AllowEmptyCollection()][array]$Events)

    $safeEvents = @(ConvertTo-SDMonArray -Value $Events)
    $rows = New-Object System.Collections.ArrayList
    $notes = New-Object System.Collections.ArrayList
    $cap = 50
    $cappedCategories = @(
        "process",
        "network",
        "service",
        "scheduled_task",
        "browser",
        "credential_metadata",
        "event_log"
    )

    foreach ($category in Get-SDMonCollectorCategories) {
        $categoryEvents = @($safeEvents | Where-Object {
            (Get-SDMonValue -SourceObject $_ -Name "category" -Default "") -eq $category
        })

        if ($cappedCategories -contains $category) {
            $displayEvents = @($categoryEvents | Select-Object -First $cap)
            if ((Get-SDMonCount -Value $categoryEvents) -gt $cap) {
                [void]$notes.Add(("Showing first {0} of {1} {2} events. Full data is available in events.json." -f $cap, (Get-SDMonCount -Value $categoryEvents), $category))
            }
        } else {
            $displayEvents = $categoryEvents
        }

        foreach ($event in $displayEvents) {
            [void]$rows.Add($event)
        }
    }

    [PSCustomObject]@{
        rows  = @($rows.ToArray())
        notes = @($notes.ToArray())
    }
}

function New-SDMonHtmlNotes {
    param([AllowNull()][AllowEmptyCollection()][array]$Notes)

    $safeNotes = @(ConvertTo-SDMonArray -Value $Notes)
    if ((Get-SDMonCount -Value $safeNotes) -eq 0) {
        return ""
    }

    $items = foreach ($note in $safeNotes) {
        "<li>{0}</li>" -f (ConvertTo-SDMonHtml $note)
    }

    $joinedItems = ($items -join "")
    return ('<ul class="notes">' + $joinedItems + '</ul>')
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
    $collectorSummary = Get-SDMonCollectorSummary -Events $safeEvents

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

    $collectorLines = @($collectorSummary | ForEach-Object {
        "- {0}: {1}" -f (Get-SDMonValue -SourceObject $_ -Name "category" -Default ""), (Get-SDMonValue -SourceObject $_ -Name "events" -Default 0)
    })

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
        "Collector Summary",
        ($collectorLines -join "`n"),
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
    $collectorRows = New-SDMonHtmlRows -Rows $collectorSummary -Columns @("category", "events")
    $permissionRows = New-SDMonHtmlRows -Rows $permissionWarnings -Columns @("event_time", "category", "target", "message")
    $displayTimeline = Get-SDMonTimelineDisplayRows -Timeline $analysisTimeline
    $timelineRows = New-SDMonHtmlRows -Rows $displayTimeline -Columns @("time", "category", "action", "target", "severity", "message")
    $timelineNote = "Showing {0} of {1} timeline entries. Full raw event data is available in events.json and timeline.json." -f (Get-SDMonCount -Value $displayTimeline), (Get-SDMonCount -Value $analysisTimeline)
    $technicalDisplay = Get-SDMonTechnicalDisplayRows -Events $safeEvents
    $technicalRows = New-SDMonHtmlRows -Rows $technicalDisplay.rows -Columns @("event_time", "category", "type", "action", "target", "severity", "message")
    $technicalNotes = New-SDMonHtmlNotes -Notes $technicalDisplay.notes

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
        Replace("{{COLLECTOR_ROWS}}", $collectorRows).
        Replace("{{PERMISSION_ROWS}}", $permissionRows).
        Replace("{{TIMELINE_NOTE}}", (ConvertTo-SDMonHtml $timelineNote)).
        Replace("{{TIMELINE_ROWS}}", $timelineRows).
        Replace("{{TECHNICAL_NOTES}}", $technicalNotes).
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
