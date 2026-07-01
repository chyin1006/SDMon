# SDMon V2 Architecture Design

## 1. Product Positioning

SDMon V2 is a read-only macOS dynamic monitoring and analysis framework for enterprise agents, endpoint tools, and local AI-related background components.

V1.1 is a focused monitor for `demo-agent` and `demo-helper`. V2 generalizes that model into a profile-driven tool that can observe different software targets without rewriting core scripts.

V2 should answer these questions for each target profile:

- Is the target installed?
- Is the target running?
- Which launch services or background items are active?
- Which files, directories, and sensitive locations are touched?
- Which network endpoints are contacted?
- What evidence supports each finding?
- Which artifacts can be shared for review without modifying the target software?

Core product principles remain unchanged:

- Read-only monitoring only.
- Do not stop, unload, uninstall, delete, quarantine, block, or modify target software.
- Prefer Bash and macOS built-in tools.
- Do not require Python or Homebrew for the baseline workflow.
- Keep output easy to find, zip, and review.
- Never commit generated logs, packet captures, reports, or zip packages.

## 2. Overall Architecture

V2 should separate target definition, collection, analysis, and reporting.

Recommended flow:

```text
Profile -> Rules -> Collectors -> Raw Logs -> Analyzers -> Reports -> Package
```

Main components:

- Profile loader: selects one target profile and loads its settings.
- Rule loader: loads process, service, network, file, and sensitive-path rules.
- Collector runner: starts read-only collectors and tracks only SDMon-owned PIDs.
- State manager: records active run directory, collector PIDs, selected profile, and timestamps.
- Analyzer runner: parses collected logs and applies rules to produce structured findings.
- Report generator: emits human-readable summaries and shareable report artifacts.
- Packager: creates a zip package from the run directory after collection stops.

The architecture should keep V1.1's double-click workflow:

1. Start monitoring.
2. Let collection run.
3. Stop monitoring.
4. Generate reports.
5. Re-run analysis later if needed.

## 3. Recommended Directory Structure

```text
SDMon/
  README.md
  AGENTS.md
  ROADMAP.md
  DECISIONS.md
  TODO.md
  VERSION
  config.conf

  bin/
    common.sh
    profile.sh
    rules.sh
    monitor.sh
    stop.sh
    analyse.sh
    summary.sh
    findings.sh
    report.sh
    package.sh

  collectors/
    process.sh
    network_lsof.sh
    launchctl.sh
    tcpdump.sh
    fs_usage.sh
    file_inventory.sh

  analyzers/
    process_analyzer.sh
    network_analyzer.sh
    launchctl_analyzer.sh
    fs_usage_analyzer.sh
    sensitive_path_analyzer.sh

  profiles/
    sdmon-v1.1.conf
    enterprise-agent-template.conf
    ai-agent-template.conf

  rules/
    common/
      sensitive_paths.conf
      browsers.conf
      documents.conf
      credentials.conf
    profiles/
      sdmon-v1.1/
        process.conf
        services.conf
        network.conf
        paths.conf
        sensitive_paths.conf

  docs/
    SDMon_V2_ARCHITECTURE.md

  examples/
    profiles/
    rules/
```

Runtime output stays outside the repository:

```text
~/Downloads/2026-110/
  run_YYYYMMDD_HHMMSS/
    metadata.conf
    collector_status.log
    process.log
    network.log
    launchctl.log
    fs_usage.log
    traffic.pcap
    summary.txt
    findings.txt
    report.txt
    run_YYYYMMDD_HHMMSS.zip
```

## 4. Profile Mechanism Design

A profile defines what SDMon monitors. It should be a plain shell-compatible `.conf` file so Bash can load it without external dependencies.

Example profile fields:

