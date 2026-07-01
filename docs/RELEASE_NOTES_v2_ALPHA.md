# SDMon V2 Alpha Preview Release Notes

## Status

SDMon V2 Alpha Preview is an early release candidate for macOS local Agent behavior analysis.

It is not a stable release and should be used for evaluation, testing, and framework feedback.

## Core Value

One command to collect local agent behavior signals and generate a local HTML/JSON/CSV report.

## Supported Platform

- macOS: supported in V2 Alpha Preview.
- Windows: planned, not implemented.
- Linux: planned, not implemented.

## Included Capabilities

- CLI wrapper: `sdmon-v2.sh`.
- End-to-end V2 Alpha pipeline: `v2_alpha.sh`.
- Event Layer with JSONL event output.
- Demo Producers.
- Rule Runtime with local `.conf` demo Rules.
- Analyzer output.
- HTML, JSON, and CSV reports.
- macOS Sensors for process, file, launchd, network, system, and permission signals.
- Examples for writing a first Rule.

## Quick Start

```bash
git clone https://github.com/chyin1006/SDMon.git
cd SDMon
bash sdmon-v2.sh version
bash sdmon-v2.sh help
bash sdmon-v2.sh run --output /tmp/sdmon-v2-test
open /tmp/sdmon-v2-test/reports/report.html
```

## Reports

The default run creates:

```text
reports/report.html
reports/report.json
reports/report.csv
```

## Safety Boundaries

SDMon V2 Alpha Preview:

- Uses read-only local collection.
- Does not upload data.
- Does not use `sudo` in the V2 Alpha path.
- Does not modify target Agents.
- Does not change system settings.
- Does not replace EDR, MDM, VPN, or security operations platforms.

## Known Limitations

- macOS only in Alpha Preview.
- Demo Rules are intentionally simple.
- Rule matching is minimal and intended for Alpha validation.
- Reports are local preview artifacts.
- No background service mode.
- No Windows or Linux Sensors yet.

## First Rule

See:

```text
examples/README.md
examples/rules/first_process_rule.conf
```

## Upgrade Notes

V1.1 remains available as a legacy validation path. V2 Alpha Preview does not modify or replace V1.1 command entry points.
