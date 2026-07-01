# SDMon V2 Rule Schema Freeze

This document defines the P0 Freeze rules for the SDMon V2 Rule Schema.

It freezes the Rule file contract. It does not define Runtime implementation, Bash execution details, or the full Rule Engine architecture.

## 1. Rule Schema Freeze Goal

The goal is to freeze a small, auditable, Bash-friendly Rule file schema for V2 Beta.

Freeze goals:

- Keep Rules local and readable.
- Keep Rules as data, not executable behavior.
- Keep Rules independent from specific vendors or target Agents.
- Keep Rules aligned with the frozen Event Schema.
- Keep the Beta format simple enough for Bash-only validation.
- Avoid YAML, JSON Schema, Python, jq, Homebrew, or third-party parsers in the default path.

The frozen Rule Schema is the minimum Beta contract. It is not a final rule language for every future platform or plugin.

## 2. Rule ID Convention

`RULE_ID` is the stable machine identifier for a Rule.

Rules:

- `RULE_ID` is required.
- Use lowercase snake case.
- Use stable, descriptive names.
- Start with the behavior area or category.
- Do not include spaces.
- Do not include vendor names unless the Rule is explicitly vendor-specific and isolated to a Profile or example pack.
- Do not rename a `RULE_ID` after Beta without compatibility handling.

Good examples:

```text
process_target_running
file_sensitive_keychain_access
network_external_connection
service_launchd_found
permission_tcc_status_unknown
```

Current Alpha demo examples remain valid as demo IDs:

```text
process_demo
file_demo
network_demo
```

## 3. Rule Category Convention

Rule category describes the behavior domain.

Frozen Beta categories:

```text
process
file
network
service
permission
configuration
security
application
persistence
privilege
sensitive_path
traffic
correlation
risk
```

Category rules:

- Categories should be lowercase snake case.
- Categories should be behavior-oriented, not product-oriented.
- Categories should map cleanly to Event categories when possible.
- `persistence` may map to `service` events such as launchd observations.
- `sensitive_path` may map to `file` events.
- `traffic` may map to `network` events.
- `correlation` and `risk` are higher-level categories and should not be required for the first Beta Runtime.

Recommended field names:

```text
RULE_CATEGORY
RULE_EVENT_CATEGORY
```

`RULE_EVENT_CATEGORY` selects the event category to match. `RULE_CATEGORY` describes the behavior or risk domain.

## 4. Severity Convention

Severity describes review priority and potential impact.

Frozen severity values:

```text
critical
high
medium
low
info
```

Rules:

- Severity must not be a malware verdict.
- Severity must not instruct remediation.
- Severity should be conservative and evidence-oriented.
- `RULE_SEVERITY` is accepted for Alpha compatibility.
- `RULE_LEVEL` may be used in design documents and future richer rules.
- Beta should standardize on one canonical field before public release.

Recommended compatibility mapping:

```text
RULE_SEVERITY -> RULE_LEVEL
```

Severity meanings:

| Severity | Meaning |
| --- | --- |
| critical | Strong behavior signal with potentially severe impact. |
| high | Important signal requiring administrator review. |
| medium | Meaningful behavior signal with contextual risk. |
| low | Weak, expected, or low-impact signal. |
| info | Informational observation. |

## 5. Risk Score Convention

Risk score is a numeric aid derived from severity, confidence, evidence, Profile context, and correlation.

Recommended score ranges:

| Severity | Score Range |
| --- | --- |
| critical | 90-100 |
| high | 70-89 |
| medium | 40-69 |
| low | 10-39 |
| info | 0-9 |

Rule Schema freeze rules:

- Rule files may define `RULE_WEIGHT` as an optional score influence.
- Rule files may define `RULE_CONFIDENCE` as an optional match confidence hint.
- Rule files should not define final `RISK_SCORE` as a fixed verdict.
- Final risk score belongs to Analyzer output, not the Rule file alone.
- Risk score must not be interpreted as a malicious/benign verdict.

Allowed optional fields:

```text
RULE_WEIGHT
RULE_CONFIDENCE
```

Discouraged Rule fields:

```text
RISK_SCORE
MALWARE_SCORE
VERDICT_SCORE
```

## 6. Match Type Convention

Match type defines how a Rule compares against a Normalized Event.

Frozen Beta match concepts:

```text
equals
contains
prefix
suffix
exists
not_empty
```

Alpha compatibility fields:

```text
RULE_EVENT_CATEGORY
RULE_PROCESS_NAME
RULE_ACTION
RULE_TARGET
```

Recommended Beta fields:

```text
RULE_MATCH_FIELD
RULE_MATCH_TYPE
RULE_MATCH_PATTERN
```

Rules:

