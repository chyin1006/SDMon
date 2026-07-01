# SDMon V2 Configuration Design

This document defines the SDMon V2 Configuration system at the framework design level. It does not change the V1.1 baseline, does not modify existing code, and does not move any existing files.

## 1. Configuration Goals

The Configuration system makes SDMon configurable without hard-coding target details into framework logic.

Primary goals:

- Make SDMon behavior configurable.
- Avoid hard-coding target processes, paths, endpoints, and report language in code.
- Support layered configuration through `config.conf`, `profile.conf`, and `rule.conf` files.
- Keep V2 Bash-friendly first.
- Avoid Python, Homebrew, or third-party configuration parsers in V2.
- Keep configuration readable, auditable, and easy to copy into each run directory.
- Preserve the read-only monitoring model.
- Keep target-specific values in Profiles and behavior-matching values in Rules.

Configuration should describe how SDMon runs. It should not become an execution mechanism.

## 2. Configuration Layers

SDMon V2 should resolve configuration through clear priority layers.

Recommended priority order:

```text
Command Line parameters
  ↓
Profile configuration
  ↓
config.conf global configuration
  ↓
default values
```

Layer meaning:

- Command Line parameters override runtime choices for a single run.
- Profile configuration defines target-specific scope and can override relevant global defaults.
- `config.conf` defines global defaults for the local SDMon installation.
- default values provide safe fallback behavior when optional settings are missing.

The resolved result should be written to `resolved_config.conf` for traceability.

## 3. Global Configuration: config.conf

`config.conf` defines global defaults for SDMon runtime behavior.

Recommended fields:

```bash
SDMON_VERSION="2.0"
OUTPUT_BASE_DIR="$HOME/Downloads/2026-110"
DEFAULT_PROFILE="profiles/macos/custom/sdom-agent.conf"
REPORT_LANG="auto"
RUN_DURATION="300"

ENABLE_PROCESS_SENSOR="true"
ENABLE_FILE_SENSOR="true"
ENABLE_NETWORK_SENSOR="true"
ENABLE_LAUNCHD_SENSOR="true"
ENABLE_SYSTEM_SENSOR="true"
ENABLE_PERMISSION_SENSOR="false"

ENABLE_HTML_REPORT="true"
ENABLE_JSON_REPORT="true"
ENABLE_CSV_REPORT="true"

LOG_LEVEL="info"
```

Field purpose:

| Field | Purpose |
| --- | --- |
| `SDMON_VERSION` | Declares the expected SDMon configuration version. |
| `OUTPUT_BASE_DIR` | Base directory for run output. |
| `DEFAULT_PROFILE` | Default Profile path when no Profile is selected. |
| `REPORT_LANG` | Report language strategy: `auto`, `zh-CN`, or `en-US`. |
| `RUN_DURATION` | Default monitoring duration for timed runs. |
| `ENABLE_PROCESS_SENSOR` | Enables or disables the process Sensor. |
| `ENABLE_FILE_SENSOR` | Enables or disables the file Sensor. |
| `ENABLE_NETWORK_SENSOR` | Enables or disables the network Sensor. |
| `ENABLE_LAUNCHD_SENSOR` | Enables or disables the launchd Sensor. |
| `ENABLE_SYSTEM_SENSOR` | Enables or disables the system Sensor. |
| `ENABLE_PERMISSION_SENSOR` | Enables or disables the permission Sensor. |
| `ENABLE_HTML_REPORT` | Enables or disables HTML report output. |
| `ENABLE_JSON_REPORT` | Enables or disables JSON report output. |
| `ENABLE_CSV_REPORT` | Enables or disables CSV report output. |
| `LOG_LEVEL` | Controls framework log verbosity. |

Global configuration should not contain target-specific Agent identity unless it is only selecting a default Profile.

## 4. Profile Configuration

Profile configuration describes the Agent, App, or Service being analyzed.

Profile fields may override relevant global settings when the override is target-specific.

