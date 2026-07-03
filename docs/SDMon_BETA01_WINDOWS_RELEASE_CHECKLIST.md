# SDMon Beta 01 Windows Release Checklist

Status: completed for `v2.1.0-beta.1` Pre-release.

Windows Beta support is now available from `main`. Future Windows changes should continue through pull requests and should keep the workflow read-only.

## Functional Checks

- [x] Confirm Windows Beta support is available from `main`.
- [x] Run Windows smoke test successfully.
- [x] Run formal Windows scan successfully.
- [x] Confirm progress completes through all scan stages.
- [x] Confirm output files are generated.
- [x] Confirm `report.html` opens successfully.

## Safety Checks

- [ ] Confirm scan is read-only.
- [ ] Confirm no remediation is performed.
- [ ] Confirm registry is not modified.
- [ ] Confirm system settings are not changed.
- [ ] Confirm services are not stopped, started, restarted, enabled, disabled, or deleted.
- [ ] Confirm scheduled tasks are not enabled, disabled, or deleted.
- [ ] Confirm credential file contents are not read.
- [ ] Confirm browser private profile data is not read.

## Privacy Checks

- [ ] Do not publish real Windows reports.
- [ ] Do not publish real hostnames.
- [ ] Do not publish real usernames.
- [ ] Do not publish real local IPs.
- [ ] Do not publish real process lists.
- [ ] Do not publish real service lists.
- [ ] Do not publish real scheduled task lists.
- [ ] Do not publish real network connections.

## Public Artifact Checks

- [ ] Demo report uses `demo-windows.local`.
- [ ] Demo report uses `EXAMPLE\demo-user`.
- [ ] Demo report uses Example Corp.
- [ ] Demo report uses documentation IP ranges only.
- [ ] Demo report does not contain real test values.
- [ ] Demo ZIP contains only synthetic demo files.

## Demo Artifact Checks

- [ ] `examples/windows/demo-report.html`
- [ ] `examples/windows/demo-report.json`
- [ ] `examples/windows/demo-report.csv`
- [ ] `examples/windows/demo-summary.txt`
- [ ] `examples/windows/demo-events.json`
- [ ] `examples/windows/demo-timeline.json`
- [ ] `examples/windows/demo-report.zip`

## Backlog Before Beta Release

- [ ] Browser localization placeholder polish.
- [ ] Raw evidence display.
- [ ] Detection accuracy validation.
- [ ] Event volume reduction.
- [ ] Technical Details grouping.
- [ ] Microsoft services/tasks allowlist.
- [ ] Cross-version Windows testing.

## Release Rule

Windows Beta 01 has been merged for `v2.1.0-beta.1` Pre-release. Do not create new tags or releases from this checklist; use it as the historical readiness record.
