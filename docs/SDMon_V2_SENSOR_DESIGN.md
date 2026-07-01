# SDMon V2 Sensor Design

This document defines the SDMon V2 Sensor collection layer at the framework design level. It does not define concrete Shell implementation details and does not change the V1.1 baseline.

## 1. Sensor Goals

The Sensor layer is responsible for collecting raw behavior data from the target platform.

Primary goals:

- Collect raw behavior evidence in a read-only way.
- Implement macOS Sensors first for V2.
- Keep Windows and Linux Sensor concepts as future extension design only.
- Avoid risk judgment inside Sensors.
- Avoid final report generation inside Sensors.
- Convert raw platform observations into normalized events for later layers.
- Preserve raw evidence so administrators can review what was observed.
- Keep collection scoped to the active Profile.

A Sensor observes activity. It does not decide whether an observed behavior is good, bad, suspicious, malicious, or acceptable.

## 2. Sensor Position In The Framework

The Sensor layer sits after Profile selection and before Rule Engine analysis.

Framework data flow:

```text
Profile
  ↓
Sensor
  ↓
Raw Event
  ↓
Normalized Event
  ↓
Rule Engine
  ↓
Analyzer
  ↓
Reporter
```

Layer responsibilities:

- Profile defines the target scope.
- Sensor collects platform evidence.
- Raw Event preserves original observations.
- Normalized Event provides a consistent event shape.
- Rule Engine evaluates normalized events against behavior rules.
- Analyzer aggregates Findings, timelines, scores, and explanations.
- Reporter renders final output artifacts.

Sensors are collection components. They should remain independent from rule judgment, analysis scoring, and report presentation.

## 3. V2 macOS Sensor Types

V2 should implement macOS Sensors first.

Recommended macOS Sensor types:

- process sensor
- file sensor
- network sensor
- launchd sensor
- system sensor
- permission sensor

Windows and Linux can later introduce equivalent platform-specific Sensors while preserving the same normalized event contract.

## 4. Sensor Responsibilities

Each Sensor should have one primary collection responsibility.

### process sensor

The process sensor observes target process state.

Responsibilities:

- Collect target process presence.
- Record PID values.
- Record startup or running state when observable.
- Record parent and child process relationships when available.
- Output normalized process events.

Example observed concepts:

- target process running
- target process not running
- process parent PID
- process command metadata

### file sensor

The file sensor observes file access behavior related to the active Profile.

Responsibilities:

- Collect file access behavior.
- Use macOS built-in mechanisms such as `fs_usage` in V2, with future design room for EndpointSecurity.
- Focus on Profile-defined paths and sensitive path categories.
- Preserve raw file access lines.
- Output normalized file events.

Example observed concepts:

- file read
- file write metadata when observable
- path access
- sensitive path touch

The file sensor does not decide whether a path access is risky. It only records the observation.

### network sensor

The network sensor observes network activity related to the active Profile.

Responsibilities:

- Collect `lsof`, `tcpdump`, and `netstat` related information where appropriate.
- Record target connections.
- Record endpoints.
- Preserve packet capture artifacts when packet capture is enabled and permitted.
- Output normalized network events.

Example observed concepts:

- process endpoint connection
- local address
- remote address
- remote port
- pcap reference

The network sensor does not classify a destination as safe or unsafe.

### launchd sensor

The launchd sensor observes macOS startup and persistence configuration.

Responsibilities:

- Collect LaunchDaemon and LaunchAgent metadata.
- Record plist paths.
- Record service labels.
- Record service state when available.
- Output normalized launchd events.

Example observed concepts:

- LaunchDaemon exists
- LaunchAgent exists
- service loaded state
- plist path

The launchd sensor only observes configuration. It must not unload, disable, modify, or delete services.

### system sensor

The system sensor records system context for the collection run.

Responsibilities:

- Collect macOS version.
- Collect hostname.
- Collect current user context.
- Collect network interface metadata.
- Output normalized system events.

Example observed concepts:

- operating system version
- hardware or host identity metadata
- active user name
- network interface list

System metadata helps administrators interpret findings and reproduce the collection context.

### permission sensor

The permission sensor observes macOS permission and privacy-related state in a read-only way.

Responsibilities:

- Collect TCC-related status where readable.
- Collect PPPC-related status where readable.
- Collect permission metadata relevant to the active Profile.
- Perform read-only checks only.
- Output normalized permission events.