```bash
PROFILE_ID="sdmon-v1.1"
PROFILE_NAME="SDMon V1.1 demo-agent/demo-helper"
PROFILE_DESCRIPTION="Targeted macOS enterprise agent monitoring profile"

OUTPUT_DIR="$HOME/Downloads/2026-110"
SNAPSHOT_INTERVAL_SECONDS="10"
CAPTURE_INTERFACE="auto"

TARGET_PROCESSES="demo-agent demo-helper"
TARGET_PATHS="/Library/Application Support/ExampleAgent/demo-agent /Library/Application Support/ExampleHelper/demo-helper"
TARGET_SERVICES="com.example.demo-agent com.example.demo-helper"
TARGET_ENDPOINTS="192.0.2.10:7777"

RULE_DIR="rules/profiles/sdmon-v1.1"
COMMON_RULE_DIR="rules/common"
```

Profile rules:

- A profile must be selected before collection starts.
- If no profile is selected, use the V1.1-compatible default profile.
- The selected profile should be copied into each run directory as `metadata.conf`.
- The profile loader should reject missing required fields with clear errors.
- Profiles should not execute arbitrary collection logic; they only declare targets and rule locations.

Recommended commands:

```bash
bash Start_SDMon.command --profile sdmon-v1.1
bash Analyse.command --run ~/Downloads/2026-110/run_YYYYMMDD_HHMMSS
```

Double-click wrappers can continue using the default profile.

## 5. Rules Mechanism Design

Rules define what evidence SDMon should look for. V2 should support small, composable text rule files.

Recommended rule types:

- `process.conf`: process names, executable names, and command substrings.
- `services.conf`: launchd labels and expected domains such as `system/`.
- `network.conf`: IPs, hostnames, ports, and endpoint labels.
- `paths.conf`: installation paths and support directories.
- `sensitive_paths.conf`: user data locations that matter during analysis.
- `patterns.conf`: optional grep-compatible patterns for log analysis.

Suggested line formats:

```text
label|value
label|value|severity
label|value|severity|description
```

Examples:

```text
aes sshd process|demo-agent|info|Target process name
demo-helper service|com.example.demo-helper|info|Target launchd service
control server|192.0.2.10:7777|medium|Known target endpoint
Chrome History|$HOME/Library/Application\ Support/Google/Chrome/*/History|high|Browser history database
```

Rule behavior:

- Blank lines and `#` comments are ignored.
- Rules should be read-only and never trigger remediation.
- Rule parsing should tolerate missing optional fields.
- Analyzers should include the matched rule label in findings.
- Common rules can be reused across profiles.
- Profile-specific rules override or extend common rules.

## 6. Collector Design

Collectors gather raw evidence. Each collector should be a small Bash script that writes one primary log file and exits cleanly when stopped by SDMon.

Baseline collectors:

- Process collector: periodic `ps` snapshots for target processes.
- Network collector: periodic `sudo lsof -nP -iTCP -iUDP` snapshots.
- Launchctl collector: periodic `launchctl print` snapshots for target services.
- Tcpdump collector: packet capture for configured endpoints.
- Fs usage collector: filtered `sudo fs_usage` output for target process names.
- File inventory collector: existence checks for target paths and sensitive paths.

Collector contract:

- Inputs: selected profile, loaded rules, run directory, interval.
- Outputs: one or more files under the current run directory.
- State: collector PID is recorded by the supervisor.
- Stop behavior: SDMon stops only collector PIDs that it started.
- Safety: collectors must not stop, unload, delete, modify, quarantine, or block target software.

Collector metadata should be logged to `collector_status.log`:

```text
collector|pid|started_at|output|status
process|12345|2026-06-29 16:00:00|process.log|running
```

## 7. Analyzer Design

Analyzers read raw logs and rules after collection. They should not require active monitoring and should be safe to run repeatedly.

Baseline analyzers:

- Process analyzer: reports observed target process rows and missing processes.
- Network analyzer: reports endpoint matches and related process network rows.
- Launchctl analyzer: reports service state, PID, program path, and missing labels.
- Fs usage analyzer: reports file access matches by sensitive path category.
- Sensitive path analyzer: reports whether sensitive locations exist and whether they appeared in logs.

Analyzer contract:

- Inputs: run directory, profile metadata, rules.
- Outputs: structured intermediate findings plus human-readable report sections.
- Idempotency: repeated analysis overwrites generated report files but does not alter raw logs.
- Evidence-first output: each finding should cite the source log and matching line when practical.