- `RULE_MATCH_FIELD` should reference a frozen Event Schema field.
- `RULE_MATCH_PATTERN` should be a safe literal or simple pattern.
- Regex-like behavior should be deferred unless clearly required.
- Match logic should not execute commands.
- Match logic should not require network access.
- Match fields should remain flat and Bash-friendly.

Compatibility rule:

Current Alpha fields may remain during Beta, but new Beta rules should move toward `RULE_MATCH_FIELD`, `RULE_MATCH_TYPE`, and `RULE_MATCH_PATTERN`.

## 7. Rule Action Convention

Rule actions are descriptive recommendations, not executable actions.

Allowed action concepts:

```text
review
investigate
confirm_expected
document_exception
monitor
```

Recommended field:

```text
RULE_RECOMMENDATION
```

Forbidden action concepts:

```text
kill
stop
unload
delete
quarantine
block
bypass
disable_security
modify_tcc
modify_pppc
upload
```

Rules:

- Rule files must not contain executable remediation actions.
- Rule files must not instruct SDMon to change the target Agent.
- Rule files must not trigger system modifications.
- Rule Runtime may output a message, but must not perform action execution.

Current Alpha `RULE_MESSAGE` is allowed as display text. It should remain non-destructive and review-oriented.

## 8. Rule Version Policy

Rule Schema should support versioning before public Beta.

Recommended field:

```text
RULE_VERSION="1"
```

Version rules:

- Missing `RULE_VERSION` may default to `1` during Beta.
- Major version changes indicate incompatible schema semantics.
- Minor changes may add optional fields.
- Rule Runtime should reject unsupported future major versions once validation exists.
- Version changes must be documented.

Recommended version interpretation:

```text
1      Beta-compatible base schema
1.x    Compatible optional additions
2      Breaking schema change requiring RFC
```

## 9. Deprecated Rule Policy

Rules should be deprecated before removal.

Recommended fields:

```text
RULE_DEPRECATED="false"
RULE_DEPRECATED_REASON=""
RULE_REPLACED_BY=""
```

Deprecation rules:

- Deprecated Rules should remain readable and auditable.
- Deprecated Rules should not silently disappear during Beta.
- Deprecated Rules should explain the reason and replacement Rule when available.
- Deprecated Rules should default to disabled only after compatibility impact is documented.
- Removing a Rule after Beta requires a compatibility note or RFC when the Rule was part of a public pack.

## 10. Rule Compatibility

Compatibility rules for Beta:

- Adding optional fields is compatible.
- Unknown optional fields should be ignored or warned when validation exists.
- Removing required fields is not compatible.
- Renaming `RULE_ID` is not compatible without aliasing or migration notes.
- Changing severity meaning is not compatible.
- Changing match semantics is not compatible without versioning.
- Changing a Rule from review-only to remediation is forbidden.

Minimum Beta required fields:

```text
RULE_ID
RULE_EVENT_CATEGORY or RULE_MATCH_FIELD
RULE_SEVERITY or RULE_LEVEL
RULE_MESSAGE or RULE_NAME
```

Recommended Beta required fields for new Rules:

```text
RULE_ID
RULE_NAME
RULE_CATEGORY
RULE_LEVEL
RULE_MATCH_FIELD
RULE_MATCH_TYPE
RULE_MATCH_PATTERN
RULE_MESSAGE
```

Alpha demo Rules may remain valid during transition.

## 11. RFC Requirements

An RFC is required for Rule Schema changes that:

- Add executable actions.
- Add remote rule download or remote rule execution.
- Replace `.conf` as the default Rule format.
- Require Python, jq, Homebrew, or third-party parsers in the default path.
- Change severity values.
- Change risk score meaning.
- Rename required fields after Beta.
- Remove public Rule fields after Beta.
- Introduce correlation or risk DSL semantics beyond simple field matching.

RFCs must describe:

1. Problem statement.
2. Proposed schema change.
3. Compatibility impact.
4. Migration path.
5. Security and read-only impact.
6. Test impact.
7. Documentation impact.

## 12. Beta Compatibility

Beta compatibility rules:

- Current `rules_v2/` demo rules remain valid during Beta planning.
- `rules_v2/` remains the safe V2 rule directory until a directory migration decision is accepted.
- New Beta Rules should follow the frozen naming, severity, category, and match conventions.
- Rule files remain local `.conf` files.
- Rule files remain Bash-friendly data.
- Rule files must not execute commands.
- Rule files must not perform remediation.
- Rule files must not bind generic behavior to a specific target Agent unless clearly scoped to a Profile or example pack.

## 13. Freeze Conclusion

Conclusion:

- Rule Schema can enter P0 Freeze.
- The frozen Rule Schema applies to Rule files, not Runtime implementation.
- The frozen Rule Schema is compatible with current `rules_v2/` demo rules.
- Beta may add small optional fields such as `RULE_VERSION`, `RULE_MATCH_TYPE`, and deprecation metadata.
- After Beta, breaking Rule Schema changes must go through RFC.
