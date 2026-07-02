Set-StrictMode -Version 3.0

function Add-SDMonFinding {
    param(
        [System.Collections.ArrayList]$Findings,
        [Parameter(Mandatory = $true)]$Event
    )

    [void]$Findings.Add([PSCustomObject]@{
        title          = $Event.message
        severity       = $Event.severity
        category       = $Event.category
        target         = $Event.target
        recommendation = $Event.recommendation
        event_id       = $Event.event_id
        rule_id        = ("{0}_{1}" -f $Event.category, $Event.type)
        technical      = $Event.details
    })
}

function Get-SDMonRiskFromScore {
    param([int]$Score)

    if ($Score -ge 80) { return "Low" }
    if ($Score -ge 60) { return "Medium" }
    if ($Score -ge 40) { return "High" }
    return "Critical"
}

function Invoke-SDMonAnalyzer {
    param(
        [AllowNull()][AllowEmptyCollection()][array]$Events
    )

    $eventList = @($Events) | Where-Object { $null -ne $_ }
    $score = 100
    $deductions = New-Object System.Collections.ArrayList
    $findings = New-Object System.Collections.ArrayList
    $deductionApplied = @{}

    foreach ($event in $eventList) {
        if ($event.severity -in @("Medium", "Low")) {
            Add-SDMonFinding -Findings $findings -Event $event
        }

        if ($event.type -eq "firewall_status" -and $event.severity -eq "Medium" -and -not $deductionApplied.ContainsKey("firewall")) {
            $score -= 10
            [void]$deductions.Add("Firewall disabled or unavailable: -10")
            $deductionApplied["firewall"] = $true
        }

        if ($event.type -eq "defender_status" -and $event.severity -eq "Medium" -and -not $deductionApplied.ContainsKey("defender")) {
            $score -= 10
            [void]$deductions.Add("Defender disabled or unavailable: -10")
            $deductionApplied["defender"] = $true
        }

        if ($event.type -eq "bitlocker_status" -and $event.severity -eq "Low" -and -not $deductionApplied.ContainsKey("bitlocker")) {
            $score -= 5
            [void]$deductions.Add("BitLocker off or unavailable: -5")
            $deductionApplied["bitlocker"] = $true
        }

        if ($event.type -eq "uac_status" -and $event.severity -eq "Medium" -and -not $deductionApplied.ContainsKey("uac")) {
            $score -= 10
            [void]$deductions.Add("UAC disabled or unavailable: -10")
            $deductionApplied["uac"] = $true
        }

        if ($event.category -eq "startup" -and $event.action -eq "found" -and -not $deductionApplied.ContainsKey("startup")) {
            $score -= 2
            [void]$deductions.Add("Startup item review: -2")
            $deductionApplied["startup"] = $true
        }
    }

    if ($score -lt 0) {
        $score = 0
    }

    $deviceEvent = $eventList | Where-Object { $_.category -eq "system" -and $_.type -eq "system_summary" } | Select-Object -First 1
    $device = if ($deviceEvent) { $deviceEvent.details } else { @{} }

    $timeline = @($eventList | Sort-Object event_time | ForEach-Object {
        [PSCustomObject]@{
            time     = $_.event_time
            category = $_.category
            action   = $_.action
            target   = $_.target
            severity = $_.severity
            message  = $_.message
        }
    })

    $permissionWarnings = @($eventList | Where-Object {
        $_.action -eq "permission_denied" -or $_.type -eq "permission_warning"
    })

    $riskDistribution = [ordered]@{
        High   = @($eventList | Where-Object { $_.severity -eq "High" }).Count
        Medium = @($eventList | Where-Object { $_.severity -eq "Medium" }).Count
        Low    = @($eventList | Where-Object { $_.severity -eq "Low" }).Count
        Info   = @($eventList | Where-Object { $_.severity -eq "Info" }).Count
    }

    [PSCustomObject]@{
        title               = "SDMon Windows Endpoint Assessment"
        generated_at        = (Get-Date).ToUniversalTime().ToString("o")
        security_score      = [int]$score
        overall_risk        = (Get-SDMonRiskFromScore -Score $score)
        total_events        = @($eventList).Count
        matched_rules       = @($findings).Count
        risk_distribution   = $riskDistribution
        deductions          = @($deductions)
        device              = $device
        top_findings        = @($findings)
        permission_warnings = @($permissionWarnings)
        timeline            = @($timeline)
    }
}
