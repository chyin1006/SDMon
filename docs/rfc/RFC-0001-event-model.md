# RFC-0001: SDMon Normalized Event Model

Status: Draft

## Summary

The Normalized Event is the core data model for SDMon V2.

It defines a stable event shape between platform-specific Sensors and the framework layers that consume evidence. Sensors convert platform-specific Raw Events into Normalized Events. The Rule Engine, Analyzer, and Reporter consume these Normalized Events without depending on raw macOS, Windows, or Linux tool output.

In V2, SDMon remains macOS first. The event model is still designed to be cross-platform ready so future Windows and Linux Sensors can produce the same logical event categories.

## Motivation

SDMon needs a unified event model because raw evidence differs across platforms and collection tools.

Key motivations:

- macOS, Windows, and Linux raw logs are different.
- `fs_usage`, `lsof`, `tcpdump`, `launchctl`, Windows Event Log, and Linux systemd logs have different formats and semantics.
- The Rule Engine should not depend on low-level tool output.
- Analyzer and Reporter need stable input.
- Sensor should only convert Raw Event into Normalized Event.
- Cross-platform framework design requires a common language for process, file, network, service, permission, configuration, and security behavior.

Without a normalized event model, every Rule, Analyzer, and Reporter would need to understand every platform and every raw tool format. That would make SDMon harder to test, harder to extend, and easier to break.

## Design Goals

The Normalized Event Model should be:

- Cross-platform ready.
- Bash friendly for V2.
- Stable across Sensor implementation changes.
- Extensible for future fields and event categories.
- Rule-friendly so Rules can match on predictable fields.
- Reporter-friendly so final reports can cite evidence consistently.
- Analyzer-friendly so timelines, correlations, and risk scoring can use stable input.
- Read-only and evidence-first.
- Safe for storage in run output directories.

The event model should avoid over-engineering. V2 can start small as long as the schema has a clear extension path.

## Event Pipeline

Recommended event pipeline:

```text
Raw Event
  ↓
Sensor
  ↓
Normalized Event
  ↓
Rule Engine
  ↓
Finding
  ↓
Analyzer
  ↓
Reporter
```

Pipeline responsibilities:

- Raw Event preserves the original observation from a platform tool or Sensor source.
- Sensor collects raw evidence and emits Normalized Events.
- Normalized Event provides a stable schema for downstream components.
- Rule Engine matches events against behavior rules and creates Findings.
- Finding records an interpreted behavior signal and its evidence.
- Analyzer aggregates Findings, generates timelines, calculates risk, and prepares report data.
- Reporter renders final text, HTML, JSON, and CSV outputs.

A Sensor should not generate final Findings. A Rule should not collect raw data. A Reporter should not parse raw tool output when Normalized Events and Analyzer output are available.

## Event Categories

The event model should support common behavior categories.

Required categories:

- `process`
- `file`
- `network`
- `launchd`
- `service`
- `system`
- `permission`
- `configuration`
- `security`
- `application`

Category notes:

- `process`: Process state, process metadata, parent-child relationships, command context.
- `file`: File access, file inventory, sensitive path interaction.
- `network`: Local and remote endpoints, protocol, direction, transfer metadata.
- `launchd`: macOS LaunchDaemon and LaunchAgent observations.
- `service`: Cross-platform service or persistence observations.
- `system`: Host, OS, user, and interface context.
- `permission`: Privacy, security, TCC, PPPC, Full Disk Access, Accessibility, and related permission state.
- `configuration`: SDMon resolved configuration, selected Profile, enabled Sensors, and run settings.
- `security`: Security-relevant platform state or observations that do not fit a narrower category.
- `application`: App-specific behavior that may later be mapped from bundle IDs, installed apps, or app-level metadata.

V2 only implements macOS collection, but event categories should preserve room for Windows and Linux. For example, a macOS LaunchDaemon, Windows Service, and Linux systemd unit can all map into `service` or persistence-related events while preserving platform-specific raw evidence.

## Common Event Fields

All Normalized Events should share a common base schema.

Recommended common fields:

