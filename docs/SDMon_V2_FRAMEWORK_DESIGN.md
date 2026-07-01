# SDMon V2 Framework Design

## 1. V2 Design Principles

SDMon V2 may be positioned as a Cross-platform Agent Behavior Analysis Framework, but the V2 implementation should be macOS first.

Design principles:

- Product positioning can be cross-platform.
- V2 implementation only delivers the macOS framework.
- Windows and Linux remain architecture extension points only in V2.
- Windows and Linux collectors, sensors, and platform integrations should not be implemented in V2.
- Avoid over-engineering.
- Prioritize a V2 that is runnable, testable, and maintainable.
- Preserve the read-only monitoring principle from V1.1.
- Keep generated output out of the repository.

V2 should prove the framework shape on macOS before expanding to other systems. The framework should be modular enough for later platforms, but each module should solve a real V2 need.

## 2. Recommended Directory Structure

Recommended V2 repository structure:

```text
core/
  common.sh
  config.sh
  state.sh
  profile_loader.sh
  rule_loader.sh
  run_context.sh

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

tests/
  fixtures/
  run_syntax_checks.sh
  run_analyzer_tests.sh

output/
  .gitkeep
```

Notes:

- `output/` is only a placeholder for local development and must not contain committed runtime output.
- Real runtime output should continue to be written outside the repository, such as under `~/Downloads/2026-110`.
- V1.1 files can remain in place while V2 directories are introduced incrementally.

## 3. Data Flow

V2 data flow:

```text
Profile -> Sensors -> Raw Logs -> Rules -> Analyzer -> Reporter
```

Flow responsibilities:

1. Profile defines the target Agent and runtime preferences.
2. Sensors collect raw macOS evidence in a read-only way.
3. Raw Logs are stored in the run directory without interpretation.
4. Rules describe behavior patterns and risk categories.
5. Analyzer reads raw logs and rules to produce timeline, findings, and risk score.
6. Reporter renders user-facing outputs in the selected language.

The data flow should keep collection and reporting separate. Sensors should not decide final risk. Reporters should not collect evidence. Analyzers should explain behavior and risk signals without making unsupported claims.

## 4. Sensor Mechanism

V2 only implements macOS Sensors.

Required macOS sensors:

- process sensor
- network sensor
- file sensor
- launchd sensor
- system sensor

Each sensor must be able to run through a common interface:

```text
start
stop
analyze
```

Sensor requirements:

- Each sensor can be started independently.
- Each sensor can be stopped independently.
- Each sensor can analyze or pre-process its own raw log format when needed.
- Each sensor writes raw logs to the active run directory.
- Each sensor records status and errors clearly.
- Each sensor must be read-only.
- Each sensor must not stop, unload, delete, quarantine, patch, or modify target software.

Recommended sensor responsibilities:

### Process Sensor

Collects process snapshots for target process names, executable paths, users, PIDs, parent PIDs, and command lines.

Possible macOS tools:

- `ps`
- `pgrep`

### Network Sensor

Collects network connections related to target processes or target endpoints.

Possible macOS tools:

- `sudo lsof -nP -iTCP -iUDP`
- `tcpdump` for scoped packet capture when configured

### File Sensor

Collects target file inventory and file access observations.

Possible macOS tools:

- `test -e`
- `ls`
- `stat`
- `sudo fs_usage` filtered to target processes

### Launchd Sensor

Collects LaunchDaemon and LaunchAgent state.

Possible macOS tools:

- `launchctl print`
- `launchctl list`

### System Sensor

Collects minimal system context needed to interpret the report.

Possible macOS tools:

- `sw_vers`
- `uname`
- `hostname`
- `id`
- `locale`

System context must avoid collecting unrelated personal content.

## 5. Profile Mechanism

A profile describes one target Agent.

A V2 profile should include:

- Process names
- Executable paths
- LaunchDaemon or LaunchAgent labels
- Network endpoints
- Sensitive paths relevant to the target analysis
- Report language preference

V2 should support at least:

- default profile
- custom profile

Example profile fields:

```bash
PROFILE_ID="default"
PROFILE_NAME="Default macOS Agent profile"
REPORT_LANG="auto"

TARGET_PROCESSES="demo-agent demo-helper"
TARGET_PATHS="/Library/Application Support/ExampleAgent/demo-agent /Library/Application Support/ExampleHelper/demo-helper"
TARGET_LAUNCHD_LABELS="com.example.demo-agent com.example.demo-helper"
TARGET_ENDPOINTS="192.0.2.10:7777"
SENSITIVE_PATH_RULES="rules/sensitive_file_access.conf"
```

Profile rules:

