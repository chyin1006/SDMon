[CmdletBinding()]
param(
    [switch]$Help
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RepoZipUrl = "https://github.com/chyin1006/SDMon/archive/refs/heads/main.zip"

function Write-SDMonRunnerInfo {
    param([string]$Message)
    Write-Host $Message
}

function Stop-SDMonRunner {
    param([string]$Message)
    Write-Host ("ERROR: {0}" -f $Message) -ForegroundColor Red
    exit 1
}

function Show-SDMonRunnerUsage {
    Write-Host "SDMon Windows Beta one-command runner"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\run-sdmon-windows.ps1"
    Write-Host ""
    Write-Host "The runner downloads the SDMon main branch ZIP, extracts it to a temporary"
    Write-Host "directory, runs the read-only Windows scan, and leaves the workspace in place."
}

if ($Help) {
    Show-SDMonRunnerUsage
    exit 0
}

if (-not (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue)) {
    Stop-SDMonRunner "Invoke-WebRequest is required. Please run this script in Windows PowerShell 5.1 or later."
}

if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
    Stop-SDMonRunner "Expand-Archive is required. Please run this script in Windows PowerShell 5.1 or later."
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # Older hosts may not allow changing the security protocol. Continue and let the download report any error.
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempBase = [System.IO.Path]::GetTempPath()
$runRoot = Join-Path $tempBase ("sdmon-windows-run-{0}" -f $timestamp)
$zipPath = Join-Path $runRoot "sdmon-main.zip"

Write-SDMonRunnerInfo "==================================="
Write-SDMonRunnerInfo "SDMon Windows Beta Runner"
Write-SDMonRunnerInfo "==================================="
Write-SDMonRunnerInfo "Read-only local assessment. No upload, remediation, or system setting changes."
Write-SDMonRunnerInfo ""

Write-SDMonRunnerInfo "[1/6] Creating temporary workspace..."
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
Write-SDMonRunnerInfo ("Workspace: {0}" -f $runRoot)

Write-SDMonRunnerInfo "[2/6] Downloading SDMon ZIP..."
try {
    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Stop-SDMonRunner ("Failed to download SDMon ZIP. {0}" -f $_.Exception.Message)
}

Write-SDMonRunnerInfo "[3/6] Extracting SDMon..."
try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $runRoot -Force
} catch {
    Stop-SDMonRunner ("Failed to extract SDMon ZIP. {0}" -f $_.Exception.Message)
}

Write-SDMonRunnerInfo "[4/6] Locating Windows scan entrypoint..."
$repoRoot = Join-Path $runRoot "SDMon-main"
$scanScriptPath = Join-Path $repoRoot "windows\sdmon-windows.ps1"

if (-not (Test-Path -LiteralPath $scanScriptPath)) {
    Stop-SDMonRunner "Could not locate windows\sdmon-windows.ps1 in SDMon-main."
}

Write-SDMonRunnerInfo ("SDMon path: {0}" -f $repoRoot)

Write-SDMonRunnerInfo "[5/6] Running SDMon Windows scan..."
$powershellCommand = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($null -eq $powershellCommand) {
    $powershellCommand = Get-Command powershell -ErrorAction SilentlyContinue
}
if ($null -eq $powershellCommand) {
    Stop-SDMonRunner "Could not find powershell.exe."
}

$scanExitCode = 0
Push-Location $repoRoot
try {
    & $powershellCommand.Source -ExecutionPolicy Bypass -File ".\windows\sdmon-windows.ps1" -Output ".\output"
    $scanExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

if ($scanExitCode -ne 0) {
    Write-SDMonRunnerInfo ""
    Write-SDMonRunnerInfo "If PowerShell execution policy blocked the scan, rerun the runner with:"
    Write-SDMonRunnerInfo "powershell -ExecutionPolicy Bypass -File .\run-sdmon-windows.ps1"
    exit $scanExitCode
}

Write-SDMonRunnerInfo "[6/6] Listing generated outputs..."
$outputDir = Join-Path $repoRoot "output"
$reportHtml = Join-Path $outputDir "report.html"

Write-SDMonRunnerInfo ""
Write-SDMonRunnerInfo "==================================="
Write-SDMonRunnerInfo "SDMon Windows runner completed."
Write-SDMonRunnerInfo "==================================="
Write-SDMonRunnerInfo "Temporary SDMon copy:"
Write-SDMonRunnerInfo $repoRoot
Write-SDMonRunnerInfo ""
Write-SDMonRunnerInfo "Generated outputs:"

$outputFiles = @(
    "report.html",
    "report.json",
    "report.csv",
    "summary.txt",
    "report.zip",
    "events.json",
    "timeline.json"
)

if (Test-Path -LiteralPath $outputDir) {
    foreach ($outputFile in $outputFiles) {
        $path = Join-Path $outputDir $outputFile
        if (Test-Path -LiteralPath $path) {
            Write-SDMonRunnerInfo ("  {0}" -f $path)
        }
    }
} else {
    Write-SDMonRunnerInfo "  No output directory found."
}

Write-SDMonRunnerInfo ""
if (Test-Path -LiteralPath $reportHtml) {
    Write-SDMonRunnerInfo "Report:"
    Write-SDMonRunnerInfo $reportHtml
} else {
    Write-SDMonRunnerInfo "WARNING: report.html was not found."
    if (Test-Path -LiteralPath $outputDir) {
        Write-SDMonRunnerInfo "Available output files:"
        Get-ChildItem -LiteralPath $outputDir -File | Sort-Object Name | ForEach-Object {
            Write-SDMonRunnerInfo ("  {0}" -f $_.FullName)
        }
    }
}

Write-SDMonRunnerInfo ""
Write-SDMonRunnerInfo "The temporary workspace is left in place for review."
