# SDMon V2 Event Schema Freeze

This document defines the P0 Freeze rules for the SDMon V2 Event Schema.

It freezes the minimum Beta contract for JSONL Normalized Events. It does not introduce JSON Schema tooling, database requirements, or non-Bash dependencies.

## 1. Event Schema Freeze Goal

The goal is to freeze the smallest stable event contract needed for V2 Beta.

Freeze goals:

- Keep the event format Bash-only friendly.
- Keep one event per JSONL line.
- Keep Sensors independent from Rule Runtime, Analyzer, and Reporter internals.
- Keep Rule Runtime independent from raw macOS tool output.
- Keep Analyzer and Reporter inputs stable enough for Beta.
- Avoid over-designing Windows/Linux fields before macOS Beta is stable.

The freeze is a minimum contract, not a complete final schema for every future platform.

## 2. Event As The Only Data Contract

The Normalized Event is the only data contract between these layers:

```text
Sensor
  -> Rule Runtime
  -> Analyzer
  -> Reporter
```

Contract rules:

- Sensors write Normalized Events.
- Rule Runtime consumes Normalized Events.
- Analyzer consumes Rule Runtime output and may reference source events.
- Reporter consumes Analyzer output and may display event-derived fields.
- Downstream layers must not depend on raw `ps`, `lsof`, `launchctl`, `sw_vers`, `profiles`, or other tool output when a Normalized Event is available.
- Raw logs may exist for evidence, but they are not the framework contract.

## 3. Required Fields

The V2 Beta minimum required fields are:

```text
EVENT_ID
EVENT_VERSION
TIMESTAMP
PLATFORM
SENSOR_TYPE
PROFILE_ID
EVENT_CATEGORY
EVENT_TYPE
ACTION
TARGET
TARGET_TYPE
SOURCE
CONFIDENCE
```

Required field rules:

- Required fields must be present in every event.
- Required fields must not be omitted from `events/event_schema.conf`.
- A required field may use a safe fallback value only when the Sensor cannot know the value.
- Missing required fields should fail event writing.
- Required fields should stay stable through Beta.

Recommended safe fallback examples:

```text
PROFILE_ID="default"
TARGET="unknown"
TARGET_TYPE="unknown"
CONFIDENCE="0"
```

## 4. Optional Fields

The current optional fields are:

```text
HOSTNAME
USER_NAME
PROCESS_NAME
PID
TAGS
SERVICE_TYPE
PLIST_PATH
LABEL
PROTOCOL
LOCAL_ADDRESS
LOCAL_PORT
REMOTE_ADDRESS
REMOTE_PORT
COMPUTER_NAME
OS_NAME
OS_VERSION
OS_BUILD
KERNEL
ARCH
PERMISSION_TYPE
STATUS
DETAIL
```

Optional field rules:

- Optional fields may be empty.
- Optional fields should remain present in the JSON object when defined in `events/event_schema.conf`.
- Sensors should not invent values for unknown optional fields.
- Platform-specific optional fields may be added before Beta if they are needed by current macOS Sensors.
- Beta additions should prefer small flat fields over nested structures.

## 5. Forbidden Fields

Forbidden fields are fields that would violate SDMon's read-only and local-first model.

Forbidden field types:

- Secrets, tokens, passwords, private keys, or credential material.
- Full unrelated personal content.
- Raw file contents.
- Remote upload destinations for automatic submission.
- Remediation instructions.
- Commands to execute.
- Fields that imply a final malware verdict.
- Fields that instruct SDMon to stop, unload, quarantine, delete, or modify a target Agent.

Forbidden examples:

```text
PASSWORD
TOKEN
PRIVATE_KEY
FILE_CONTENT
EXEC_COMMAND
REMEDIATION_COMMAND
AUTO_UPLOAD_URL
MALWARE_VERDICT
KILL_PROCESS
DELETE_PATH
```

Events describe observations only. They must not become action objects.

## 6. Field Naming Rules

Field naming is frozen as uppercase snake case.

Rules:

- Use only `A-Z`, `0-9`, and `_`.
- Start field names with a letter.
- Use stable names once added.
- Prefer generic names over vendor-specific names.
- Do not encode platform names into generic fields unless the field is explicitly platform-specific.
- Do not rename required fields during Beta.

Good examples:

```text
EVENT_CATEGORY
REMOTE_ADDRESS
PERMISSION_TYPE
OS_VERSION
```

Bad examples:

```text
eventCategory
remote-address
VendorAgentPath
macOSOnlyRiskDecision
```

## 7. Time Field Rules

The frozen time field is:

```text
TIMESTAMP
```

Time rules:

- `TIMESTAMP` should use UTC when possible.
- Recommended format is ISO-like UTC text:

```text
YYYY-MM-DDTHH:MM:SSZ
```

- Sensors should use the observation time when exact event time is unavailable.
- Do not add multiple competing primary time fields for Beta.
- Future fields such as `FIRST_SEEN` and `LAST_SEEN` belong in Analyzer/Finding output unless a Sensor truly observes them.

`EVENT_TIME` may appear in user-facing requirements, but the frozen schema field is `TIMESTAMP`.

## 8. Risk And Severity Field Rules

Events do not carry final risk or severity.

Frozen rule:

- Event fields may include `CONFIDENCE`.
- Event fields must not include final `RISK_SCORE`, `RISK_LEVEL`, or `SEVERITY` as Sensor output fields.

Reason:

- Sensors observe behavior.
- Rule Runtime identifies matches.
- Analyzer calculates risk and confidence summaries.
- Reporter renders the final result.

Allowed event reliability field:

```text
CONFIDENCE
```

Disallowed Sensor event fields for Beta:

```text
RISK_SCORE
RISK_LEVEL
SEVERITY
MALICIOUS
VERDICT
```

## 9. Category Classification Rules

Frozen Beta event categories are:

```text
process
file
network
service
system
permission
configuration
security
application
```

Category rules:

- `EVENT_CATEGORY` must be one of the frozen categories.
- Categories are lowercase.
- Categories should be broad and behavior-oriented.
- Do not add vendor-specific categories.
- Do not add Windows/Linux-only categories before platform support exists.
- Prefer `service` for cross-platform persistence concepts.
- Use `SENSOR_TYPE` or optional fields for platform-specific detail.

Current macOS `launchd` events should map to:

```text
EVENT_CATEGORY="service"
SERVICE_TYPE="launchd"
```

## 10. Action Naming Rules

`ACTION` describes the observed behavior.

Action rules:

- Use lowercase snake case.
- Use short verbs or verb phrases.
- Describe what was observed, not what SDMon should do.
- Avoid final judgment language.
- Avoid remediation language.

Good examples:

```text
running
found
connection
no_connection
system_info
permission_check
read
write_observed
```

Bad examples:

```text
malicious
safe
kill
quarantine
delete
bypass
```

## 11. macOS First Current Supported Fields

The current macOS-first Beta field set is:

```text
EVENT_ID
EVENT_VERSION
TIMESTAMP
HOSTNAME
USER_NAME
PLATFORM
SENSOR_TYPE
PROFILE_ID
EVENT_CATEGORY
EVENT_TYPE
PROCESS_NAME
PID
ACTION
TARGET
TARGET_TYPE
SOURCE
CONFIDENCE
TAGS
SERVICE_TYPE
PLIST_PATH
LABEL
PROTOCOL
LOCAL_ADDRESS
LOCAL_PORT
REMOTE_ADDRESS
REMOTE_PORT
COMPUTER_NAME
OS_NAME
OS_VERSION
OS_BUILD
KERNEL
ARCH
PERMISSION_TYPE
STATUS
DETAIL
```

This field set covers current macOS Sensors:

- process
- file
- launchd
- network
- system
- permission

The project should freeze this as the current Beta minimum, while allowing small pre-Beta additions listed in Section 15.

## 12. Windows/Linux Future Extension Reserved Fields

Windows/Linux support is not part of the current implementation freeze.

Future extension concepts may include:

```text
PARENT_PID
PROCESS_PATH
COMMAND_LINE
FILE_PATH
FILE_OPERATION
ACCESS_TYPE
DIRECTION
BYTES_SENT
BYTES_RECEIVED
SERVICE_NAME
SERVICE_LABEL
SERVICE_PATH
SERVICE_STATE
UNIT_PATH
RAW_SOURCE
RAW_LINE
```

Extension rules:

- Do not add fields solely for Windows/Linux until platform work starts.
- Do not block macOS Beta waiting for a complete Windows/Linux model.
- Future Windows/Linux Sensors should map into the same event categories where possible.
- Future platform fields must remain optional unless an RFC changes the required field list.

## 13. Schema Compatibility Rules

Compatibility rules for Beta:

- Adding optional fields before Beta is allowed when needed by current macOS flow.
- Removing required fields is not allowed.
- Renaming required fields is not allowed.
- Changing category names is not allowed without RFC.
- Changing JSONL to another default format is not allowed.
- Reordering fields in `event_schema.conf` should be avoided unless needed for readability and tests remain stable.
- Empty optional fields are compatible.
- Unknown fields should be rejected by the current writer unless the schema is updated first.

Compatibility principle:

A Beta consumer should be able to read Alpha/Beta events if it recognizes the required fields and safely ignores optional fields it does not use.

## 14. Breaking Change Rules

Breaking changes after Beta require RFC review.

Breaking changes include:

- Removing a required field.
- Renaming a required field.
- Changing the meaning of a required field.
- Removing or renaming an event category.
- Changing `CONFIDENCE` from evidence reliability to risk severity.
- Replacing JSONL as the default event format.
- Making SQLite or another database mandatory for the default event contract.
- Allowing Sensors to bypass `events/event_writer.sh` without an equivalent contract.

Breaking change process:

1. Draft an RFC.
2. Explain compatibility impact.
3. Define migration behavior.
4. Update tests and docs.
5. Update `events/event_schema.conf` only after acceptance.

## 15. Fields To Sync To events/event_schema.conf Before Beta

The current `events/event_schema.conf` already contains the minimum active macOS Alpha fields.

Before Beta, review whether to add these RFC-aligned optional fields:

```text
PARENT_PID
RAW_SOURCE
RAW_LINE
PROCESS_PATH
COMMAND_LINE
FILE_PATH
FILE_OPERATION
ACCESS_TYPE
DIRECTION
BYTES_SENT
BYTES_RECEIVED
SERVICE_NAME
SERVICE_LABEL
SERVICE_PATH
SERVICE_STATE
```

Sync rules:

- Add only fields needed by current Beta tests, Sensors, Rules, Analyzer, or Reporter.
- Do not add speculative Windows/Linux fields unless they are generic and immediately useful.
- Keep all additions optional unless a separate RFC updates the required field list.
- Keep the schema Bash-friendly as a flat field list.
- Do not introduce JSON Schema tooling for Beta.

## 16. Freeze Conclusion

Conclusion:

- Event Schema can enter P0 Freeze.
- The frozen format remains JSONL.
- The frozen implementation remains Bash-only friendly.
- The frozen scope is the minimum V2 Beta event contract, not a complete final cross-platform schema.
- Small field additions are allowed before Beta when required by current macOS flow.
- After Beta, field changes that affect compatibility must go through RFC.