Recommended Profile fields:

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
RISK_WEIGHT="network_endpoint:2 sensitive_file_access:3 persistence:2"
TAGS="macos custom enterprise-agent read-only"
```

Profile configuration can define or override:

- `PROFILE_ID`
- `PROFILE_NAME`
- `PROFILE_PLATFORM`
- `PROFILE_CATEGORY`
- `TARGET_PROCESSES`
- `TARGET_PATHS`
- `TARGET_LAUNCHD`
- `TARGET_ENDPOINTS`
- `REPORT_LANG`
- `RISK_WEIGHT`
- `TAGS`

Profile configuration should not start Sensors, execute commands, parse logs, generate reports, modify target software, or contain remediation instructions.

## 5. Rule Configuration

Rule configuration defines behavior matching metadata used by the Rule Engine.

Recommended Rule fields:

```bash
RULE_ID="network_target_endpoint_connection"
RULE_NAME="Target Endpoint Connection"
RULE_TYPE="network"
RULE_LEVEL="medium"
RULE_ENABLED="true"
RULE_WEIGHT="2"
RULE_CONFIDENCE="80"
RULE_MATCH_FIELD="endpoint"
RULE_MATCH_PATTERN="192.0.2.10:7777"
```

Rule configuration can define:

- `RULE_ID`
- `RULE_NAME`
- `RULE_TYPE`
- `RULE_LEVEL`
- `RULE_ENABLED`
- `RULE_WEIGHT`
- `RULE_CONFIDENCE`
- `RULE_MATCH_FIELD`
- `RULE_MATCH_PATTERN`

Rules should describe behavior patterns and risk metadata. They should not collect data, start Sensors, generate final reports, modify target Agents, or execute remediation commands.

## 6. Configuration Validation

Configuration validation should run before Sensors start.

Required validation checks:

- `config.conf` exists.
- Selected Profile exists.
- `REPORT_LANG` is one of `auto`, `zh-CN`, or `en-US`.
- `OUTPUT_BASE_DIR` exists or can be created and is writable.
- Sensor enable fields are either `true` or `false`.
- Profile defines at least one of `TARGET_PROCESSES` or `TARGET_PATHS`.
- Rule required fields are complete.

Global configuration required fields:

- `OUTPUT_BASE_DIR`
- `DEFAULT_PROFILE`
- `REPORT_LANG`

Profile required fields:

- `PROFILE_ID`
- `PROFILE_NAME`
- `PROFILE_PLATFORM`
- `TARGET_PROCESSES` or `TARGET_PATHS`

Rule required fields:

- `RULE_ID`
- `RULE_NAME`
- `RULE_TYPE`
- `RULE_LEVEL`
- `RULE_MATCH_FIELD`
- `RULE_MATCH_PATTERN`

Validation should distinguish between blocking errors and warnings.

Blocking errors should stop startup. Warnings should be written to `config_warning.log` and included in report metadata.

## 7. Configuration Loading Flow

Configuration loading should be deterministic and auditable.

Recommended flow:

```text
load config
  ↓
load profile
  ↓
load rules
  ↓
merge config
  ↓
validate
  ↓
start sensors
```

Flow responsibilities:

### load config

Read global defaults from `config.conf`.

### load profile

Read the selected Profile from a Profile path, command line argument, or `DEFAULT_PROFILE`.

### load rules

Read enabled Rule files from configured Rule directories.

### merge config

Apply priority order: Command Line parameters, then Profile configuration, then global configuration, then defaults.

### validate

Validate merged configuration, Profile scope, Rule metadata, output directory, sensor toggles, and report language.

### start sensors

Start only after configuration is resolved and validated.

The resolved configuration should be copied into the run directory as `resolved_config.conf`.

## 8. Error Handling

Configuration errors should be visible and actionable.

Error handling principles:

- Use default values when optional configuration is missing.
- Stop startup and show a clear message when critical fields are missing.
- Write non-critical configuration issues to `config_warning.log`.
- Write all resolved configuration values to `resolved_config.conf`.
- Preserve validation results for Reporter output.
- Avoid starting Sensors with ambiguous target scope.
- Avoid silently ignoring invalid high-impact settings.

Examples of blocking errors:

- Missing `config.conf` when no defaults are available.
- Selected Profile does not exist.
- Profile has no `TARGET_PROCESSES` and no `TARGET_PATHS`.
- `OUTPUT_BASE_DIR` cannot be created or written.
- `REPORT_LANG` is not one of the allowed values.

Examples of warnings:

- Optional report format disabled.
- Permission Sensor disabled.
- Unknown non-critical field found.
- Rule is disabled.
- Rule confidence is missing and defaults are applied.

## 9. Security Principles

Configuration must remain data, not executable behavior.

Security principles:

- Do not allow configuration to execute arbitrary commands.
- Do not allow dangerous shell statements in configuration files.
- Limit `source` risk when reading configuration.
- Prefer safe parsing in V2 where practical.
- If `source` is used, only source trusted configuration files inside the repository or selected local SDMon configuration directories.
- Reject or warn on command substitution patterns.
- Reject or warn on shell metacharacters that are not needed for simple key-value configuration.
- Treat Profiles and Rules as untrusted until validated.
- Do not download, auto-update, or remotely execute configuration.

Safe parsing direction:

- Prefer `KEY="value"` style configuration.
- Allow only expected key names.
- Validate values after parsing.
- Ignore or reject unknown executable-looking lines.
- Keep configuration examples free of shell logic.

If V2 initially uses Bash `source` for simplicity, it should be treated as a transitional implementation detail with strict trust boundaries and validation.

## 10. Example Configuration

### config.conf example

```bash
SDMON_VERSION="2.0"
OUTPUT_BASE_DIR="$HOME/Downloads/2026-110"
DEFAULT_PROFILE="profiles/macos/custom/sdom-agent.conf"
REPORT_LANG="auto"
RUN_DURATION="300"