| Field | Description |
| --- | --- |
| `EVENT_ID` | Unique event identifier within a run. |
| `EVENT_VERSION` | Event schema version. |
| `TIMESTAMP` | Event time or observation time. |
| `HOSTNAME` | Hostname where the event was collected. |
| `USER_NAME` | Related user name when available. |
| `PLATFORM` | Platform such as `macos`, `windows`, or `linux`. |
| `SENSOR_TYPE` | Sensor that produced the event. |
| `PROFILE_ID` | Active Profile identifier. |
| `EVENT_CATEGORY` | High-level event category. |
| `EVENT_TYPE` | Specific event type within the category. |
| `PROCESS_NAME` | Related process name when available. |
| `PID` | Related process ID when available. |
| `PARENT_PID` | Parent process ID when available. |
| `ACTION` | Observed action, such as `running`, `read`, `connect`, `found`, or `allowed`. |
| `TARGET` | Primary event target, such as a path, endpoint, service label, or permission name. |
| `TARGET_TYPE` | Type of target, such as `file`, `directory`, `endpoint`, `service`, or `permission`. |
| `SOURCE` | SDMon source component or Sensor name. |
| `RAW_SOURCE` | Underlying platform tool or raw source, such as `fs_usage`, `lsof`, or `launchctl`. |
| `RAW_LINE` | Original raw evidence line or reference. |
| `CONFIDENCE` | Evidence confidence score or label. |
| `TAGS` | Comma-separated or array-like tags for filtering and reporting. |

Field principles:

- Missing values should be empty rather than invented.
- Platform-specific details may be added as extension fields.
- `CONFIDENCE` is evidence reliability, not risk severity.
- `RAW_LINE` should avoid copying unrelated personal content when a reference is enough.
- `EVENT_VERSION` allows future schema evolution.

## Process Event

A Process Event records process state or process metadata.

Recommended process fields:

- `PROCESS_NAME`
- `PID`
- `PARENT_PID`
- `PROCESS_PATH`
- `COMMAND_LINE`
- `USER_NAME`
- `ACTION`

Example actions:

- `running`
- `not_running`
- `started`
- `stopped_observed`
- `parent_observed`

Process Events should be used for target process presence, parent-child context, command metadata, and runtime identity. They should not decide whether a process is malicious.

## File Event

A File Event records file or directory behavior.

Recommended file fields:

- `FILE_PATH`
- `FILE_OPERATION`
- `PROCESS_NAME`
- `PID`
- `ACCESS_TYPE`
- `SENSITIVE_MATCH`

Example actions:

- `read`
- `write_observed`
- `open`
- `stat`
- `exists`
- `sensitive_path_access`

`SENSITIVE_MATCH` indicates whether the event matched a sensitive path category, such as Keychain, SSH keys, browser credential stores, Documents, Desktop, Downloads, or application data. It should not by itself be a final risk judgment.

## Network Event

A Network Event records network connection or traffic metadata.

Recommended network fields:

- `LOCAL_ADDRESS`
- `LOCAL_PORT`
- `REMOTE_ADDRESS`
- `REMOTE_PORT`
- `PROTOCOL`
- `DIRECTION`
- `BYTES_SENT`
- `BYTES_RECEIVED`

Example actions:

- `connect`
- `listen`
- `send_observed`
- `receive_observed`
- `pcap_captured`

Network Events should support both connection snapshots and packet capture references. `tcpdump` may provide direct packet evidence, while `lsof` may provide process-to-endpoint mapping.

## Launch / Service Event

Launch and service events describe startup, persistence, and service state.

The model should support:

- macOS `launchd`
- Windows Service
- Linux `systemd`

Future platform mappings:

- macOS LaunchDaemon or LaunchAgent maps to `launchd` or `service` event categories.
- Windows Service maps to `service` event category.
- Linux systemd unit maps to `service` event category.

Recommended fields:

- `SERVICE_NAME`
- `SERVICE_LABEL`
- `SERVICE_PATH`
- `SERVICE_STATE`
- `SERVICE_TYPE`
- `PLIST_PATH`
- `UNIT_PATH`
- `ACTION`

Example actions:

- `found`
- `loaded`
- `enabled`
- `disabled_observed`
- `state_observed`

These events are observational only. SDMon must not unload, disable, delete, or modify services.

## Permission Event

A Permission Event records read-only permission and privacy state.

Relevant macOS concepts include:

- TCC
- PPPC
- Full Disk Access
- Accessibility
- Screen Recording
- Automation
- Files and Folders access

Recommended fields:

- `PERMISSION_NAME`
- `PERMISSION_SCOPE`
- `PERMISSION_STATUS`
- `BUNDLE_ID`
- `PROCESS_NAME`
- `PROFILE_ID`
- `ACTION`

Example actions:

- `permission_found`
- `permission_missing`
- `permission_allowed_observed`
- `permission_denied_observed`
- `permission_unknown`

