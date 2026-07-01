# SDMon V2 Alpha Usage

## 1. V2 Alpha Current Status

SDMon V2 Alpha Preview is an early runnable framework preview for macOS.

This is a release candidate for the Alpha Preview experience. It is not a stable release.

It provides a minimal end-to-end local pipeline for collecting macOS events, matching demo rules, analyzing results, and generating reports.

One command to collect local agent behavior signals and generate a local HTML/JSON/CSV report.

V2 Alpha is not a replacement for V1.1. V1.1 files and command entry points remain unchanged.

## 2. Quick Start

Run SDMon V2 Alpha Preview in about 5 minutes:

```bash
git clone https://github.com/chyin1006/SDMon.git
cd SDMon
./sdmon-v2.sh
```

The command runs the full scan, generates reports, and opens the HTML report automatically on macOS.

Expected report files:

```text
output/report.html
output/report.json
output/report.csv
output/summary.txt
output/timeline.json
output/events.json
```

## 3. Supported Platform

Current support:

- macOS

Windows and Linux are planned for future versions, but they are not implemented in V2 Alpha.

## 4. Current Capabilities

V2 Alpha currently includes:

- Event Layer
- Producer
- Rule Runtime
- Analyzer
- Reporter
- macOS Sensors
- CLI Wrapper

## 5. Output Directory

The default output directory is:

```text
output/
```

User-facing report files:

- `output/report.html`
- `output/report.json`
- `output/report.csv`
- `output/summary.txt`
- `output/timeline.json`
- `output/events.json`

Internal pipeline artifacts may also be kept under the selected output directory for troubleshooting.

## 6. Open HTML Report

On macOS, SDMon automatically opens the generated HTML report:

```text
output/report.html
```

You can still open it manually if needed:

```bash
open output/report.html
```

## 7. Write Your First Rule

V2 Alpha rules live in `rules_v2/` and use Bash-friendly `.conf` files.

Start from the example rule:

```bash
cp examples/rules/first_process_rule.conf rules_v2/my_first_rule.conf
./sdmon-v2.sh
```

Minimal Alpha-compatible rule fields:

```conf
RULE_ID="example_process_start"
RULE_EVENT_CATEGORY="process"
RULE_PROCESS_NAME="test-process"
RULE_ACTION="start"
RULE_TARGET="test-process"
RULE_SEVERITY="info"
RULE_CONFIDENCE="50"
RULE_MESSAGE="Example process start event matched."
```

Rule safety rules:

- Rules are data, not executable scripts.
- Rules should explain behavior for review.
- Rules must not stop, unload, delete, quarantine, bypass, or upload anything.
- Rules must not modify Agents or system settings.

See `examples/README.md` for more detail.

## 8. Current Limitations

V2 Alpha limitations:

- Alpha stage.
- Does not capture packets.
- Does not modify the system.
- Does not modify target Agents.
- Does not replace EDR, MDM, or VPN products.

## 9. Safety Notes

V2 Alpha is designed for local, read-only monitoring:

- Read-only collection.
- Local output only.
- No data upload.
- No automatic remediation.

## 10. Test Commands

Run the V2 Alpha pipeline test:

```bash
bash tests/test_v2_alpha_pipeline.sh
```

Run the V2 CLI test:

```bash
bash tests/test_sdmon_v2_cli.sh
```

## 11. Next Steps

Planned next steps:

- End-to-end release candidate validation.
- Report optimization.
- Rule example expansion.
- Real macOS target Profile support for Sensors.
