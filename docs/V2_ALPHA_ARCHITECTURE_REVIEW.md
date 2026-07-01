# SDMon V2 Alpha Architecture Review

## 1. Current V2 Alpha Completed Capabilities

V2 Alpha has reached a runnable local macOS framework baseline.

Completed capabilities:

- Event Layer with JSONL normalized event output.
- Demo Event Producers for process, file, and network events.
- Rule Runtime with loader, matcher, and rule result output.
- Analyzer with summary, timeline, confidence, and risk score output.
- Reporter with JSON, HTML, and CSV report generation.
- macOS Sensors for process, file, launchd, network, system, and permission observations.
- macOS Sensor Runner that writes `all_events.jsonl` and `sensor_status.jsonl`.
- V2 Alpha Pipeline Runner that connects Sensors, Rule Runtime, Analyzer, and Reporter.
- V2 CLI Wrapper with `run`, `version`, and `help`.
- V2 Alpha usage documentation.

These capabilities are sufficient to demonstrate the framework flow:

```text
Sensor -> Normalized Event -> Rule Runtime -> Analyzer -> Reporter
```

## 2. Current Directory Structure Review

Current V2 Alpha directories are understandable and mostly aligned with the design documents:

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

Positive findings:

- V2 code is separated from V1.1 `bin/`, `rules/`, `config.conf`, and `.command` entry points.
- `sensors/macos/` clearly reflects the macOS-first implementation strategy.
- `runtime/`, `analyzers/`, and `reporters/` follow single-responsibility boundaries.
- `templates/` is separate from Reporter logic.
- `tests/` covers the runnable Alpha pipeline and CLI.

Naming concerns:

- `rules_v2/` is practical for avoiding collision with V1.1 `rules/`, but long-term architecture documents recommend `rules/` with subdirectories. Keep `rules_v2/` for Alpha to avoid V1.1 collision, then migrate deliberately during Beta.
- The design documents sometimes use `Collector`, while the implementation currently uses `Sensor` and `Producer`. This is acceptable for Alpha, but Beta should standardize terminology in user-facing docs.
- Analyzer output is currently compact compared with the planned `analysis.json`, `risk_summary.json`, and `report_data.json` model.

## 3. Event Schema Freeze Recommendation

Recommendation: freeze the Alpha event schema as an Alpha contract, not as the final V2 contract.

The current schema is good enough for Alpha because it supports:

- process
- file
- network
- service
- system
- permission
- configuration/security/application extension categories

Freeze now:

- Field naming style.
- JSONL output model.
- Required fields for framework flow.
- Event category names.

Do not freeze permanently yet:

- Platform-specific optional fields.
- Evidence reference fields.
- Raw event linkage.
- Timeline and Finding mapping fields.

Beta should add schema versioning rules and compatibility notes before treating it as a stable public contract.

## 4. Rule Format Freeze Recommendation

Recommendation: freeze the Alpha rule format only for demo rules.

The `.conf` approach is aligned with the Bash-only and dependency-free design. However, the current Rule Runtime is intentionally minimal and does not yet fully implement the richer rule fields described in the design documents.

Freeze now:

- Local `.conf` rule files.
- Rule files as data, not executable behavior.
- Rule Runtime consumes normalized events.
- Rule output feeds Analyzer rather than Reporter directly.

Do not freeze permanently yet:

- Full rule validation.
- Deduplication semantics.
- Correlation rule shape.
- Risk scoring rule shape.
- Profile-specific rule overrides.

Beta should define a stricter Rule schema before adding many real rule examples.

## 5. Boundary Review

The main module boundaries are clear enough for Alpha.

Sensor boundary:

- Sensors collect, normalize, and write events.
- Sensors do not call Rule Runtime, Analyzer, or Reporter.
- Sensors do not calculate risk.
- Sensors do not modify target Agents or system settings.

Runtime boundary:

- Rule Runtime consumes events and emits rule results.
- Runtime does not collect evidence.
- Runtime does not render final reports.

Analyzer boundary:

- Analyzer consumes rule results and emits structured analysis.
- Analyzer does not collect evidence or render final HTML.
- Analyzer currently uses a compact model; this is acceptable for Alpha.

Reporter boundary:

- Reporter consumes Analyzer output and renders JSON, HTML, and CSV.
- Reporter no longer leaves template placeholders in HTML.
- Reporter does not collect or analyze raw evidence.

The boundaries should be frozen for Alpha.

