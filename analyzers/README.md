# SDMon V2 Analyzer

Analyzer is the V2 Alpha layer after Rule Runtime.

It reads Rule Runtime JSON, derives a small behavior summary, builds a minimal timeline entry, calculates confidence and risk score, and emits Analysis JSON for later Reporter work.

Analyzer does not collect system data, run sensors, modify rules, render final reports, upload results, or change target software.

## Usage

```bash
bash analyzers/analyzer.sh --input /tmp/sdmon/rule_result.jsonl --output /tmp/sdmon/analysis.json
```

The output contains:

- `RISK_SCORE`
- `SEVERITY`
- `CONFIDENCE`
- `SUMMARY`
- `TIMELINE`
- `MATCHED_RULE`

## Boundaries

Analyzer must remain Bash-only and dependency-free for V2 Alpha. It must not use Python, jq, Homebrew, or third-party tools.
