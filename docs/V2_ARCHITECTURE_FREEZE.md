# SDMon V2 Architecture Freeze

This document defines which SDMon V2 design areas are considered frozen for the current V2 architecture baseline.

It is not an architecture introduction. It is a change-control document.

## 1. Directory Freeze

The following top-level V2 Alpha directories are frozen as the current architecture baseline:

```text
events/
producers/
rules_v2/
runtime/
analyzers/
reporters/
sensors/macos/
templates/
tests/
docs/
```

Freeze rules:

- Do not move V1.1 files into V2 directories during the freeze period.
- Do not move V2 files into V1.1 directories.
- Do not modify `bin/`, legacy `rules/`, `config.conf`, or `.command` files as part of V2 work unless a task explicitly targets V1.1 compatibility.
- Runtime output, generated logs, packet captures, reports, and archives must not be committed.
- `rules_v2/` remains the Alpha/Beta-safe rule directory until a formal migration decision is accepted.

Allowed changes without architecture review:

- Add tests under `tests/`.
- Add documentation under `docs/`.
- Add bug fixes within the owning module directory.

Requires architecture review:

- Moving `rules_v2/` to another path.
- Introducing new root-level runtime directories.
- Merging V1.1 and V2 paths.
- Moving sensors out of `sensors/macos/` before Windows/Linux planning is accepted.

## 2. Runtime Pipeline Freeze

The V2 runtime pipeline is frozen as:

```text
Sensor Runner
  -> Event JSONL
  -> Rule Runtime
  -> Analyzer
  -> Reporter
  -> Local Output
```

Frozen pipeline artifacts:

```text
events/all_events.jsonl
events/sensor_status.jsonl
runtime/rule_results.jsonl
analysis/analysis.json
reports/report.json
reports/report.html
reports/report.csv
```

Freeze rules:

- Sensors must not call Analyzer or Reporter directly.
- Rule Runtime must not collect system data.
- Analyzer must not collect sensor data.
- Reporter must not run Sensors, Rules, or Analyzer logic.
- Pipeline output remains local by default.
- A failed required pipeline stage should stop the pipeline with a clear error.

## 3. Sensor Responsibility Freeze

Sensor responsibilities are frozen as:

- Collect raw or observed platform evidence.
- Normalize observations into event fields.
- Write events through the Event Layer.
- Write collection status through the Sensor Runner.
- Stay read-only.

Sensors must not:

- Calculate risk score.
- Generate Findings.
- Render reports.
- Modify target Agents.
- Stop or unload target services.
- Modify TCC, PPPC, LaunchDaemon, LaunchAgent, or system security settings.
- Upload data.
- Use hidden collection behavior.

Current frozen macOS Sensor categories:

- process
- file
- launchd
- network
- system
- permission

Windows and Linux Sensors are not part of the frozen implementation. They remain future extension points.

## 4. Analyzer Responsibility Freeze

Analyzer responsibilities are frozen as:

- Consume Rule Runtime output.
- Produce structured analysis output.
- Build behavior summary.
- Build timeline data.
- Calculate risk score and confidence from available rule results.
- Preserve evidence-oriented interpretation.

Analyzer must not:

- Collect system data.
- Run Sensors.
- Modify Rules.
- Render final HTML, CSV, or JSON reports.
- Upload results.
- Stop, delete, quarantine, or modify target Agents.
- Produce final malicious or benign verdicts.

Analyzer output may evolve, but field changes require report compatibility review.

## 5. Reporter Responsibility Freeze

Reporter responsibilities are frozen as:

- Consume Analyzer output.
- Render local report artifacts.
- Use templates for HTML output.
- Produce machine-readable and human-readable outputs.
- Preserve evidence-first and limitation-aware presentation.

Frozen report outputs:

```text
report.json
report.html
report.csv
```

Reporter must not:

- Collect evidence.
- Re-run Rules.
- Modify Profiles or Rules.
- Upload reports.
- Start a web server by default.
- Fetch remote assets by default.
- Leave unresolved template placeholders such as `{{...}}` in final reports.

## 6. Rule Management Freeze

Rule management is frozen as a local, file-based, read-only model.

Frozen Alpha/Beta rule properties:

- Rules are local files.
- Rules are data, not executable remediation logic.
- Rule Runtime consumes Normalized Events.
- Rule Runtime emits Rule Results for Analyzer.
- Rules do not generate final reports.
- Rules do not start or stop Sensors.

Current rule directory:

```text
rules_v2/
```

`rules_v2/` is frozen as the safe V2 rule directory until a migration decision is accepted.

Requires architecture review:

