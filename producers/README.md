# SDMon V2 Event Producers

Event Producers are V2 Alpha adapters between simulated raw input and the Event Layer.

They do not analyze events, score risk, render reports, or collect real system data. Their only responsibility is to turn raw input into RFC-0001-style Normalized Events and call `events/event_writer.sh`.

## Producers

- `process_producer.sh`: Emits one simulated process event.
- `file_producer.sh`: Emits one simulated file event.
- `network_producer.sh`: Emits one simulated network event.

## Usage

```bash
bash producers/process_producer.sh --output /tmp/sdmon/events/process_events.jsonl
bash producers/file_producer.sh --output /tmp/sdmon/events/file_events.jsonl
bash producers/network_producer.sh --output /tmp/sdmon/events/network_events.jsonl
```

Each producer appends one JSONL event through `events/event_writer.sh`.

## Boundaries

Producers must not:

- Collect real system data.
- Analyze risk.
- Generate reports.
- Modify files outside the selected event output.
- Stop, unload, modify, or interact with target software.
- Depend on Python, jq, Homebrew, or third-party tools.
