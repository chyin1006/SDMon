# SDMon V2 Reporter

Reporter is the V2 Alpha rendering layer after Analyzer.

It reads Analyzer JSON and writes local report artifacts:

- `report.json`
- `report.html`
- `report.csv`

Reporter does not analyze data, collect evidence, modify rules, modify profiles, upload reports, or change target software.

## Usage

```bash
bash reporters/reporter.sh --input /tmp/sdmon/analysis.json --output-dir /tmp/sdmon/reports
```

The HTML report is static and uses `templates/report.html`.

## Boundaries

Reporter must remain Bash-only and dependency-free for V2 Alpha. It must not use Python, jq, Homebrew, remote assets, or third-party tools.