Permission Events should be read-only checks. SDMon must not modify TCC, PPPC, privacy databases, profiles, or security settings.

## Confidence Model

Confidence represents how reliable the event evidence is. It is separate from risk level.

Different Sensors may produce different confidence levels:

- Direct packet evidence from `tcpdump` may have higher confidence for network traffic existence.
- `lsof` may have high confidence for process-to-socket mapping at the snapshot time.
- A single ambiguous `fs_usage` line may have lower confidence.
- `launchctl` output may have high confidence for observed launchd state.
- Multiple Sensors observing the same behavior should increase confidence.

Recommended confidence representation:

- Numeric score from `0` to `100`, or
- Simple labels such as `low`, `medium`, `high` during early V2 implementation.

Confidence examples:

- `90`: packet capture observed a matching endpoint.
- `80`: `lsof` linked a target process to a remote endpoint.
- `60`: `fs_usage` showed a single relevant file path access.
- `95`: `launchctl` and file inventory both confirmed the same LaunchDaemon.

The Analyzer may later combine confidence values across related events and Findings.

## Event Storage

V2 should write normalized events into line-oriented files under the run directory.

Recommended event files:

```text
events/process_events.jsonl
events/file_events.jsonl
events/network_events.jsonl
events/service_events.jsonl
events/system_events.jsonl
events/permission_events.jsonl
events/all_events.jsonl
```

Storage principles:

- Category-specific files make debugging easier.
- `events/all_events.jsonl` supports unified timeline and correlation analysis.
- Raw logs should remain separate from normalized events.
- Events should be written inside the run output directory, not committed to the repository.
- Events should reference raw evidence when possible.

## Bash Friendly Format

V2 should remain Bash friendly.

Acceptable transitional formats:

- Line-based `key=value` records.
- Delimited text records with explicit field order.
- JSONL records generated by safe shell formatting.

Recommended final direction:

- JSONL should become the preferred normalized event format.

Rationale:

- JSONL is line-oriented.
- JSONL supports streaming and append-only output.
- JSONL is easy for later tools, SIEM pipelines, and reports to consume.
- JSONL can preserve strings, arrays, and nested metadata when needed.

V2 can phase in JSONL gradually. Early Sensors may write text logs first and then convert them into normalized events as a separate normalization step.

## Examples

### Process running

```json
{"EVENT_ID":"evt-000001","EVENT_VERSION":"1","TIMESTAMP":"2026-06-29T10:00:00Z","HOSTNAME":"demo-host.local","USER_NAME":"root","PLATFORM":"macos","SENSOR_TYPE":"process","PROFILE_ID":"sdom-agent","EVENT_CATEGORY":"process","EVENT_TYPE":"process_state","PROCESS_NAME":"demo-agent","PID":"1234","PARENT_PID":"1","ACTION":"running","TARGET":"demo-agent","TARGET_TYPE":"process","SOURCE":"process_sensor","RAW_SOURCE":"ps","RAW_LINE":"demo-agent 1234","CONFIDENCE":"90","TAGS":"macos,process,target"}
```

### File access

```json
{"EVENT_ID":"evt-000002","EVENT_VERSION":"1","TIMESTAMP":"2026-06-29T10:01:00Z","HOSTNAME":"demo-host.local","USER_NAME":"root","PLATFORM":"macos","SENSOR_TYPE":"file","PROFILE_ID":"sdom-agent","EVENT_CATEGORY":"file","EVENT_TYPE":"file_access","PROCESS_NAME":"demo-helper","PID":"2345","PARENT_PID":"1","ACTION":"read","TARGET":"/Users/example/Library/Keychains/login.keychain-db","TARGET_TYPE":"file","SOURCE":"file_sensor","RAW_SOURCE":"fs_usage","RAW_LINE":"fs_usage reference line 42","CONFIDENCE":"60","TAGS":"macos,file,keychain","FILE_PATH":"/Users/example/Library/Keychains/login.keychain-db","FILE_OPERATION":"read","ACCESS_TYPE":"sensitive_path","SENSITIVE_MATCH":"keychain"}
```

### Network connection

