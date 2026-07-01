# SDMon Examples

This directory contains small, safe examples for SDMon V2 Alpha Preview.

The examples are designed to help a new developer run SDMon quickly and write a first Rule without changing runtime code.

## 5-Minute Trial

```bash
git clone https://github.com/chyin1006/SDMon.git
cd SDMon
bash sdmon-v2.sh version
bash sdmon-v2.sh help
bash sdmon-v2.sh run --output /tmp/sdmon-v2-test
open /tmp/sdmon-v2-test/reports/report.html
```

## First Rule

Copy the example Rule into `rules_v2/`:

```bash
cp examples/rules/first_process_rule.conf rules_v2/my_first_rule.conf
bash sdmon-v2.sh run --output /tmp/sdmon-v2-rule-test
open /tmp/sdmon-v2-rule-test/reports/report.html
```

## Rule Safety

Rules are local data files. They should describe behavior to review.

Rules must not:

- Execute commands.
- Stop or unload Agents.
- Delete, quarantine, or modify files.
- Change system settings.
- Upload data.
- Bypass security tools.

## Current Alpha Rule Fields

The current Alpha runtime recognizes these fields:

```text
RULE_ID
RULE_EVENT_CATEGORY
RULE_PROCESS_NAME
RULE_ACTION
RULE_TARGET
RULE_SEVERITY
RULE_CONFIDENCE
RULE_MESSAGE
```

See `examples/rules/first_process_rule.conf` for a minimal working example.
