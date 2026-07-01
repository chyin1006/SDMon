# SDMon V2 Rule Runtime

Rule Runtime is the V2 Alpha path from Event JSONL to Rule Result JSON.

Flow:

```text
Producer
  ↓
Event(JSONL)
  ↓
Rule Loader
  ↓
Rule Matcher
  ↓
Rule Result
```

The runtime is intentionally small. It does not collect system data, analyze final risk, generate reports, or modify target software.

## Files

- `rule_loader.sh`: Loads `rules_v2/*.conf` rule files.
- `rule_matcher.sh`: Matches one event JSON object against one loaded rule record.
- `rule_result.sh`: Emits a JSON rule result.
- `rule_runtime.sh`: Runs loader, matcher, and result output for event input.

## Boundaries

Rule Runtime must remain Bash-only and must not depend on Python, jq, Homebrew, or third-party tools.
