# SDMon

Enterprise Endpoint Security Assessment Toolkit

![SDMon report home](docs/images/report-home.png)

SDMon is a read-only Enterprise Endpoint Security Assessment Toolkit for macOS and Windows.

- One Command for macOS and Windows
- Read-only
- Local Analysis
- No cloud dependency
- HTML / PDF / JSON / CSV / ZIP reports
- Executive Summary
- Technical Details

> Platform Status
>
> macOS: Public Preview, available in `v2.0.0-rc1` and later.
>
> Windows: Beta Preview, available in `v2.1.0-beta.1` and later.
>
> Linux: Planned.
>
> Release note: GitHub may show `v2.0.0-rc1` as the Latest release because it is the current macOS Public Preview. Windows support is available in the `v2.1.0-beta.1` Pre-release and on `main`.
>
> Designed for evaluation. False positives are expected. SDMon is not a replacement for EDR, MDM, VPN, antivirus, or SOC platforms.

## What is SDMon?

SDMon is a local, read-only endpoint security assessment toolkit for enterprise IT and security teams.

It collects endpoint behavior and configuration signals, runs local rule matching, and generates an executive-friendly report package that can be reviewed, printed, archived, or shared internally.

SDMon does not block, remove, isolate, unload, modify, or remediate anything on the endpoint.

## Current Platform Status

| Platform | Status | Available In | Notes |
| --- | --- | --- | --- |
| macOS | Public Preview | `v2.0.0-rc1` and later | One-command local assessment and report generation. |
| Windows | Beta Preview | `v2.1.0-beta.1` and later | Tested on Windows 11 Pro and Windows 11 Home. Manual review and further QA / polish are still required. |
| Linux | Planned | Future release | Not implemented yet. |

Windows support is Beta. It is read-only and useful for evaluation, but it should not be treated as a finished stable release.

## Before You Start

SDMon currently supports macOS Public Preview and Windows Beta Preview from `main`.

If you use `git clone` on a fresh Mac, macOS may ask you to install Apple Command Line Tools first:

```bash
xcode-select --install
```

After installation, verify Git is available:

```bash
git --version
```

The one-command macOS runner below uses GitHub ZIP download mode by default and does not require Git.

## Quick Start

### macOS One-command Runner

Use this option for a fresh Mac when you want to avoid `git clone` and Apple Command Line Tools setup.

```bash
curl -fsSL https://raw.githubusercontent.com/chyin1006/SDMon/main/scripts/run-sdmon-macos.sh -o run-sdmon-macos.sh
chmod +x run-sdmon-macos.sh
./run-sdmon-macos.sh
```

The runner downloads the current SDMon ZIP archive, extracts it to a temporary directory, runs `sdmon-v2.sh`, opens `report.html` when possible, and prints generated report paths. If automatic opening fails, it prints the report path for manual review.

Optional Git mode:

```bash
./run-sdmon-macos.sh --git
```

Git mode requires Git. On a fresh Mac, install Apple Command Line Tools first with `xcode-select --install`.

### Windows One-command Runner

