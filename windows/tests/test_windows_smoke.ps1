Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$TestRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WindowsRoot = Split-Path -Parent $TestRoot
$RepoRoot = Split-Path -Parent $WindowsRoot
$ScriptPath = Join-Path $WindowsRoot "sdmon-windows.ps1"
$TemplatePath = Join-Path $WindowsRoot "templates\report.html"

$requiredFiles = @(
    $ScriptPath,
    (Join-Path $WindowsRoot "collectors\system_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\security_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\startup_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\browser_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\process_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\network_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\service_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\scheduled_task_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\credential_metadata_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\event_log_collector.ps1"),
    (Join-Path $WindowsRoot "runtime\event_writer.ps1"),
    (Join-Path $WindowsRoot "runtime\analyzer.ps1"),
    (Join-Path $WindowsRoot "runtime\reporter.ps1"),
    $TemplatePath
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Required file missing: $file"
    }
}

$outputPath = Join-Path ([System.IO.Path]::GetTempPath()) ("sdmon-windows-smoke-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

try {
    Push-Location $RepoRoot
    & $ScriptPath -Output $outputPath -NoOpen
} finally {
    Pop-Location
}

$expectedOutputs = @(
    "report.html",
    "report.json",
    "report.csv",
    "summary.txt",
    "report.zip",
    "events.json",
    "timeline.json"
)

foreach ($name in $expectedOutputs) {
    $path = Join-Path $outputPath $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Expected output missing: $path"
    }
}

Get-Content -LiteralPath (Join-Path $outputPath "report.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $outputPath "events.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $outputPath "timeline.json") -Raw | ConvertFrom-Json | Out-Null

$summaryText = Get-Content -LiteralPath (Join-Path $outputPath "summary.txt") -Raw
if ($summaryText -notmatch "Collector Summary") {
    throw "summary.txt did not contain Collector Summary."
}

$noFindingOutputPath = Join-Path ([System.IO.Path]::GetTempPath()) ("sdmon-windows-no-finding-" + [guid]::NewGuid().ToString())

. (Join-Path $WindowsRoot "runtime\event_writer.ps1")
. (Join-Path $WindowsRoot "runtime\analyzer.ps1")
. (Join-Path $WindowsRoot "runtime\reporter.ps1")
. (Join-Path $WindowsRoot "collectors\startup_collector.ps1")

$startupSamplePath = Join-Path ([System.IO.Path]::GetTempPath()) ("sdmon-startup-sample-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $startupSamplePath -Force | Out-Null
Set-Content -LiteralPath (Join-Path $startupSamplePath "desktop.ini") -Value "[.ShellClassInfo]" -Encoding ASCII
Set-Content -LiteralPath (Join-Path $startupSamplePath "approved-startup.lnk") -Value "sample shortcut placeholder" -Encoding ASCII

$startupSampleEvents = Add-SDMonStartupFolderEvents -Path $startupSamplePath -Scope "sample"
$desktopIniEvents = @($startupSampleEvents | Where-Object { $_.target -like "*desktop.ini*" })
if ($desktopIniEvents.Count -ne 0) {
    throw "desktop.ini should not be reported as a startup item."
}
$shortcutEvents = @($startupSampleEvents | Where-Object { $_.target -like "*approved-startup.lnk*" })
if ($shortcutEvents.Count -ne 1) {
    throw "Expected sample startup shortcut to be reported."
}

$noFindingAnalysis = Invoke-SDMonAnalyzer -Events @()
if ($noFindingAnalysis.security_score -ne 100) {
    throw "Expected no-finding security score 100, got $($noFindingAnalysis.security_score)"
}
if ($noFindingAnalysis.overall_risk -ne "Low") {
    throw "Expected no-finding overall risk Low, got $($noFindingAnalysis.overall_risk)"
}
if ($noFindingAnalysis.matched_rules -ne 0) {
    throw "Expected no-finding matched rules 0, got $($noFindingAnalysis.matched_rules)"
}

Invoke-SDMonReporter -OutputPath $noFindingOutputPath -Events @() -Analysis $noFindingAnalysis -TemplatePath $TemplatePath | Out-Null

foreach ($name in $expectedOutputs) {
    $path = Join-Path $noFindingOutputPath $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Expected no-finding output missing: $path"
    }
}

Get-Content -LiteralPath (Join-Path $noFindingOutputPath "report.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $noFindingOutputPath "events.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $noFindingOutputPath "timeline.json") -Raw | ConvertFrom-Json | Out-Null

$noFindingSummary = Get-Content -LiteralPath (Join-Path $noFindingOutputPath "summary.txt") -Raw
if ($noFindingSummary -notmatch "Security Score : 100") {
    throw "No-finding summary did not contain Security Score 100."
}
if ($noFindingSummary -notmatch "Overall Risk   : Low") {
    throw "No-finding summary did not contain Overall Risk Low."
}
if ($noFindingSummary -notmatch "Matched Rules  : 0") {
    throw "No-finding summary did not contain Matched Rules 0."
}
if ($noFindingSummary -notmatch "Collector Summary") {
    throw "No-finding summary did not contain Collector Summary."
}

$minimalOutputPath = Join-Path ([System.IO.Path]::GetTempPath()) ("sdmon-windows-minimal-" + [guid]::NewGuid().ToString())
$minimalAnalysis = [PSCustomObject]@{
    security_score = 100
    overall_risk   = "Low"
    matched_rules  = 0
}

Invoke-SDMonReporter -OutputPath $minimalOutputPath -Events $null -Analysis $minimalAnalysis -TemplatePath $TemplatePath | Out-Null

foreach ($name in $expectedOutputs) {
    $path = Join-Path $minimalOutputPath $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Expected minimal-analysis output missing: $path"
    }
}

$minimalHtml = Get-Content -LiteralPath (Join-Path $minimalOutputPath "report.html") -Raw
if ($minimalHtml -notmatch "Unknown") {
    throw "Minimal-analysis report did not render safe default values."
}

Write-Host "PASS"
Write-Host ("Output: {0}" -f $outputPath)