Example observed concepts:

- readable TCC database reference
- permission category metadata
- profile-related privacy permission state

The permission sensor must not modify TCC, PPPC, privacy databases, profiles, or security settings.

## 5. Sensor Lifecycle

Each Sensor should follow a predictable lifecycle.

Recommended lifecycle:

1. discover
2. configure
3. start
4. collect
5. stop
6. normalize
7. output
8. cleanup

### discover

Identify whether the Sensor can run on the current system and whether required built-in tools are available.

### configure

Load Profile scope, config settings, output paths, language settings, and any relevant Rule context.

### start

Start collection for Sensors that require a collection window.

### collect

Capture raw observations during the run.

### stop

Stop collection activity owned by the Sensor.

### normalize

Convert raw observations into normalized event records.

### output

Write raw logs, normalized events, and Sensor status.

### cleanup

Release temporary files or runtime state created by the Sensor, without touching target software.

## 6. Sensor Input

Sensor input should be explicit and traceable.

Inputs include:

- Profile
- `config.conf`
- Rule context
- output directory
- `REPORT_LANG`

Input responsibilities:

- Profile defines what the Sensor should pay attention to.
- `config.conf` defines runtime behavior and collection options.
- Rule context can describe which event fields are useful for later matching.
- output directory defines where raw and normalized artifacts should be written.
- `REPORT_LANG` is passed through as run context but does not change collection logic.

Sensors should not require hard-coded target names in framework code.

## 7. Sensor Output

Sensors should output both raw logs and normalized events.

Raw logs preserve original collection evidence.

Recommended raw log files:

- `process.log`
- `file.log`
- `network.log`
- `launchd.log`
- `system.log`
- `permission.log`

Normalized events provide a stable interface for the Rule Engine.

Recommended normalized event files:

- `events/process_events.jsonl`
- `events/file_events.jsonl`
- `events/network_events.jsonl`
- `events/launchd_events.jsonl`
- `events/system_events.jsonl`
- `events/permission_events.jsonl`

Each line in a normalized event file should represent one event record.

The raw log format may remain platform-specific. The normalized event format should remain framework-oriented.

## 8. Normalized Event Design

A Normalized Event is the contract between Sensors and the Rule Engine.

Minimum fields:

| Field | Purpose |
| --- | --- |
| `EVENT_ID` | Stable event identifier within a run. |
| `TIMESTAMP` | Event time or observation time. |
| `SENSOR_TYPE` | Sensor that produced the event. |
| `PROFILE_ID` | Active Profile identifier. |
| `PROCESS_NAME` | Related process name when available. |
| `PID` | Related process ID when available. |
| `ACTION` | Observed action, such as read, connect, exists, running, or loaded. |
| `TARGET` | File path, endpoint, service label, interface, or other observed target. |
| `SOURCE` | Source tool or collection source. |
| `RAW_LINE` | Original raw evidence line or reference. |
| `CONFIDENCE` | Collection confidence for this event. |

Design notes:

- Missing platform fields should be empty rather than invented.
- `RAW_LINE` may be a raw text value or a reference to a raw log line.
- `CONFIDENCE` describes collection reliability, not behavior severity.
- The event schema should stay stable even when Sensor internals change.

## 9. Sensor And Profile Relationship

Profile and Sensor responsibilities must remain separate.

Profile responsibilities:

- Tell Sensors which processes to observe.
- Tell Sensors which paths to check.
- Tell Sensors which services to inspect.
- Tell Sensors which endpoints are relevant.
- Provide target metadata and language preferences.

Sensor responsibilities:

- Collect observations for the requested scope.
- Preserve raw evidence.
- Normalize observations.
- Report Sensor status.

Important boundaries:

- Profile does not collect data.
- Sensor does not hard-code a specific Agent.
- Sensor can run with a default Profile when no custom Profile is selected.
- Profile-specific values should be data, not framework logic.

This separation allows the same macOS Sensors to support MDM, EDR, VPN, Zero Trust, AI Agent, Enterprise Agent, and Custom Agent Profiles.

## 10. Sensor And Rule Engine Relationship

Sensors produce evidence. Rules interpret evidence.

Sensor responsibilities:

- Collect raw events.
- Produce normalized events.
- Preserve status and errors.

