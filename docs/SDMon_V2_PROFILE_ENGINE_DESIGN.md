# SDMon V2 Profile Engine Design

This document defines the SDMon V2 Profile Engine at the framework design level. It does not define concrete implementation code and does not change the V1.1 baseline.

## 1. Profile Engine Goals

The Profile Engine exists to describe the Agent, App, or Service being analyzed without hard-coding a specific product into SDMon core logic.

Primary goals:

- Use a Profile to describe one analyzed Agent, App, or Service.
- Avoid hard-coding specific software names, paths, endpoints, or service labels in framework code.
- Let SDMon support different target classes through Profiles, including MDM, EDR, VPN, Zero Trust, AI Agent, and Custom Agent targets.
- Keep V2 macOS first while preserving a Profile model that can later support Windows and Linux.
- Keep Profiles declarative, readable, portable, and safe.
- Keep Profiles separate from Sensors, Rules, Analyzers, and Reporters.

A Profile is not executable collection logic. It is target metadata and analysis context.

## 2. Profile Responsibilities

A Profile defines the scope and expectations for one target.

Profile responsibilities include:

- Define target name.
- Define target platform.
- Define process names.
- Define installation paths.
- Define LaunchDaemon or LaunchAgent identifiers.
- Define network endpoints.
- Define sensitive paths relevant to the target analysis.
- Define expected behavior.
- Define risk weights.
- Define report language strategy.

A Profile should answer these questions:

- What is the target called?
- Which platform does this Profile apply to?
- Which process names should Sensors pay attention to?
- Which installed paths should be checked?
- Which startup items should be observed?
- Which network endpoints are expected or important?
- Which local paths are sensitive in this analysis context?
- Which behaviors are expected and which deserve attention?
- How should findings be weighted for this target?
- Which report language should be used?

A Profile should not:

- Start monitoring by itself.
- Stop monitoring by itself.
- Run collection tools.
- Parse raw logs.
- Generate final reports.
- Modify, unload, uninstall, block, or bypass the target software.

## 3. Profile File Format Design

V2 Profiles should use a Bash-friendly `.conf` format.

Reasons:

- Keeps the baseline macOS workflow simple.
- Avoids Python, Homebrew, or external parsers.
- Matches the current V1.1 project direction.
- Allows users to inspect and edit Profiles with any text editor.
- Keeps Profiles easy to copy into run metadata for traceability.

Recommended minimal Profile format:

```bash
PROFILE_ID="sdom-agent"
PROFILE_NAME="SDOM Agent"
PROFILE_PLATFORM="macos"
PROFILE_CATEGORY="enterprise-agent"
TARGET_PROCESSES="demo-agent demo-helper"
TARGET_PATHS="/Library/Application Support/ExampleAgent /Library/Application Support/ExampleHelper"
TARGET_LAUNCHD="com.example.demo-agent com.example.demo-helper"
TARGET_ENDPOINTS="192.0.2.10:7777"
REPORT_LANG="auto"
```

Recommended extended fields:

```bash
PROFILE_DESCRIPTION="Read-only behavior analysis profile for a macOS enterprise agent"
PROFILE_VENDOR="unknown"
PROFILE_VERSION="1"
TARGET_BUNDLE_IDS=""
TARGET_EXPECTED_BEHAVIOR="runs_as_background_service connects_to_configured_endpoint"
SENSITIVE_PATHS="$HOME/Library/Keychains $HOME/.ssh $HOME/Documents"
RISK_WEIGHT="network_endpoint:2 sensitive_file_access:3 persistence:2 privilege:2"
TAGS="macos enterprise-agent custom read-only"
```

Field design rules:

- Values should be plain strings.
- Multiple values should be space-separated unless a later design defines a different list format.
- Profiles should avoid command substitution and dynamic execution.
- Profiles should avoid secrets.
- Profiles should avoid storing personal content.
- Profiles should be copied into each run directory as evidence of the selected target scope.

## 4. Profile Categories

V2 should organize macOS Profiles by Agent category.

Recommended macOS Profile categories:

```text
profiles/macos/edr/
profiles/macos/mdm/
profiles/macos/vpn/
profiles/macos/zerotrust/
profiles/macos/ai/
profiles/macos/custom/
```

Category purpose:

- `profiles/macos/edr/`: endpoint detection and response agents.
- `profiles/macos/mdm/`: mobile device management agents.
- `profiles/macos/vpn/`: enterprise VPN clients.
- `profiles/macos/zerotrust/`: Zero Trust access agents.
- `profiles/macos/ai/`: local AI agents, AI coding tools, and AI background services.
- `profiles/macos/custom/`: user-defined or investigation-specific targets.

Future extension paths:

```text
profiles/windows/edr/
profiles/windows/mdm/
profiles/windows/vpn/
profiles/windows/zerotrust/
profiles/windows/ai/
profiles/windows/custom/

profiles/linux/edr/
profiles/linux/mdm/
profiles/linux/vpn/
profiles/linux/zerotrust/
profiles/linux/ai/
profiles/linux/custom/
```

V2 should not implement Windows or Linux Profile execution logic. These paths are architecture extension points for later versions.

