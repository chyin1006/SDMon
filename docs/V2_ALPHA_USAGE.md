# SDMon V2 RC1 Usage

## 1. V2 RC1 Current Status

SDMon V2 RC1 Public Preview is a runnable macOS-first endpoint security assessment toolkit.

This is a public preview release designed for evaluation. It is not a stable enterprise deployment release.

It provides a local, read-only pipeline for collecting macOS endpoint signals, matching rules, analyzing results, and generating enterprise-style reports.

One command collects local endpoint security signals and generates local HTML, PDF, ZIP, JSON, CSV, and text reports.

The public `v2.0.0-rc1` release currently supports macOS. Windows support is under Beta development in a separate branch and pull request, and is not part of RC1 yet.

## 2. Before You Start

If you use `git clone` on a fresh Mac, macOS may ask you to install Apple Command Line Tools first:

```bash
xcode-select --install
```

After installation, verify Git is available:

```bash
git --version
```

The one-command macOS runner below uses GitHub ZIP download mode by default and does not require Git.

## 3. Quick Start

Run SDMon V2 RC1 Public Preview in about 5 minutes.

### Option 1: One-command macOS Runner

Use this option for a fresh Mac when you want to avoid `git clone` and Apple Command Line Tools setup.

```bash
curl -fsSL https://raw.githubusercontent.com/chyin1006/SDMon/main/scripts/run-sdmon-macos.sh -o run-sdmon-macos.sh
chmod +x run-sdmon-macos.sh
./run-sdmon-macos.sh
```

The runner downloads the current SDMon ZIP archive, extracts it to a temporary directory, runs `sdmon-v2.sh`, and prints generated report paths.

Optional Git mode:

```bash
./run-sdmon-macos.sh --git
```

Git mode requires Git. On a fresh Mac, install Apple Command Line Tools first with `xcode-select --install`.

### Option 2: Run With Git

```bash
git clone https://github.com/chyin1006/SDMon.git
cd SDMon
chmod +x sdmon-v2.sh
./sdmon-v2.sh
```

### Option 3: Run From GitHub ZIP

Use this option if Git is not installed yet.

1. Open the SDMon GitHub page.
2. Select **Code** -> **Download ZIP**.
3. Extract the ZIP file.
4. Open Terminal in the extracted folder.
5. Run:

```bash
chmod +x sdmon-v2.sh
./sdmon-v2.sh
```

The command runs the full scan, generates reports, and opens the HTML report automatically on macOS.

Expected report files:

```text
output/report.html
output/report.pdf
output/report.zip
output/report.json
output/report.csv
output/summary.txt
output/timeline.json
output/events.json
```

## 4. Supported Platform

Current support:

- macOS

Windows and Linux are planned for future versions. Windows Beta work is being developed separately and is not included in `v2.0.0-rc1`.

## 5. Current Capabilities

V2 RC1 currently includes:

- Event Layer
- Producer
- Rule Runtime
- Analyzer
- Reporter
- macOS Sensors
- CLI Wrapper

## 6. Output Directory

The default output directory is:

```text
output/
```

User-facing report files:

- `output/report.html`
- `output/report.pdf`
- `output/report.zip`
- `output/report.json`
- `output/report.csv`
- `output/summary.txt`
- `output/timeline.json`
- `output/events.json`

Internal pipeline artifacts may also be kept under the selected output directory for troubleshooting.

## 7. Open HTML Report

On macOS, SDMon automatically opens the generated HTML report:

```text
output/report.html
```

You can still open it manually if needed:

```bash
open output/report.html
```

## 8. Write Your First Rule

V2 RC1 rules live in `rules_v2/` and use Bash-friendly `.conf` files.

Start from the example rule:

```bash
cp examples/rules/first_process_rule.conf rules_v2/my_first_rule.conf
./sdmon-v2.sh
```

Minimal RC1-compatible rule fields:

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

## 9. Current Limitations

V2 RC1 limitations:

- Public preview stage.
- Does not capture packets.
- Does not modify the system.
- Does not modify target Agents.
- Does not replace EDR, MDM, or VPN products.

## 10. Safety Notes

V2 RC1 is designed for local, read-only assessment:

- Read-only collection.
- Local output only.
- No data upload.
- No automatic remediation.

## 11. Test Commands

Run the V2 pipeline test:

```bash
bash tests/test_v2_alpha_pipeline.sh
```

Run the V2 CLI test:

```bash
bash tests/test_sdmon_v2_cli.sh
```

## 12. Next Steps

Planned next steps:

- End-to-end release candidate validation.
- Report optimization.
- Rule example expansion.
- Real macOS target Profile support for Sensors.
