# SDMon V2 Beta Plan

## 1. Beta Goals

V2 Beta should turn the runnable V2 Alpha baseline into a stable macOS-first framework release candidate.

Beta goals:

- Freeze the core Alpha architecture before adding new capability.
- Stabilize Event Schema, Rule Format, CLI behavior, and report fields.
- Confirm V1 and V2 directory boundaries.
- Keep SDMon read-only, local-first, and dependency-light.
- Continue macOS first and avoid premature Windows/Linux implementation.
- Improve test coverage for the end-to-end pipeline.
- Prepare Profile and Configuration foundations for real Agent analysis scenarios.

## 2. Beta Non-goals

Beta should not include:

- Windows Sensor implementation.
- Linux Sensor implementation.
- Web UI as a required interface.
- AI-based analysis as a required decision layer.
- Automatic remediation.
- Hidden or background monitoring by default.
- Remote upload of events or reports.
- Changes to V1.1 behavior.
- Migration or deletion of V1.1 command files.
- Replacement of EDR, MDM, VPN, or enterprise security products.

## 3. Alpha To Beta Prerequisites

Before entering Beta implementation, the project should complete these prerequisite decisions:

- Freeze V2 Alpha module boundaries.
- Freeze or explicitly version Event Schema.
- Freeze the Alpha Rule Format or define a Beta Rule Format with compatibility notes.
- Freeze CLI commands for Beta.
- Confirm V1/V2 directory boundaries and migration policy.
- Decide whether `rules_v2/` remains for Beta or migrates to a future `rules/` layout.
- Define report field names and report artifact contracts.
- Confirm macOS first as the Beta implementation route.
- Keep Windows/Linux as future platform planning only.

## 4. Beta Priorities

### P0: Freeze And Stabilize

P0 items must be completed before Beta feature expansion.

Required P0 items:

- Event Schema freeze.
- Rule Format freeze.
- CLI command freeze.
- V1/V2 directory boundary confirmation.
- `rules_v2/` keep-or-migrate naming decision.
- Report field standardization.
- macOS first route confirmation.

Additional P0 details:

- Event Schema should include a schema version and compatibility note.
- Rule Format should define required fields, optional fields, validation behavior, and disabled-rule behavior.
- CLI should preserve `run`, `run --output`, `version`, and `help`.
- V1.1 files should remain stable and outside V2 Beta refactors.
- Report artifacts should standardize at least `report.json`, `report.html`, and `report.csv` for Beta.
- Generated output, logs, pcap files, and zip files must remain outside commits.

### P1: Beta Feature Work

P1 items may start after P0 freeze items are complete.

Recommended P1 items:

- SQLite event database design.
- Incremental collection design.
- LaunchAgent continuous run mode design.
- Rule example expansion.
- HTML report optimization.

P1 notes:

- SQLite should be designed first, not immediately required in the default pipeline.
- Incremental collection should preserve read-only behavior and explicit user control.
- LaunchAgent mode must not become hidden monitoring and should require clear user opt-in.
- Rule examples should remain generic and avoid vendor- or organization-specific assumptions.
- HTML report optimization should keep reports static and local by default.

### P2: Future Planning

P2 items should remain planning topics during Beta.

Recommended P2 items:

- Windows/Linux delayed planning.
- Web UI.
- AI analysis.
- SIEM/SOC output formats.

P2 notes:

- Windows and Linux should not be implemented until macOS Beta contracts are stable.
- Web UI should not replace CLI or local static report output.
- AI analysis should not become an unsupported malware verdict engine.
- SIEM/SOC export should consume structured Analyzer/Reporter data, not raw Sensor output.

## 5. Beta Acceptance Criteria

V2 Beta can be accepted when:

- P0 freeze decisions are documented.
- V2 Alpha architecture is frozen with known limitations.
- CLI commands remain stable and tested.
- Event Schema is versioned and documented.
- Rule Format is validated and documented.
- V1.1 and V2 boundaries are explicitly documented.
- macOS Sensor Runner remains read-only and local.
- End-to-end pipeline test passes consistently.
- Reporter output contains no unresolved template placeholders.
- Report fields are stable enough for downstream use.
- Public docs avoid internal target paths as primary project identity.
- Generated artifacts are not committed.

## 6. Beta Risks

Key Beta risks:

- V1/V2 mixing: future changes may accidentally reuse V1.1 `bin/`, `rules/`, or command wrappers.
- Naming drift: `rules_v2/` may diverge from long-term `rules/` design if not documented.
- Bash-only limits: JSON parsing, rule validation, HTML rendering, and future data modeling may become fragile.
- Report contract drift: JSON, HTML, and CSV fields may change without versioning.
- Profile delay: without Profile support, real Agent analysis may remain too demo-like.
- Configuration safety: unsafe `source` usage or executable configuration would violate the design.
- Cross-platform temptation: starting Windows/Linux too early would likely create rework.
- Continuous mode risk: LaunchAgent support could be misread as hidden monitoring unless opt-in and visible.

## 7. Beta Development Order

Recommended Beta development sequence:

1. Freeze P0 architecture and interface decisions.
2. Document Event Schema version and compatibility rules.
3. Document and validate Rule Format.
4. Confirm `rules_v2/` naming policy for Beta.
5. Standardize report fields and report artifact contracts.
6. Add Profile minimum implementation design and tests.
7. Add Configuration minimum implementation design and tests.
8. Expand Rule examples with fixtures.
9. Improve HTML report and placeholder regression tests.
10. Design SQLite event database without making it mandatory.
11. Design incremental collection.
12. Design explicit opt-in LaunchAgent continuous mode.
13. Revisit Windows/Linux planning after macOS Beta contracts are stable.

## 8. Conclusion

Current conclusion:

- V2 Alpha architecture can be frozen now.
- Before entering Beta implementation, complete the P0 freeze items first.
- Do not develop Windows/Linux at the same time as macOS Beta stabilization.
- Continue macOS first.
- Keep Windows/Linux as future extension planning until Event Schema, Rule Format, CLI, reports, Profile, and Configuration are stable on macOS.