## 5. Profile Lifecycle

Profile lifecycle stages:

```text
discover -> load -> validate -> apply -> collect -> analyze -> report
```

### discover

The Profile Engine finds available Profiles in supported Profile directories.

Discovery output should include Profile identifiers, names, platforms, categories, and file paths.

### load

The selected Profile is loaded into the run context.

Loading should produce a Profile object or equivalent framework data structure that other components can read.

### validate

The Profile is checked before Sensors start.

Validation should ensure required fields exist, platform values are supported, and at least one meaningful target selector is present.

### apply

The validated Profile becomes the active Profile for the run.

Applying a Profile should freeze the target scope so collection and analysis use the same context.

### collect

Sensors use the active Profile to decide what to observe.

The Profile does not collect data. It only tells Sensors which processes, paths, launch items, endpoints, and sensitive locations matter.

### analyze

Analyzers use the Profile as context for interpreting raw logs and rule matches.

The Profile helps explain whether an event belongs to the selected target and how risk should be weighted.

### report

Reporters use Profile metadata for titles, target names, categories, platform labels, and report language behavior.

The Profile should be referenced in final reports so the reviewer knows exactly what scope was selected.

## 6. Profile And Sensor Relationship

A Profile does not collect data.

Sensors are responsible for collection.

The Profile only tells Sensors what targets to focus on.

Relationship model:

```text
Profile target scope -> Sensor selection -> Collector execution -> Raw logs
```

Examples:

- `TARGET_PROCESSES` tells the process Sensor which process names matter.
- `TARGET_PATHS` tells the file Sensor which install paths matter.
- `TARGET_LAUNCHD` tells the launchd Sensor which service labels matter.
- `TARGET_ENDPOINTS` tells the network Sensor which endpoints matter.
- `SENSITIVE_PATHS` tells the file Sensor and Analyzer which sensitive areas are relevant.

Sensor boundaries:

- Sensors may read Profile fields.
- Sensors should write raw logs and status data.
- Sensors should not change Profile definitions.
- Sensors should not generate final findings.
- Sensors should not render final reports.

## 7. Profile And Rule Relationship

Rules should not bind to one specific software product when the behavior can be described generically.

Profile and Rule responsibilities:

- Profile provides target context.
- Rule describes behavior risk.
- Rule Engine evaluates normalized events against rules.
- Analyzer turns rule matches into findings.

Examples:

- A network endpoint rule can describe connections to configured endpoints.
- The Profile supplies the configured endpoint values.
- A sensitive file access rule can describe access to browser history, SSH keys, keychains, or documents.
- The Profile supplies which target process or target path makes the event relevant.

This keeps SDMon reusable. Adding a new Agent should usually require a new Profile, not rewriting framework code or hard-coding software names into rules.

## 8. Profile And Reporter Relationship

A Profile can influence report presentation, but it does not render reports.

Profile fields may affect:

- Report title.
- Target name.
- Target category.
- Target platform.
- Report language.
- Expected behavior section.
- Scope and limitations section.
- Risk weighting explanation.

Reporter boundaries:

- Reporter reads Profile metadata.
- Reporter reads Analyzer outputs.
- Reporter resolves language through the Internationalization Manager.
- Reporter produces `summary.txt`, `findings.txt`, `timeline.csv`, `report.html`, or future formats.
- Profile does not generate report files directly.

## 9. Profile Validation

Validation should be strict enough to avoid ambiguous runs and simple enough for users to understand.

Required fields:

- `PROFILE_ID`
- `PROFILE_NAME`
- `PROFILE_PLATFORM`
- At least one of:
  - `TARGET_PROCESSES`
  - `TARGET_PATHS`

Optional fields:

- `PROFILE_DESCRIPTION`
- `PROFILE_CATEGORY`
- `PROFILE_VENDOR`
- `PROFILE_VERSION`
- `TARGET_ENDPOINTS`
- `TARGET_LAUNCHD`
- `TARGET_BUNDLE_IDS`
- `SENSITIVE_PATHS`
- `TARGET_EXPECTED_BEHAVIOR`
- `REPORT_LANG`
- `RISK_WEIGHT`
- `TAGS`

Recommended validation rules:

- `PROFILE_ID` should be stable, lowercase, and filename-friendly.
- `PROFILE_NAME` should be human-readable.
- `PROFILE_PLATFORM` should be `macos` for V2 runnable Profiles.
- `REPORT_LANG` should be `auto`, `zh-CN`, or `en-US` when present.
- `TARGET_PROCESSES` or `TARGET_PATHS` must contain at least one value.
- `PROFILE_CATEGORY` should match a known category when practical.
- Windows and Linux Profiles should not be treated as runnable in V2.
- Missing optional fields should not fail validation unless a selected Sensor requires them.

Validation output should be clear and actionable. A failed Profile should not start collection.

## 10. Profile Examples

### macOS enterprise agent profile

