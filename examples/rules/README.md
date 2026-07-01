# Rule Examples

This directory contains small SDMon V2 Alpha rule examples.

The examples are intentionally harmless. They exist only to demonstrate the report pipeline and the Rule file format.

## Included Examples

- `first_process_rule.conf`: a minimal process Rule for learning the current Alpha Rule format.

## How To Try

```bash
cp examples/rules/first_process_rule.conf rules_v2/my_first_rule.conf
bash sdmon-v2.sh run --output /tmp/sdmon-v2-rule-test
open /tmp/sdmon-v2-rule-test/reports/report.html
```
