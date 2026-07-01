# SDMon TODO

## Immediate V1.1 tasks

- [ ] Confirm local repository is up to date after GitHub changes.
- [ ] Implement `bin/common.sh`.
- [ ] Implement `bin/monitor.sh`.
- [ ] Implement `bin/stop.sh`.
- [ ] Implement `bin/summary.sh`.
- [ ] Implement `bin/findings.sh`.
- [ ] Implement `Start_SDMon.command`.
- [ ] Implement `Stop_SDMon.command`.
- [ ] Implement `Analyse.command`.
- [ ] Fill `rules/sensitive_paths.conf`.
- [ ] Fill `rules/process.conf`.
- [ ] Fill `rules/network.conf`.
- [ ] Run `bash -n` syntax checks.
- [ ] Test double-click Start and Stop on macOS.
- [ ] Confirm output is created under `~/Downloads/2026-110`.
- [ ] Confirm generated logs and pcaps are ignored by Git.

## V1.1 acceptance checklist

- [ ] `traffic.pcap` is created.
- [ ] `network.log` contains root-owned connections when present.
- [ ] `process.log` records `demo-agent` and `demo-helper` snapshots.
- [ ] `launchctl.log` records service status.
- [ ] `fs_usage.log` is smaller than the V1 prototype because it is filtered.
- [ ] `summary.txt` is generated.
- [ ] `findings.txt` is generated.
- [ ] ZIP package is created after stop.
- [ ] Tool does not stop or modify target software.

## Later tasks

- [ ] Add `report.html`.
- [ ] Add better pcap traffic byte statistics.
- [ ] Add generic configurable target support.
- [ ] Add rules for other enterprise agents.