- Profiles should be plain text and Bash-compatible.
- Profiles should not contain collection logic.
- Profiles should be validated before sensors start.
- Custom profiles should be easy to copy from the default profile.
- The selected profile should be copied into each run directory for traceability.

## 6. Rule Mechanism

Rules and code must be separated.

Rules describe behavior risk, not a specific software product. A rule should say what behavior matters and why; profiles decide which target Agent is being observed.

Required V2 rule types:

- sensitive file access
- network endpoint
- persistence
- privilege
- large upload

Rule examples:

```text
sensitive_file_access|high|Browser credential or history file was accessed
network_endpoint|medium|Target process connected to configured external endpoint
persistence|medium|LaunchDaemon or LaunchAgent exists and is active
privilege|medium|Target process is running as root or another privileged user
large_upload|medium|Potential large outbound transfer observed
```

Rule requirements:

- Rules should be small text files.
- Blank lines and comments should be ignored.
- Rules should not execute commands.
- Rules should not directly reference one hard-coded product when the behavior can be described generically.
- Analyzer output should include the matched rule type and severity.

## 7. Analyzer Mechanism

The Analyzer reads raw logs and applies rules.

Analyzer responsibilities:

- Read raw logs from the run directory.
- Generate `timeline.csv`.
- Generate findings.
- Calculate a risk score.
- Explain behavior and risk signals.
- Avoid unsupported malware verdicts.

The Analyzer must not make a final malicious/not-malicious judgment. It should provide behavior explanation and risk hints such as:

- Target process was observed running.
- Target process contacted a configured endpoint.
- Target process accessed a sensitive path.
- Target service appears persistent through launchd.
- Evidence was not observed during the collection window.

Recommended analyzer outputs:

```text
timeline.csv
findings.raw
risk_score.txt
```

Recommended `timeline.csv` fields:

```text
timestamp,source,event_type,target,evidence,severity
```

Recommended risk scoring approach:

- Start at 0.
- Add points for matched rules.
- Keep score explainable by listing contributing findings.
- Do not treat score as a malware verdict.
- Include missing-data limitations in the report.

## 8. Reporter Mechanism

Reporters render analyzer output into user-facing artifacts.

Required V2 report files:

- `summary.txt`
- `findings.txt`
- `timeline.csv`
- `report.html`

Language support:

- `REPORT_LANG=auto`
- `REPORT_LANG=zh-CN`
- `REPORT_LANG=en-US`

Language behavior:

- Chinese systems output Chinese reports by default.
- Non-Chinese systems output English reports by default.
- Users can force Chinese or English in `config.conf` or the selected profile.

Reporter requirements:

- Reporters should not collect evidence.
- Reporters should not parse raw logs directly when analyzer output is available.
- Reporters should load text templates from i18n files.
- Reporters should include evidence references and limitations.
- Reporters should clearly state that SDMon is read-only and observation-window based.

## 9. i18n Mechanism

V2 should separate report templates and collection logic.

Recommended i18n structure:

```text
i18n/
  zh-CN/
    messages.conf
  en-US/
    messages.conf
```

`messages.conf` should contain report strings keyed by stable identifiers:

```text
report.title=SDMon Behavior Analysis Report
summary.title=Summary
findings.title=Findings
limitations.title=Limitations
```

Chinese example:

```text
report.title=SDMon 行为分析报告
summary.title=摘要
findings.title=发现
limitations.title=限制说明
```

Requirements:

- Collectors and sensors should avoid user-facing prose.
- Analyzers should emit structured data where practical.
- Reporters should resolve message keys based on `REPORT_LANG`.
- Missing translation keys should fall back to English.

## 10. What V2 Does Not Do

V2 does not include:

- Windows implementation
- Linux implementation
- Background resident service
- Security software bypass
- Agent uninstall or destruction
- Hidden monitoring
- Collection of unrelated personal content

V2 should remain a transparent, user-triggered, read-only analysis framework.

## 11. V1.1 To V2 Migration Plan

Migration should preserve V1.1 as the baseline while V2 is introduced gradually.

Recommended steps:

1. Keep V1.1 runnable as the baseline.
2. Add the V2 directory structure without changing V1.1 behavior.
3. Gradually split `bin/monitor.sh` into `sensors/macos/*`.
4. Move rules and profiles into independent directories.
5. Upgrade `summary.sh` and `findings.sh` concepts into `reporters/`.
6. Add analyzer-generated `timeline.csv` and risk score output.
7. Add i18n-backed report templates.
8. Update README last, after the V2 workflow is runnable and tested.

This order reduces risk. It lets each V2 layer be tested while the V1.1 monitor remains available as a known-good baseline.