## 6. CLI Freeze Recommendation

Recommendation: freeze the Alpha CLI commands:

```text
./sdmon-v2.sh run
./sdmon-v2.sh run --output <dir>
./sdmon-v2.sh version
./sdmon-v2.sh help
```

These commands are simple, testable, and sufficient for Alpha and early Beta validation.

Do not add more CLI surface until Beta priorities are clear.

## 7. Interfaces Not Recommended For Further Alpha Changes

Do not continue changing these Alpha interfaces unless fixing bugs:

- `sdmon-v2.sh run --output <dir>`
- `v2_alpha.sh <output-dir>`
- `sensors/macos/run_all_sensors.sh <events-dir>`
- `events/event_writer.sh --output <file> KEY=VALUE`
- JSONL event output model.
- `events/all_events.jsonl`
- `events/sensor_status.jsonl`
- `reports/report.json`
- `reports/report.html`
- `reports/report.csv`

These interfaces should remain stable while Beta planning starts.

## 8. Beta-Before-Freeze Fix List

Before V2 Beta, fix or clarify:

- Add stronger tests that assert no `{{...}}` placeholders remain in HTML reports.
- Add rule validation and clear invalid-rule diagnostics.
- Add schema version compatibility notes for events and reports.
- Decide whether `rules_v2/` remains through Beta or migrates to a future `rules/` structure.
- Add Profile support before adding real target-specific Sensors or Rules.
- Add `resolved_config` or equivalent run metadata.
- Improve Analyzer output toward `analysis.json`, `risk_summary.json`, and `report_data.json`.
- Improve Reporter handling for empty findings and multiple timeline entries.
- Add public documentation that distinguishes Alpha demo rules from production-ready rules.
- Ensure public docs do not expose internal target paths or organization-specific indicators.

## 9. Beta Recommended Additions

Recommended Beta additions:

- Profile Engine minimum implementation.
- Configuration loader with safe parsing and validation.
- Rule validation and rule test fixtures.
- More realistic macOS Sensor fixtures.
- End-to-end regression tests for CLI, pipeline, reports, and placeholder cleanup.
- Report improvements for multiple findings, timeline display, and limitations.
- i18n foundation for `REPORT_LANG=auto`, `zh-CN`, and `en-US`.
- Profile examples for generic MDM, EDR, VPN, Zero Trust, Enterprise Agent, AI Agent, and Custom Agent categories.

Windows and Linux should remain planned only. Beta should continue macOS first.

## 10. Current Architecture Risks

V1.1 and V2 mixing risk:

- Current code separation is acceptable.
- V1.1 files remain in place and V2 uses separate entry points.
- Risk remains if future changes try to reuse V1.1 `rules/`, `bin/`, or command wrappers without wrappers or migration notes.

Internal path exposure risk:

- Public README has been cleaned.
- Some older architecture documents still contain legacy examples. Treat those as migration references, not public homepage messaging.
- Future public docs should avoid making internal paths the primary project identity.

Directory naming risk:

- `rules_v2/` is intentionally separate from V1.1 `rules/`.
- Long-term docs recommend a richer `rules/` directory tree. Moving too early could create V1.1 collision risk.

Cross-platform refactor risk:

- The high-level model is cross-platform ready.
- Current implementation is macOS-specific in Sensors, which is correct for Alpha.
- Future Windows/Linux support should add new Sensors and Profiles rather than changing Analyzer or Reporter contracts.

Bash-only long-term risk:

- Bash-only is good for Alpha portability and macOS built-in dependency goals.
- Long-term risks include JSON parsing fragility, HTML rendering limitations, and rule validation complexity.
- Beta should keep Bash-only, but should document where a future optional richer runtime may help.

Platform strategy risk:

- Adding Windows/Linux now would create avoidable rework.
- Recommendation is to keep macOS first until Profile, Rule, Analyzer, Reporter, and event schema contracts are steadier.

## 11. Beta Readiness Conclusion

Conclusion: V2 Alpha architecture can be frozen with known limitations.

Recommendation:

- Freeze Alpha module boundaries.
- Freeze Alpha CLI commands.
- Freeze Alpha event schema as an Alpha contract.
- Keep Rule format semi-frozen until validation improves.
- Continue macOS first.
- Do not start Windows/Linux implementation yet.

V2 can enter Beta planning, but should not be called Beta-ready until Profile, Configuration, Rule validation, report quality, and end-to-end regression coverage are improved.