ENABLE_PROCESS_SENSOR="true"
ENABLE_FILE_SENSOR="true"
ENABLE_NETWORK_SENSOR="true"
ENABLE_LAUNCHD_SENSOR="true"
ENABLE_SYSTEM_SENSOR="true"
ENABLE_PERMISSION_SENSOR="false"

ENABLE_HTML_REPORT="true"
ENABLE_JSON_REPORT="true"
ENABLE_CSV_REPORT="true"

LOG_LEVEL="info"
```

### macOS custom profile example

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
RISK_WEIGHT="network_endpoint:2 sensitive_file_access:3 persistence:2 privilege:2"
TAGS="macos custom enterprise-agent"
```

### rule.conf example

```bash
RULE_ID="file_sensitive_keychain_access"
RULE_NAME="Sensitive Keychain Access"
RULE_TYPE="file"
RULE_LEVEL="high"
RULE_ENABLED="true"
RULE_WEIGHT="3"
RULE_CONFIDENCE="80"
RULE_MATCH_FIELD="file_path"
RULE_MATCH_PATTERN="Library/Keychains"
```

These examples are declarative. They should not contain shell functions, command substitutions, redirects, pipes, or process execution.

## 11. V2 Does Not Do

V2 Configuration intentionally excludes remote and unsafe behavior.

V2 does not:

- Download configuration from the network.
- Execute remote configuration.
- Automatically modify system settings.
- Automatically disable security features.
- Execute commands through configuration.
- Treat configuration as a plugin runtime.
- Store secrets in configuration files.
- Use configuration to stop, unload, uninstall, bypass, or alter target Agents.

Configuration controls SDMon observation scope and output behavior only.

## 12. V1.1 To V2 Migration

V1.1 contains several values that should move into V2 configuration layers.

Migration targets:

| V1.1 hard-coded value | V2 configuration destination |
| --- | --- |
| output base directory | `config.conf` as `OUTPUT_BASE_DIR` |
| target process names | Profile as `TARGET_PROCESSES` |
| target installation paths | Profile as `TARGET_PATHS` |
| target LaunchDaemon labels | Profile as `TARGET_LAUNCHD` |
| target network endpoint | Profile as `TARGET_ENDPOINTS` or Rule as `RULE_MATCH_PATTERN` |
| report language | `config.conf` or Profile as `REPORT_LANG` |
| sensor enable behavior | `config.conf` as `ENABLE_*_SENSOR` fields |
| report format toggles | `config.conf` as `ENABLE_*_REPORT` fields |
| sensitive behavior checks | Rule files as `RULE_*` fields |

Recommended migration sequence:

1. Keep V1.1 files in place as the baseline.
2. Introduce V2 `config.conf` field definitions without changing runtime behavior.
3. Move target identity into a macOS custom Profile design.
4. Move behavior matching into Rule configuration design.
5. Generate `resolved_config.conf` in V2 run directories.
6. Update Sensors to consume resolved configuration instead of hard-coded values.
7. Update Analyzer and Reporter to include configuration metadata.

The migration should preserve read-only behavior and should not require Python, Homebrew, or third-party tools.
