Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$TestRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WindowsRoot = Split-Path -Parent $TestRoot
$RepoRoot = Split-Path -Parent $WindowsRoot
$ScriptPath = Join-Path $WindowsRoot "sdmon-windows.ps1"

$requiredFiles = @(
    $ScriptPath,
    (Join-Path $WindowsRoot "collectors\system_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\security_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\startup_collector.ps1"),
    (Join-Path $WindowsRoot "collectors\browser_collector.ps1"),
    (Join-Path $WindowsRoot "runtime\event_writer.ps1"),
    (Join-Path $WindowsRoot "runtime\analyzer.ps1"),
    (Join-Path $WindowsRoot "runtime\reporter.ps1"),
    (Join-Path $WindowsRoot "templates\report.html")
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

Write-Host "PASS"
Write-Host ("Output: {0}" -f $outputPath)