- Migrating `rules_v2/` to `rules/`.
- Adding remote rule download.
- Adding remote rule execution.
- Adding rule actions that modify system or target state.
- Adding rule formats that require non-built-in dependencies.

## 7. Configuration Freeze

Configuration design is frozen as layered configuration:

```text
Command Line parameters
  -> Profile configuration
  -> config.conf global configuration
  -> default values
```

Configuration principles are frozen:

- Configuration is data, not executable behavior.
- Configuration must not execute arbitrary commands.
- Configuration must not modify system settings.
- Configuration must not stop, unload, uninstall, or alter target Agents.
- Profile data defines target scope.
- Rule data defines behavior matching.
- CLI parameters may override run-local choices.

Beta work may implement configuration loading, but must preserve these boundaries.

## 8. Event Contract Freeze

The Event Contract is frozen at the Alpha architecture level as JSONL Normalized Events.

Frozen event contract properties:

- One event per JSONL line.
- Events are written by `events/event_writer.sh`.
- Events include schema version fields.
- Events include category, type, source, target, profile, timestamp, and confidence concepts.
- Rule Runtime consumes events instead of raw tool output.
- Sensors should keep missing fields empty rather than invent values.

Current frozen event categories:

- process
- file
- network
- service
- system
- permission
- configuration
- security
- application

Requires architecture review:

- Removing an existing event category.
- Renaming existing required event fields.
- Changing JSONL to a non-line-based format.
- Making SQLite or any database mandatory for the default pipeline.
- Allowing Sensors to bypass the Event Layer.

## 9. CLI Freeze

The V2 Alpha CLI surface is frozen as:

```text
./sdmon-v2.sh run
./sdmon-v2.sh run --output <dir>
./sdmon-v2.sh version
./sdmon-v2.sh help
```

Freeze rules:

- Existing commands must remain backward compatible during Beta.
- Error handling should return non-zero status for invalid commands or invalid arguments.
- CLI must call V2 entry points, not V1.1 command files.
- CLI must not require sudo for the default V2 Alpha/Beta path.

Requires architecture review:

- Renaming `sdmon-v2.sh`.
- Removing any frozen command.
- Changing `run --output` semantics.
- Making background or LaunchAgent mode the default.

## 10. Version Policy

Version policy is frozen as:

- V2 Alpha remains a runnable preview.
- V2 Beta begins only after P0 freeze items are accepted.
- Beta must preserve Alpha CLI compatibility unless an explicit breaking-change note is accepted.
- Event Schema, Rule Format, and Report Format should carry version identifiers before public Beta.
- Generated report artifacts should identify the SDMon version or report schema version when available.

Recommended labels:

```text
SDMon V2 Alpha
SDMon V2 Beta
```

Breaking changes require:

- Documentation update.
- Compatibility note.
- Test update.
- Architecture review entry.

## 11. Backward Compatibility

Backward compatibility rules:

- V1.1 remains available as the legacy baseline.
- V2 work must not change V1.1 runtime behavior by default.
- V2 entry points must not depend on V1.1 `.command` files.
- V1.1 command files remain user-facing legacy entry points until an explicit migration plan is accepted.
- Public README may describe V1.1 as legacy, but V2 should not remove V1.1 files during the freeze period.

V2 compatibility rules:

- Existing V2 CLI commands should keep working.
- Existing report artifact names should keep working.
- Existing Event JSONL output should remain consumable by Rule Runtime.
- Existing tests should remain meaningful when implementation improves.

## 12. Architecture Change Process

Architecture changes must follow a lightweight review process.

A change requires architecture review when it:

- Changes frozen directory boundaries.
- Changes the runtime pipeline order.
- Changes Sensor, Runtime, Analyzer, or Reporter responsibilities.
- Changes required event fields or event categories.
- Changes Rule Format semantics.
- Changes CLI command names or argument semantics.
- Introduces Windows/Linux implementation work.
- Introduces background or continuous monitoring mode.
- Introduces remote upload, remote rules, or remote execution.
- Introduces non-Bash or third-party runtime dependencies for the default path.

Architecture review should include:

1. Problem statement.
2. Proposed change.
3. Affected frozen area.
4. Compatibility impact.
5. Security and read-only impact.
6. Test impact.
7. Migration plan.
8. Decision: accepted, rejected, or deferred.

Preferred location for architecture changes:

```text
docs/
docs/rfc/
```

Default decision bias:

- Preserve macOS first.
- Preserve read-only behavior.
- Preserve local output.
- Preserve V1.1 compatibility.
- Avoid Windows/Linux implementation until Beta contracts are stable.
- Avoid new dependencies in the default workflow.
