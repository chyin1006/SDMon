# SDMon Beta 01 Windows Endpoint Assessment Plan

## 1. Goal

SDMon Beta 01 introduces the planning foundation for Windows endpoint assessment while preserving the existing macOS RC1 behavior.

The goal is to design a Windows-native, read-only assessment workflow that can collect local endpoint signals and generate SDMon-style reports:

- `report.html`
- `report.json`
- `report.csv`
- `summary.txt`
- `report.zip`

Beta 01 should make Windows support testable without turning SDMon into an agent, background service, EDR, MDM, or remediation tool.

## 2. Scope

Beta 01 scope:

- Windows endpoint assessment planning.
- PowerShell-native implementation direction.
- Read-only collection model.
- Basic scan that does not require administrator permission.
- Clear detection and explanation when advanced checks require administrator permission.
- Output structure aligned with SDMon V2 report conventions.
- Windows testing workflow that can be executed on a real Windows machine.

## 3. Out of Scope

Beta 01 does not include:

- Windows code implementation in this planning step.
- Changes to macOS RC1 behavior.
- Remediation actions.
- Background services.
- Registry modification.
- Service stop, start, restart, unload, or removal.
- File deletion or quarantine.
- Kernel drivers.
- Real-time protection.
- Centralized dashboard.
- New GitHub release or tag.

## 4. Windows Modules

Recommended Windows assessment modules:

| Module | Purpose | Admin Required |
| --- | --- | --- |
| System | Collect hostname, username, OS version, architecture, uptime, and hardware summary. | No |
| Process | List running processes, executable paths when readable, parent process IDs, and command line where available. | Partial |
| Network | Collect active TCP/UDP connections and listening ports using native PowerShell or Windows tools. | Partial |
| Services | Enumerate Windows services and startup configuration in read-only mode. | No |
| Scheduled Tasks | Enumerate scheduled tasks and suspicious startup patterns in read-only mode. | Partial |
| Startup Items | Review Startup folders and Run/RunOnce registry locations without changing them. | Partial |
| Security Baseline | Check Windows Defender, Firewall, BitLocker, UAC, and basic audit policy status. | Partial |
| Credentials Metadata | Detect presence and permissions of common credential/configuration files without reading secret values. | No |
| Browser | Review installed browser extensions and application trust metadata where accessible. | Partial |
| Event Logs | Optional read-only review of selected Windows Event Log channels. | Partial |

## 5. File Structure

Recommended Beta 01 file layout:

```text
windows/
  README.md
  sdmon-windows.ps1
  collectors/
    system_collector.ps1
    process_collector.ps1
    network_collector.ps1
    service_collector.ps1
    scheduled_task_collector.ps1
    startup_collector.ps1
    security_collector.ps1
    credential_collector.ps1
    browser_collector.ps1
  runtime/
    event_writer.ps1
    rule_runtime.ps1
    analyzer.ps1
    reporter.ps1
  templates/
    report.html
  tests/
    test_windows_smoke.ps1
docs/
  SDMon_BETA01_WINDOWS_PLAN.md
```

The Windows tree should stay separate from macOS files so RC1 behavior remains stable.

## 6. PowerShell CLI Command

Recommended command:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1
```

Recommended optional parameters:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Output .\output
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -NoOpen
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Advanced
```

Default behavior should run a basic read-only scan and write reports under `output\`.

## 7. Permission Model

Principles:

- Basic scan should not require administrator permission.
- Advanced checks may require administrator permission.
- SDMon must detect whether it is running elevated.
- If a check requires administrator permission, SDMon should explain the requirement and continue where possible.
- SDMon must not silently elevate.
- SDMon must not modify registry values, services, firewall rules, files, or system settings.
- Permission failures should be recorded as `permission_denied`, `not_available`, or `requires_admin` findings, not fatal errors.

Recommended user message:

```text
Some advanced Windows checks require administrator permission.
The current scan will continue in read-only basic mode.
Run PowerShell as Administrator and use -Advanced to include those checks.
```

## 8. Output Files

Windows output should match SDMon report style:

```text
output\
  report.html
  report.json
  report.csv
  summary.txt
  report.zip
  events.json
  timeline.json
```

Report content should include:

- Device summary.
- Security score.
- Overall risk.
- Collection statistics.
- Top findings.
- Recommendations.
- Timeline.
- Technical details.
- Permission warnings.

## 9. Testing Method on Windows

Windows testing should be done on a real Windows machine, not in macOS Codex.

Recommended test steps:

1. Pull or copy the Beta branch to the Windows machine.
2. Open PowerShell.
3. Run the basic scan:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Output .\output
   ```

4. Confirm these files exist:

   ```text
   output\report.html
   output\report.json
   output\report.csv
   output\summary.txt
   output\report.zip
   ```

5. Run optional advanced scan from elevated PowerShell only when explicitly testing admin-gated checks:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Advanced -Output .\output-advanced
   ```

6. Report terminal output, generated file list, and any permission warnings back to macOS Codex.

## 10. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Windows permissions differ widely by environment. | Some checks may fail or return partial data. | Record `requires_admin`, `permission_denied`, or `unknown` without failing the scan. |
| PowerShell execution policy may block scripts. | User may not be able to run the CLI. | Document `-ExecutionPolicy Bypass` for local one-time execution. |
| Event Log and security data may require admin. | Basic scan may miss deeper signals. | Keep basic scan useful and clearly label advanced checks. |
| False positives in enterprise environments. | Users may overinterpret findings. | Present findings as review items, not malicious verdicts. |
| Divergence from macOS report style. | Product feels inconsistent. | Reuse SDMon report structure and field names. |
| Accidental remediation behavior. | Violates project safety model. | Prohibit writes, service control, registry changes, and deletion. |

## 11. Implementation Phases

Phase 1: Planning

- Create Windows Beta 01 plan.
- Define module boundaries.
- Define output contract.
- Define Windows testing workflow.

Phase 2: Skeleton

- Add `windows/` directory.
- Add PowerShell CLI skeleton.
- Add basic output directory creation.
- Add placeholder report generation using synthetic local values.

Phase 3: Basic Collectors

- Implement system, process, network, services, scheduled tasks, and startup collectors.
- Keep all collectors read-only.
- Ensure basic scan runs without administrator permission.

Phase 4: Report Pipeline

- Generate `report.html`, `report.json`, `report.csv`, `summary.txt`, and `report.zip`.
- Align report structure with SDMon V2 style.

Phase 5: Advanced Checks

- Add admin-aware checks for deeper security posture.
- Detect elevation.
- Explain skipped checks clearly.

Phase 6: Windows Real Testing

- Run on a Windows machine.
- Collect terminal output and generated artifacts.
- Report failures back to macOS Codex for code changes.

## 12. How Windows Testing Results Should Be Reported Back

Windows test results should be copied back as plain text, not edited in Windows Codex.

Recommended report format:

```text
Branch:
Windows version:
PowerShell version:
Command run:
Was PowerShell elevated: Yes/No
Exit code:

Terminal output:
<paste full output>

Generated files:
<paste dir output>

Permission warnings:
<paste warnings>

Report observations:
<short notes>

Errors:
<paste exact errors>
```

Rules for feedback:

- Do not edit code on Windows.
- Do not commit from Windows.
- Do not push from Windows.
- Send exact terminal output and file lists back to macOS Codex.
- macOS Codex remains the only place for code changes.