```bash
PROFILE_ID="sdom-agent"
PROFILE_NAME="SDOM Agent"
PROFILE_PLATFORM="macos"
PROFILE_CATEGORY="enterprise-agent"
PROFILE_DESCRIPTION="Read-only behavior analysis profile for a macOS enterprise background agent"
TARGET_PROCESSES="demo-agent demo-helper"
TARGET_PATHS="/Library/Application Support/ExampleAgent /Library/Application Support/ExampleHelper"
TARGET_LAUNCHD="com.example.demo-agent com.example.demo-helper"
TARGET_ENDPOINTS="192.0.2.10:7777"
SENSITIVE_PATHS="$HOME/Library/Keychains $HOME/.ssh $HOME/Documents $HOME/Desktop $HOME/Downloads"
TARGET_EXPECTED_BEHAVIOR="background_service configured_endpoint_connection launchd_persistence"
RISK_WEIGHT="network_endpoint:2 sensitive_file_access:3 persistence:2 privilege:2"
REPORT_LANG="auto"
TAGS="macos enterprise-agent custom v1.1-migration"
```

### macOS VPN client profile

```bash
PROFILE_ID="example-vpn-client"
PROFILE_NAME="Example VPN Client"
PROFILE_PLATFORM="macos"
PROFILE_CATEGORY="vpn"
PROFILE_DESCRIPTION="Example profile for a macOS enterprise VPN client"
TARGET_PROCESSES="example-vpn example-vpn-helper"
TARGET_PATHS="/Applications/ExampleVPN.app /Library/Application Support/ExampleVPN"
TARGET_LAUNCHD="com.example.vpn.helper"
TARGET_ENDPOINTS="vpn.example.com:443 gateway.example.com:443"
SENSITIVE_PATHS="$HOME/Library/Preferences $HOME/Library/Keychains"
TARGET_EXPECTED_BEHAVIOR="network_tunnel privileged_helper configured_gateway_connection"
RISK_WEIGHT="network_endpoint:2 privilege:2 persistence:1 sensitive_file_access:2"
REPORT_LANG="auto"
TAGS="macos vpn example"
```

### macOS AI agent profile

```bash
PROFILE_ID="example-ai-agent"
PROFILE_NAME="Example AI Agent"
PROFILE_PLATFORM="macos"
PROFILE_CATEGORY="ai"
PROFILE_DESCRIPTION="Example profile for a local AI assistant or coding agent background process"
TARGET_PROCESSES="example-ai-agent example-ai-helper"
TARGET_PATHS="$HOME/Library/Application Support/ExampleAI /Applications/ExampleAI.app"
TARGET_LAUNCHD="com.example.ai.agent"
TARGET_ENDPOINTS="api.example-ai.com:443"
SENSITIVE_PATHS="$HOME/Documents $HOME/Desktop $HOME/Downloads $HOME/.ssh"
TARGET_EXPECTED_BEHAVIOR="user_initiated_requests local_project_access remote_api_connection"
RISK_WEIGHT="network_endpoint:1 sensitive_file_access:3 persistence:2 large_upload:3"
REPORT_LANG="auto"
TAGS="macos ai example custom"
```

Example notes:

- Examples are templates, not verified product support claims.
- Real Profiles should be reviewed and tested before being marked ready.
- Profiles should avoid storing credentials, tokens, or private user content.

## 11. What V2 Does Not Do

V2 Profile Engine does not include:

- Windows Profile execution logic.
- Linux Profile execution logic.
- Network downloading of Profiles.
- Automatic Profile uploads.
- Use of Profiles to bypass security software.
- Use of Profiles to unload, uninstall, disable, or damage security software.
- Hidden monitoring behavior.
- Collection of personal content unrelated to target analysis.

Profiles are for transparent, user-controlled, read-only behavior analysis.

## 12. V1.1 To V2 Migration

V1.1 currently has specific targets embedded in the baseline monitor:

- `demo-agent`
- `demo-helper`
- `/Library/Application Support/ExampleAgent`
- `/Library/Application Support/ExampleHelper`
- `com.example.demo-agent`
- `com.example.demo-helper`
- `192.0.2.10:7777`

In V2, these should migrate into a Profile:

```text
profiles/macos/custom/sdom-agent.conf
```

Recommended migrated Profile identity:

```bash
PROFILE_ID="sdom-agent"
PROFILE_NAME="SDOM Agent"
PROFILE_PLATFORM="macos"
PROFILE_CATEGORY="custom"
TARGET_PROCESSES="demo-agent demo-helper"
TARGET_PATHS="/Library/Application Support/ExampleAgent /Library/Application Support/ExampleHelper"
TARGET_LAUNCHD="com.example.demo-agent com.example.demo-helper"
TARGET_ENDPOINTS="192.0.2.10:7777"
REPORT_LANG="auto"
```

Migration strategy:

1. Preserve V1.1 as the runnable baseline.
2. Add `profiles/macos/custom/sdom-agent.conf` as the V1.1 compatibility Profile.
3. Teach the V2 Profile Engine to load and validate that Profile.
4. Make Sensors read target scope from the active Profile.
5. Keep Rules behavior-oriented and independent from the specific target software.
6. Keep Reporters reading Profile metadata for target labels and language behavior.
7. Update README only after the V2 Profile workflow is runnable and tested.

This migration removes target-specific values from framework logic while preserving the original V1.1 monitoring scope.