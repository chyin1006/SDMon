# SDMon V2 Event Layer

The Event Layer is the first V2 Alpha building block for normalized evidence output.

It provides a small Bash-only writer that converts supplied event fields into JSONL records. It does not collect system data, run Sensors, apply Rules, analyze behavior, or generate reports.

## Purpose

The Event Layer exists to:

- Provide a stable Normalized Event output format.
- Give future Sensors a common way to write event records.
- Keep Rule Engine input independent from raw macOS tool output.
- Preserve the read-only architecture defined by SDMon V2.
- Stay Bash friendly and avoid Python, Homebrew, or third-party dependencies.

## Files

- `event_schema.conf`: Defines the Normalized Event field list and required fields.
- `event_types.conf`: Defines the base event categories.
- `event_writer.sh`: Appends one JSONL event to a specified output file.

## Usage

```bash
bash events/event_writer.sh --output /tmp/sdmon_events/process_events.jsonl \
  EVENT_ID="evt-000001" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-06-29T10:00:00Z" \
  HOSTNAME="example-host" \
  USER_NAME="root" \
  PLATFORM="macos" \
  SENSOR_TYPE="process" \
  PROFILE_ID="default" \
  EVENT_CATEGORY="process" \
  EVENT_TYPE="process_state" \
  PROCESS_NAME="example-agent" \
  PID="1234" \
  ACTION="running" \
  TARGET="example-agent" \
  TARGET_TYPE="process" \
  SOURCE="test" \
  CONFIDENCE="90" \
  TAGS="test,process"
```

The writer creates the output directory when needed and appends exactly one JSON object per line.

## Output Format

Output is JSONL:

```json
{"EVENT_ID":"evt-000001","EVENT_VERSION":"1","EVENT_CATEGORY":"process"}
```

Each line is one Normalized Event record.

## Relationship To Sensors

Sensors should collect raw evidence and pass normalized fields to `event_writer.sh`.

The Event Layer does not:

- Collect process data.
- Read file activity.
- Inspect network connections.
- Query launchd.
- Check permissions.
- Modify target software.

## Relationship To Rule Engine

The Rule Engine should consume JSONL Normalized Events instead of raw tool output.

This keeps Rules independent from `ps`, `lsof`, `tcpdump`, `fs_usage`, `launchctl`, or future Windows and Linux raw sources.

## Safety

The Event Layer is write-only for event files. It does not execute remediation, unload services, stop Agents, change permissions, upload events, or collect unrelated personal content.
