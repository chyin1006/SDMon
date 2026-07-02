[CmdletBinding()]
param(
    [string]$Output = ".\output",
    [switch]$NoOpen
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RuntimeRoot = Join-Path $ScriptRoot "runtime"
$CollectorRoot = Join-Path $ScriptRoot "collectors"
$TemplatePath = Join-Path $ScriptRoot "templates\report.html"

. (Join-Path $RuntimeRoot "event_writer.ps1")
. (Join-Path $RuntimeRoot "analyzer.ps1")
. (Join-Path $RuntimeRoot "reporter.ps1")
. (Join-Path $CollectorRoot "system_collector.ps1")
. (Join-Path $CollectorRoot "security_collector.ps1")
. (Join-Path $CollectorRoot "startup_collector.ps1")
. (Join-Path $CollectorRoot "browser_collector.ps1")

function Resolve-SDMonOutputPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return (Join-Path (Get-Location).Path $Path)
}

function Invoke-SDMonCollectorSafely {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Collector
    )

    try {
        return @(& $Collector)
    } catch {
        return @(
            New-SDMonEvent -Category "collector" -Type "collector_error" -Action "failed" -Target $Name -Severity "Info" -Message "Collector failed and scan continued." -Details @{
                collector = $Name
                error = $_.Exception.Message
            }
        )
    }
}

$OutputPath = Resolve-SDMonOutputPath -Path $Output
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

Write-Host "==================================="
Write-Host "SDMon Windows Endpoint Assessment"
Write-Host "==================================="
Write-Host "Read-only basic scan. No remediation will be performed."
Write-Host ""

$events = @()

Write-Host "[1/5] System"
$events += Invoke-SDMonCollectorSafely -Name "System" -Collector { Invoke-SDMonSystemCollector }

Write-Host "[2/5] Security"
$events += Invoke-SDMonCollectorSafely -Name "Security" -Collector { Invoke-SDMonSecurityCollector }

Write-Host "[3/5] Startup"
$events += Invoke-SDMonCollectorSafely -Name "Startup" -Collector { Invoke-SDMonStartupCollector }

Write-Host "[4/5] Browser"
$events += Invoke-SDMonCollectorSafely -Name "Browser" -Collector { Invoke-SDMonBrowserCollector }

Write-Host "[5/5] Report"
$analysis = Invoke-SDMonAnalyzer -Events $events
$outputs = Invoke-SDMonReporter -OutputPath $OutputPath -Events $events -Analysis $analysis -TemplatePath $TemplatePath

Write-Host ""
Write-Host "==================================="
Write-Host "Summary"
Write-Host "==================================="
Write-Host ("Security Score : {0}" -f $analysis.security_score)
Write-Host ("Overall Risk   : {0}" -f $analysis.overall_risk)
Write-Host ("Events         : {0}" -f $analysis.total_events)
Write-Host ("Matched Rules  : {0}" -f $analysis.matched_rules)
Write-Host ""
Write-Host "Output paths"
Write-Host ("HTML     : {0}" -f $outputs.report_html)
Write-Host ("JSON     : {0}" -f $outputs.report_json)
Write-Host ("CSV      : {0}" -f $outputs.report_csv)
Write-Host ("Summary  : {0}" -f $outputs.summary_txt)
Write-Host ("ZIP      : {0}" -f $outputs.report_zip)
Write-Host ("Events   : {0}" -f $outputs.events_json)
Write-Host ("Timeline : {0}" -f $outputs.timeline_json)

if (-not $NoOpen) {
    if (Test-Path -LiteralPath $outputs.report_html) {
        Start-Process -FilePath $outputs.report_html
    }
}

Write-Host "Done."