Run from Windows PowerShell:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chyin1006/SDMon/main/scripts/run-sdmon-windows.ps1" -OutFile ".\run-sdmon-windows.ps1"
powershell -ExecutionPolicy Bypass -File .\run-sdmon-windows.ps1
```

The Windows runner downloads the current SDMon ZIP archive, extracts it to a temporary directory, runs the read-only Windows scan, opens `report.html` when possible, and prints generated report paths.

Windows support is Beta quality. Review findings manually before using them for operational decisions.

### Manual macOS: Run With Git

```bash
git clone https://github.com/chyin1006/SDMon.git
cd SDMon
chmod +x sdmon-v2.sh
./sdmon-v2.sh
```

### Manual macOS: Run From GitHub ZIP

Use this option if Git is not installed yet.

1. Open the SDMon GitHub page.
2. Select **Code** -> **Download ZIP**.
3. Extract the ZIP file.
4. Open Terminal in the extracted folder.
5. Run:

```bash
chmod +x sdmon-v2.sh
./sdmon-v2.sh
```

SDMon runs locally, writes reports to `output/`, and opens `output/report.html` when possible. The macOS workflow may ask for administrator permission once when required. The Windows Beta workflow does not require Administrator for the basic scan.

Terminal screenshot coming soon.

## Report Preview

### Report Home

![Report Home](docs/images/report-home.png)

### Executive Summary

![Executive Summary](docs/images/report-pdf.png)

### Top Findings

![Top Findings](docs/images/report-findings.png)

### Timeline

![Timeline](docs/images/report-timeline.png)

## Demo Artifacts

- `examples/report/demo-report.html`
- `examples/report/demo-report.pdf`
- `examples/report/demo-report.zip`

## Features

| Feature | Description |
| --- | --- |
| One Command | macOS and Windows runners download, run, and open the local report. |
| Read-only | SDMon collects local signals without modifying agents, settings, files, or services. |
| Local Analysis | Events, rules, analysis, and reports are processed on the endpoint. |
| No Cloud Dependency | No upload is required for the current macOS or Windows workflows. |
| Enterprise Report | Generates HTML, PDF, JSON, CSV, ZIP, and `summary.txt`. |
| Executive Summary | Shows Security Score, Overall Risk, Top Findings, and Recommendations. |
| Technical Details | Keeps evidence, rule IDs, paths, and raw context behind expandable details. |

## Why SDMon?

| Capability | SDMon | EDR | MDM |
| --- | --- | --- | --- |
| Read-only assessment | Yes | Partial | Partial |
| Enterprise report | Yes | Partial | No |
| Offline analysis | Yes | No | No |
| Real-time protection | No | Yes | No |
| System configuration enforcement | No | Partial | Yes |
| One-command scan | Yes | No | No |

SDMon is not EDR, not MDM, and not antivirus. It is a lightweight assessment and reporting toolkit for understanding endpoint posture and agent behavior.

## Detection Coverage

| Module | macOS | Windows Beta |
| --- | --- | --- |
| System | Host, user, OS, CPU, memory, and scan context. | Host, user, OS, architecture, PowerShell, uptime, CPU, memory. |
| Security | Firewall, FileVault, Gatekeeper, SIP, XProtect, MRT, permissions. | Defender, Firewall profiles, BitLocker, UAC, elevation status. |
| Persistence / Startup | LaunchAgent, LaunchDaemon, login item signals. | Startup folders and Run registry entries, read-only. |
| Browser | Browser extension and application trust signals. | Chrome and Edge extension metadata where readable. |
| Credential Metadata | Credential-related file metadata without reading credential values. | Credential-related file metadata without reading credential values. |
| Process / Network | Local process and network exposure signals. | Process and network inventory signals. |
| Services / Tasks | macOS service-style persistence signals. | Services and scheduled tasks, read-only. |
| Rule Engine | Local rule matching over normalized events. | Local analysis and findings over collected events. |
| Reporter | HTML, PDF, ZIP, JSON, CSV, and Summary outputs. | HTML, ZIP, JSON, CSV, Summary, Events, and Timeline outputs. |

## Use Cases

- Enterprise IT endpoint review.
- Security team triage.
- Compliance evidence collection.
- Internal audit.
- Customer delivery reports.
- Endpoint management validation.
- Local agent behavior assessment.

## Supported Platforms

| Platform | Status | Notes |
| --- | --- | --- |
| macOS | Public Preview | Available in `v2.0.0-rc1` and later. |
| Windows | Beta Preview | Available in `v2.1.0-beta.1` and later. Tested on Windows 11 Pro and Windows 11 Home. |
| Linux | Planned | Not implemented yet. |

## Current Release

| Release | GitHub Label | Platform Scope | Status |
| --- | --- | --- | --- |
| `v2.0.0-rc1` | Latest | macOS | Public Preview |
| `v2.1.0-beta.1` | Pre-release | Windows | Beta Preview |

`v2.0.0-rc1` remains the Latest release for the macOS Public Preview. `v2.1.0-beta.1` adds Windows Beta support and is intentionally marked as a Pre-release.

Default output files:

```text
output/report.html
output/report.pdf
output/report.zip
output/report.json
output/report.csv
output/summary.txt
output/timeline.json
output/events.json
```

## Roadmap

```text
macOS Public Preview
  |
Windows Beta Preview
  |
Beta
  |-- Linux support
  |-- SQLite event store
  |-- Rule manager
  |-- IOC / MITRE mapping
  |-- Dashboard
  |
Stable
```

## Safety Notes

SDMon does not:

- Stop, uninstall, or modify target agents.
- Change system settings.
- Upload reports or events.
- Read credential values.
- Replace EDR, MDM, VPN, antivirus, or SOC platforms.
- Perform automatic remediation.

## Documentation

- `docs/RELEASE_NOTES_RC1.md`: RC1 release notes.
- `docs/RELEASE_NOTES_v2.1.0-beta.1.md`: Windows Beta pre-release notes.
- `docs/RC1_RELEASE_CHECKLIST.md`: RC1 release checklist.
- `windows/README.md`: Windows Beta usage and safety notes.
- `examples/README.md`: examples and first-rule walkthrough.
- `CHANGELOG.md`: project change history.
- `CONTRIBUTING.md`: contribution guide.
- `SECURITY.md`: security policy.
- `PROJECT_INDEX.md`: project knowledge entry point.

## License

SDMon is released under the MIT License. See `LICENSE`.
