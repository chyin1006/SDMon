# Contributing to SDMon

Thanks for your interest in SDMon.

SDMon V2 Alpha Preview is focused on a small, safe, macOS-first framework for local Agent behavior analysis.

## Start Here

Before contributing, read:

- `PROJECT_INDEX.md`
- `README.md`
- `docs/V2_ALPHA_USAGE.md`
- `docs/V2_RULE_SCHEMA_FREEZE.md`

## Development Boundaries

Keep these boundaries intact:

- Read-only collection.
- Local output only.
- No data upload.
- No automatic remediation.
- No target Agent modification.
- No security bypass behavior.
- No Python, jq, Homebrew, or third-party dependency in the default V2 Alpha path.

## Writing a First Rule

Copy the example Rule:

```bash
cp examples/rules/first_process_rule.conf rules_v2/my_first_rule.conf
```

Alpha-compatible fields:

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

Rules should be descriptive and review-oriented. They must not execute commands or perform remediation.

## Pull Request Checklist

Before opening a PR:

- Confirm whether your change touches V1.1 or V2.
- Keep V1.1 and V2 boundaries clear.
- Do not commit output, logs, packet captures, generated reports, or zip files.
- Run relevant tests when changing executable scripts.
- Update docs when adding new user-facing behavior.

## Documentation Contributions

Documentation improvements are welcome, especially:

- Quick Start clarity.
- Rule authoring examples.
- Report interpretation guidance.
- Safety boundary explanations.

## Code Contributions

For V2 Alpha code changes, preserve Bash-only and macOS built-in tool constraints unless a future RFC changes that direction.
