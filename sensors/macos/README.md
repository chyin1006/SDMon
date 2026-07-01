# SDMon V2 macOS Sensors

This directory contains V2 Alpha macOS sensors.

The first sensor is `process_sensor.sh`. It reads the current macOS process table with built-in tools, normalizes each observed process into a process event, and writes JSONL through `events/event_writer.sh`.

## Process Sensor

```bash
bash sensors/macos/process_sensor.sh --output /tmp/sdmon/events/process_events.jsonl
```

Optional:

```bash
bash sensors/macos/process_sensor.sh --output /tmp/sdmon/events/process_events.jsonl --profile default --limit 1
```

## Boundaries

Sensors collect, normalize, and write events only.

They do not analyze behavior, calculate risk, call rules, render reports, modify target software, stop processes, unload services, or change system settings.