Recommended finding fields:

```text
finding_id|severity|category|rule_label|source_file|evidence|notes
```

Severity should be conservative:

- `info`: observed state or inventory detail.
- `low`: expected or weak behavioral signal.
- `medium`: meaningful access or network signal.
- `high`: sensitive data access or strong suspicious behavior.
- `unknown`: insufficient evidence.

## 8. Report Output Design

V2 reports should support both quick review and deeper handoff.

Recommended outputs:

- `summary.txt`: short human-readable run overview.
- `findings.txt`: prioritized findings with evidence snippets.
- `report.txt`: full report combining profile, rules, collectors, findings, and file inventory.
- `metadata.conf`: selected profile, timestamps, SDMon version, host basics.
- `collector_status.log`: collector lifecycle information.
- Optional later output: `report.html` for easier sharing.

Report sections:

1. Run metadata.
2. Selected profile.
3. Target inventory.
4. Collector status.
5. Process observations.
6. Service observations.
7. Network observations.
8. Sensitive path observations.
9. File access findings.
10. Limitations and missing data.

Reports must avoid overstating conclusions. If evidence is absent, the report should say that SDMon did not observe the behavior during the collection window, not that the behavior never happens.

## 9. V1.1 To V2 Migration Plan

Migration should be incremental and keep V1.1 runnable throughout.

Phase 1: preserve V1.1 behavior

- Keep existing command wrappers working.
- Keep default output under `~/Downloads/2026-110`.
- Keep `traffic.pcap`, `process.log`, `network.log`, `launchctl.log`, `fs_usage.log`, `summary.txt`, and `findings.txt` names.
- Add V1.1 as the first profile: `profiles/sdmon-v1.1.conf`.

Phase 2: extract profile and rule loading

- Move hard-coded target values into the V1.1 profile.
- Split process, service, network, path, and sensitive path rules into profile-specific rule files.
- Add validation for missing profile fields and missing rule files.

Phase 3: split collectors

- Move collection logic from `bin/monitor.sh` into scripts under `collectors/`.
- Keep `bin/monitor.sh` as the supervisor and compatibility entrypoint.
- Standardize collector PID tracking and collector status logging.

Phase 4: split analyzers

- Move parsing logic from `summary.sh` and `findings.sh` into `analyzers/`.
- Keep `summary.sh` and `findings.sh` as report entrypoints.
- Add structured intermediate findings for future report formats.

Phase 5: add reusable profiles

- Add generic enterprise agent and AI agent profile templates.
- Add examples for enterprise VPN clients, EDR agents, and local AI agent processes when target details are known.
- Keep all templates read-only and clearly marked as examples until validated.

## 10. V2 Development Milestones

Milestone 1: V2 architecture and compatibility plan

- Add architecture document.
- Define profile and rule file formats.
- Identify V1.1 compatibility requirements.

Milestone 2: Profile loader

- Implement `bin/profile.sh`.
- Add `profiles/sdmon-v1.1.conf`.
- Validate required profile fields.
- Keep default double-click workflow unchanged.

Milestone 3: Rule loader

- Implement `bin/rules.sh`.
- Split common and profile-specific rules.
- Add rule parsing helpers and validation output.

Milestone 4: Collector modularization

- Add `collectors/` scripts.
- Keep supervisor logic in `bin/monitor.sh`.
- Write `collector_status.log`.
- Confirm SDMon stops only its own collector processes.

Milestone 5: Analyzer modularization

- Add `analyzers/` scripts.
- Emit structured findings.
- Preserve `summary.txt` and `findings.txt` compatibility.

Milestone 6: Report improvements

- Add `report.txt`.
- Improve traffic and sensitive path summaries.
- Add clear limitations and missing-data sections.

Milestone 7: Profile templates

- Add reusable enterprise and AI agent templates.
- Document how to create a new profile.
- Add examples without committing runtime output.

Milestone 8: V2 validation

- Run shell syntax checks.
- Test default V1.1 profile on macOS.
- Test at least one template profile with harmless local process targets.
- Confirm logs, pcap, zip, and generated output remain ignored by Git.
