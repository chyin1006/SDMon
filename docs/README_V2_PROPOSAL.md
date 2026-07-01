# README V2 Proposal

This document is a proposal for a future SDMon GitHub homepage README. It does not replace the current `README.md`.

---

# SDMon

**Security Dynamic Monitor**

**Cross-platform Agent Behavior Analysis Framework**

SDMon helps security researchers, enterprise administrators, and incident responders observe how endpoint Agents behave at runtime. It collects read-only evidence about processes, files, network activity, startup mechanisms, permissions, and sensitive path access, then turns that evidence into timelines, findings, and reports.

Current implementation: **macOS first**.

Future platform direction: **Windows and Linux are planned, not yet supported**.

## Project Vision

Endpoint Agents are everywhere: MDM, EDR, VPN, Zero Trust, remote access, monitoring, and internal enterprise tools. They often run with elevated privileges, start automatically, communicate with remote services, and access local files that matter to users and organizations.

SDMon aims to provide a transparent, repeatable, and evidence-first framework for understanding Agent behavior without modifying the Agent under analysis.

The long-term vision is a cross-platform framework with a common analysis model and platform-specific sensors:

- macOS Sensors for macOS Agent behavior analysis.
- Windows Sensors for future Windows Agent behavior analysis.
- Linux Sensors for future Linux Agent behavior analysis.
- Profiles for defining target Agents.
- Rules for identifying behavior patterns and risk signals.
- Reporters for producing human-readable output in the right language.

## Why SDMon

SDMon is designed for practical Agent behavior analysis:

- **Read-only by design**: SDMon observes. It does not stop, unload, uninstall, delete, quarantine, patch, or modify target Agents.
- **Evidence first**: Reports should explain what was observed, where the evidence came from, and what was not observed during the collection window.
- **macOS ready today**: The current baseline focuses on macOS Agent monitoring.
- **Cross-platform model**: Process, file, network, persistence, privilege, sensitive-path, and reporting concepts can be reused across platforms.
- **Profile driven**: A Profile describes the target Agent so the framework does not need to be rewritten for every case.
- **Rule driven**: A Rule Engine highlights behavior categories instead of hard-coding one vendor or one product.
- **Report oriented**: SDMon turns raw logs into summaries, findings, timelines, and HTML reports.
- **Internationalized**: `LANG=auto` should produce Chinese reports on Chinese systems and English reports on non-Chinese systems.

## Features

Planned V2 feature set:

- macOS Agent behavior collection.
- Profile Engine for defining target Agents.
- Rule Engine for behavior and risk patterns.
- Plugin System for future sensors, analyzers, reporters, and platform extensions.
- Timeline generation.
- Findings generation.
- HTML Report output.
- Text report output.
- Internationalization with `LANG=auto`.
- Chinese report output on Chinese systems.
- English report output on non-Chinese systems.
- Read-only collection using native platform tools where possible.
- Clear separation between Sensors, Rules, Analyzers, and Reporters.

## Supported Platforms

| Platform | Status | Notes |
| --- | --- | --- |
| macOS | Ready | Current implementation target. V2 is macOS first. |
| Windows | Planned | Architecture extension point only. Not supported yet. |
| Linux | Planned | Architecture extension point only. Not supported yet. |

SDMon is positioned as a cross-platform framework, but Windows and Linux support should not be presented as implemented until real sensors and tests exist.

## Supported Agent Types

SDMon is intended to analyze many classes of endpoint Agents:

- MDM Agent
- EDR Agent
- VPN Client
- Zero Trust Agent
- Enterprise Security Agent
- Remote Access Agent
- Monitoring Agent
- Custom Agent

Support depends on available Profiles, Rules, and platform Sensors. V2 should stabilize macOS first, then grow through reusable profiles and plugins.

## Architecture

```text
+----------------+
|    Profile     |
| target Agent   |
+-------+--------+
        |
        v
+----------------+
| Profile Engine |
+-------+--------+
        |
        v
+----------------+       +----------------+
|    Sensors     | ----> |    Raw Logs    |
| macOS first    |       | run directory  |
+-------+--------+       +-------+--------+
        |                        |
        v                        v
+----------------+       +----------------+
|  Rule Engine   | ----> |   Analyzer     |
| behavior rules |       | timeline/finds |
+----------------+       +-------+--------+
                                 |
                                 v
                         +----------------+
                         |   Reporter     |
                         | txt/html/i18n  |
                         +----------------+
```

Core concepts:

- **Profile Engine**: loads target process names, paths, launch items, endpoints, sensitive paths, and report language preferences.
- **Sensors**: collect platform-specific raw evidence. V2 implements macOS Sensors first.
- **Raw Logs**: preserve source evidence for review and re-analysis.
- **Rule Engine**: applies behavior-oriented rules such as sensitive file access, persistence, privilege, network endpoint, and large upload indicators.
- **Analyzer**: produces timeline events, findings, and risk scoring without making unsupported malware verdicts.
- **Reporter**: renders `summary.txt`, `findings.txt`, `timeline.csv`, and `report.html`.
- **Plugin System**: future extension point for additional Sensors, Profiles, Rules, Analyzers, Reporters, and platforms.
- **Internationalization**: report text should be loaded from language templates with automatic language selection.

## Report Samples

### summary.txt

```text
SDMon Summary
Profile: Default macOS Agent Profile
Platform: macOS
Collection Window: 2026-06-29 10:00:00 - 2026-06-29 10:15:00

Observed:
- Target process was running.
- LaunchDaemon was present.
- Network connection to configured endpoint was observed.
- Sensitive path access was observed during the collection window.

Reports:
- findings.txt
- timeline.csv
- report.html
```

