# Changelog

All notable changes to SDMon are documented in this file.

## Unreleased

- Post-RC1 development will continue toward Beta.

## v2.0.0-rc1

Status: Public Preview.

### Added

- One-command workflow through `./sdmon-v2.sh`.
- Local read-only macOS assessment.
- Unified administrator privilege flow.
- HTML, PDF, ZIP, JSON, CSV, and Summary reports.
- Executive Summary with Security Score, Overall Risk, and risk distribution.
- Top Findings, Recommendations, Timeline, Download, and Technical Details sections.
- Local Rule Engine and Reporter pipeline.
- macOS-oriented checks for system, persistence, network, browser, credential, sensitive file, firewall, FileVault, and related endpoint signals.

### Improved

- Report presentation for enterprise IT and security review.
- PDF print layout for compact executive summary pages.
- Score and risk consistency.
- Home path display using `~/...` in management-facing report sections.
- Chinese-friendly report wording while keeping repository documentation in English.

### Safety

- No data upload.
- No automatic remediation.
- No target agent modification.
- No system setting modification.
- V1.1 remains available as a legacy workflow.

## V2 Alpha Preview

- Introduced the initial V2 event, rule, analyzer, reporter, sensor, and CLI pipeline.

## V1.1 Legacy

- Introduced the original Bash-only macOS validation workflow.