Rule Engine responsibilities:

- Consume normalized events.
- Apply behavior rules.
- Generate Findings.

Important boundaries:

- Sensor does not judge risk.
- Sensor does not assign final severity.
- Sensor does not generate Findings.
- Sensor only outputs normalized events for later layers.
- Rule Engine should not depend on a specific raw tool format when normalized events are available.

For example, a file sensor may observe access to a Keychain-related path. The file sensor records the event. A Rule decides whether that event matches a sensitive file access rule.

## 11. macOS Tool Choice

V2 should prioritize macOS built-in tools.

Preferred built-in tools:

- `ps`
- `pgrep`
- `lsof`
- `tcpdump`
- `fs_usage`
- `launchctl`
- `defaults`
- `system_profiler`
- `scutil`

Tool selection principles:

- Prefer tools available by default on macOS.
- Preserve read-only behavior.
- Capture enough evidence for analysis without modifying target software.
- Make permission requirements clear before collection.
- Keep Sensor output stable even if raw tool output varies.

V2 should not use:

- Python
- Homebrew
- third-party dependencies

Future versions may introduce optional platform-specific collectors, but V2 should remain simple and dependency-light.

## 12. Permission Strategy

Sensors must respect macOS permission and privacy boundaries.

Permission strategy:

- Sensors that require `sudo` must clearly tell the user before running.
- SDMon must not perform silent privilege escalation.
- SDMon must not bypass system permissions.
- SDMon must not modify TCC or PPPC settings.
- SDMon must not close, disable, or weaken security settings.
- SDMon must continue collecting what it can when a permission is unavailable.
- Reports should show when missing permissions limited collection.

Permission failures are collection limitations, not reasons to alter the system.

## 13. Sensor Error Handling

Sensor failure should be isolated and visible.

Error handling principles:

- A single Sensor failure should not crash the entire SDMon run.
- Every Sensor must output a status record.
- Errors should be written to `sensor_status.json`.
- Reporter should show collection failure reasons.
- Partial collection should remain usable when other Sensors succeed.
- Permission-denied errors should be recorded clearly.
- Missing-tool errors should be recorded clearly.
- Empty results should be distinguishable from failed collection.

Recommended status concepts:

- Sensor name
- status
- start time
- end time
- raw output path
- normalized event path
- error code
- error message
- permission requirement
- collection limitations

This makes reports more honest and helps administrators understand evidence gaps.

## 14. V2 Does Not Do

V2 Sensor design intentionally excludes several behaviors.

V2 does not:

- Implement Windows Sensors.
- Implement Linux Sensors.
- Run as a background resident service.
- Perform hidden collection.
- Bypass security software.
- Modify the target Agent.
- Stop the target Agent.
- Unload LaunchDaemons or LaunchAgents.
- Change TCC, PPPC, privacy, or security settings.
- Collect personal content unrelated to the active Profile.
- Upload collected data automatically.
- Perform automated remediation.

SDMon V2 remains a read-only Agent behavior analysis framework.

## 15. V1.1 To V2 Migration

V1.1 should remain available as the baseline while V2 introduces a clearer Sensor layer.

The functionality currently concentrated in `bin/monitor.sh` should be gradually split into macOS Sensor components.

Recommended migration mapping:

| V1.1 source | V2 target |
| --- | --- |
| `bin/monitor.sh` process checks | `sensors/macos/process_sensor.sh` |
| `bin/monitor.sh` file monitoring | `sensors/macos/file_sensor.sh` |
| `bin/monitor.sh` network monitoring | `sensors/macos/network_sensor.sh` |
| `bin/monitor.sh` launchd checks | `sensors/macos/launchd_sensor.sh` |
| `bin/monitor.sh` system collection | `sensors/macos/system_sensor.sh` |

Migration principles:

- Keep V1.1 command files in place during the transition.
- Add V2 Sensor structure without moving existing V1.1 files at first.
- Preserve read-only behavior.
- Keep Profile-driven targeting instead of hard-coded target values.
- Keep raw logs and normalized events separate.
- Move risk interpretation into Rule Engine and Analyzer layers.
- Update README only after the V2 structure becomes runnable and testable.

The first V2 Sensor milestone should focus on macOS process, file, network, launchd, and system Sensors. Permission Sensor support can be introduced as a read-only extension once the baseline event contract is stable.