### findings.txt

```text
[Medium] Network Endpoint
Target process connected to configured endpoint 192.0.2.10:7777.
Evidence: network.log

[High] Sensitive File Access
Target process accessed a browser-related sensitive path.
Evidence: fs_usage.log

[Info] Persistence
LaunchDaemon entry was present during collection.
Evidence: launchd.log
```

### timeline.csv

```csv
timestamp,source,event_type,target,evidence,severity
2026-06-29T10:01:10Z,process,process_seen,demo-agent,process.log,info
2026-06-29T10:02:23Z,network,endpoint_connected,192.0.2.10:7777,network.log,medium
2026-06-29T10:03:44Z,file,sensitive_access,Chrome History,fs_usage.log,high
```

### report.html

`report.html` should provide a readable browser-based report with:

- Executive summary.
- Collection metadata.
- Timeline table.
- Findings grouped by severity.
- Evidence references.
- Limitations and missing data.
- Language selected through `LANG=auto`, `zh-CN`, or `en-US`.

## Quick Start

Current macOS baseline workflow:

```bash
git clone https://github.com/chyin1006/SDMon.git
cd SDMon
chmod +x Start_SDMon.command Stop_SDMon.command Analyse.command bin/*.sh
bash Start_SDMon.command
# Let SDMon collect evidence for several minutes.
bash Stop_SDMon.command
```

Output is written under:

```text
~/Downloads/2026-110/
```

A typical run directory contains:

```text
traffic.pcap
process.log
network.log
launchctl.log
fs_usage.log
summary.txt
findings.txt
```

Future V2 workflow proposal:

```bash
sdmon start --profile profiles/default.conf
sdmon stop
sdmon analyze --latest
sdmon report --lang auto
```

## Roadmap

| Version | Focus | Status |
| --- | --- | --- |
| V1.1 | macOS targeted monitor baseline | Ready |
| V2 | macOS framework architecture | Planned / In design |
| V3 | Windows support | Planned |
| V4 | Linux support | Planned |

V2 priorities:

- Stabilize macOS framework structure.
- Add Profile Engine.
- Add Rule Engine.
- Add macOS Sensors.
- Add Timeline output.
- Add HTML Report.
- Add Internationalization with `LANG=auto`.
- Prepare Plugin System extension points.

## Project Structure

Current V1.1 structure is intentionally simple. Proposed V2 structure:

```text
SDMon/
  core/
    common.sh
    config.sh
    state.sh
    profile_loader.sh
    rule_loader.sh

  sensors/
    macos/
      process.sh
      network.sh
      file.sh
      launchd.sh
      system.sh

  profiles/
    default.conf
    examples/
      custom.conf

  rules/
    sensitive_file_access.conf
    network_endpoint.conf
    persistence.conf
    privilege.conf
    large_upload.conf

  analyzers/
    timeline.sh
    findings.sh
    risk_score.sh

  reporters/
    summary_txt.sh
    findings_txt.sh
    timeline_csv.sh
    report_html.sh

  i18n/
    zh-CN/
      messages.conf
    en-US/
      messages.conf

  docs/
    SDMon_V2_ARCHITECTURE.md
    SDMon_V2_PRODUCT_DIRECTION.md
    SDMon_V2_FRAMEWORK_DESIGN.md
    README_V2_PROPOSAL.md

  tests/
    fixtures/
    run_syntax_checks.sh
    run_analyzer_tests.sh
```

Runtime output should not be committed.

## FAQ

### Is SDMon malware?

No. SDMon is a read-only behavior analysis framework. It is designed to help users understand Agent behavior through transparent evidence collection and reporting.

### Does SDMon bypass security software?

No. SDMon must not bypass, disable, evade, or tamper with security tools.

### Does SDMon uninstall or break Agents?

No. SDMon does not uninstall, stop, unload, delete, quarantine, patch, or damage target Agents.

### Does SDMon support Windows today?

No. Windows support is planned for a future version. V2 should only preserve architecture extension points for Windows.

### Does SDMon support Linux today?

No. Linux support is planned for a future version. V2 should only preserve architecture extension points for Linux.

### Why is V2 macOS first?

The current working baseline is macOS, and the collection methods for macOS, Windows, and Linux are very different. Focusing V2 on macOS keeps the framework runnable, testable, and maintainable.

### What does `LANG=auto` mean?

`LANG=auto` means SDMon should detect the system language. Chinese systems should receive Chinese reports. Non-Chinese systems should receive English reports. Users should also be able to force `zh-CN` or `en-US`.

### Does SDMon collect personal content?

SDMon should not collect unrelated personal content. It should collect only evidence needed for the selected Agent behavior analysis, such as metadata, process state, endpoint observations, and matched sensitive-path events.

## Contributing

Contributions should preserve SDMon's core principles:

- Keep monitoring read-only.
- Keep generated output out of Git.
- Prefer clear Bash and native platform tools for baseline workflows.
- Add tests or reproducible checks for new behavior.
- Keep Profiles, Rules, Sensors, Analyzers, and Reporters separate.
- Do not claim platform support until sensors and tests exist.
- Do not add bypass, stealth, destructive, or unrelated personal-data collection features.

Good first contribution areas:

- Documentation improvements.
- Profile examples.
- Rule examples.
- Analyzer test fixtures.
- Report template improvements.
- macOS Sensor hardening.
- Internationalization messages.

## License

License information should be added before public release.

Until a license is selected, users should treat the repository as source-available but not automatically open for reuse, redistribution, or commercial use.
