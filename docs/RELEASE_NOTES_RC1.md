# SDMon V2 RC1 Release Notes

Version: `v2.0.0-rc1`

Status: Public Preview

## Summary

SDMon V2 RC1 is a macOS-first Enterprise Security Assessment Toolkit.

It generates local HTML, PDF, ZIP, JSON, CSV, and Summary reports from a single command:

```bash
./sdmon-v2.sh
```

## Highlights

- One-command local scan.
- Read-only assessment.
- Local analysis with no cloud dependency.
- Unified administrator privilege flow.
- Enterprise-style report package.
- Executive Summary with Security Score and Overall Risk.
- Top Findings and Recommendations.
- Timeline with Technical Details.
- Downloadable HTML, PDF, CSV, JSON, and ZIP outputs.

## What RC1 Is

RC1 is designed for:

- Enterprise IT review.
- Security team triage.
- Compliance evidence collection.
- Internal audit.
- Customer delivery reports.
- MDM and endpoint management validation.

## What RC1 Is Not

RC1 is not:

- EDR.
- MDM.
- Antivirus.
- SOC platform.
- Automatic remediation.
- Background monitoring service.

## Included Outputs

```text
output/report.html
output/report.pdf
output/report.zip
output/report.json
output/report.csv
output/summary.txt
```

## Known Limitations

- macOS first.
- Windows and Linux sensors are planned but not implemented.
- No centralized dashboard yet.
- No fleet deployment workflow yet.
- False positives are expected until enterprise policy and allowlist support are added.
- Some local checks may return `unknown`, `permission_denied`, or `unsupported` depending on endpoint policy.

## Beta Direction

Planned Beta work:

- Enterprise policy and allowlist support.
- Rule tuning and severity management.
- Historical Scan and Diff Scan.
- SQLite event store.
- Dashboard.
- IOC and YARA support.
- MITRE ATT&CK mapping.
- Windows and Linux sensor research.

## Safety Boundaries

- Read-only collection.
- Local output only.
- No data upload.
- No target agent modification.
- No system setting modification.
- No automatic delete, isolate, stop, or unload actions.