```json
{"EVENT_ID":"evt-000003","EVENT_VERSION":"1","TIMESTAMP":"2026-06-29T10:02:00Z","HOSTNAME":"demo-host.local","USER_NAME":"root","PLATFORM":"macos","SENSOR_TYPE":"network","PROFILE_ID":"sdom-agent","EVENT_CATEGORY":"network","EVENT_TYPE":"network_connection","PROCESS_NAME":"demo-agent","PID":"1234","PARENT_PID":"1","ACTION":"connect","TARGET":"192.0.2.10:7777","TARGET_TYPE":"endpoint","SOURCE":"network_sensor","RAW_SOURCE":"lsof","RAW_LINE":"lsof reference line 12","CONFIDENCE":"80","TAGS":"macos,network,endpoint","LOCAL_ADDRESS":"192.0.2.20","LOCAL_PORT":"53122","REMOTE_ADDRESS":"192.0.2.10","REMOTE_PORT":"7777","PROTOCOL":"tcp","DIRECTION":"outbound","BYTES_SENT":"","BYTES_RECEIVED":""}
```

### Launch daemon found

```json
{"EVENT_ID":"evt-000004","EVENT_VERSION":"1","TIMESTAMP":"2026-06-29T10:03:00Z","HOSTNAME":"demo-host.local","USER_NAME":"root","PLATFORM":"macos","SENSOR_TYPE":"launchd","PROFILE_ID":"sdom-agent","EVENT_CATEGORY":"service","EVENT_TYPE":"launch_daemon","PROCESS_NAME":"","PID":"","PARENT_PID":"","ACTION":"found","TARGET":"com.example.demo-agent","TARGET_TYPE":"service","SOURCE":"launchd_sensor","RAW_SOURCE":"launchctl","RAW_LINE":"launchctl reference line 8","CONFIDENCE":"90","TAGS":"macos,launchd,persistence","SERVICE_NAME":"com.example.demo-agent","SERVICE_LABEL":"com.example.demo-agent","SERVICE_PATH":"/Library/LaunchDaemons/com.example.demo-agent.plist","SERVICE_STATE":"loaded","SERVICE_TYPE":"launchdaemon","PLIST_PATH":"/Library/LaunchDaemons/com.example.demo-agent.plist"}
```

### Permission status

```json
{"EVENT_ID":"evt-000005","EVENT_VERSION":"1","TIMESTAMP":"2026-06-29T10:04:00Z","HOSTNAME":"demo-host.local","USER_NAME":"demo-user","PLATFORM":"macos","SENSOR_TYPE":"permission","PROFILE_ID":"sdom-agent","EVENT_CATEGORY":"permission","EVENT_TYPE":"permission_status","PROCESS_NAME":"demo-helper","PID":"2345","PARENT_PID":"1","ACTION":"permission_unknown","TARGET":"Full Disk Access","TARGET_TYPE":"permission","SOURCE":"permission_sensor","RAW_SOURCE":"tcc_readonly_check","RAW_LINE":"permission check reference","CONFIDENCE":"50","TAGS":"macos,permission,tcc","PERMISSION_NAME":"Full Disk Access","PERMISSION_SCOPE":"system","PERMISSION_STATUS":"unknown","BUNDLE_ID":""}
```

## Non-goals

This RFC does not:

- Define malicious behavior verdicts.
- Define automated remediation or response actions.
- Require all platforms to be implemented at once.
- Require Windows or Linux Sensors in V2.
- Collect unrelated personal content.
- Upload events automatically.
- Replace raw evidence storage.
- Define final report templates.
- Define the complete Rule file format.

## Migration From V1.1

V1.1 writes platform-specific logs directly into the run directory.

Relevant V1.1 logs:

- `process.log`
- `network.log`
- `fs_usage.log`
- `launchctl.log`

V2 should gradually convert these raw logs into Normalized Events.

Migration mapping:

| V1.1 raw log | V2 normalized output |
| --- | --- |
| `process.log` | `events/process_events.jsonl` |
| `network.log` | `events/network_events.jsonl` |
| `fs_usage.log` | `events/file_events.jsonl` |
| `launchctl.log` | `events/service_events.jsonl` |
| system context logs | `events/system_events.jsonl` |
| permission checks | `events/permission_events.jsonl` |

Recommended migration steps:

1. Keep V1.1 raw logs as baseline evidence.
2. Add a normalization step that reads raw logs and emits category-specific event files.
3. Add `events/all_events.jsonl` as a merged stream for timeline and correlation analysis.
4. Update Rule Engine design to consume Normalized Events instead of raw logs.
5. Update Analyzer to build timeline and risk summary from Findings backed by Normalized Events.
6. Update Reporter to cite event IDs and raw evidence references.

The migration should preserve read-only behavior and should not require Python, Homebrew, or third-party dependencies in V2.
