# SDMon Beta 01 Windows Test Record

## Test Scope

- Branch tested: `beta/windows-endpoint-assessment`
- Windows test machine type: real Windows machine
- Test date: `<YYYY-MM-DD>`
- Test status: PASS

## Commands Executed

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\tests\test_windows_smoke.ps1
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Output .\output -NoOpen
```

## Results

- Smoke test result: PASS
- Formal scan result: PASS
- HTML report opened successfully: Yes

## Generated Output Files

```text
output\
  report.html
  report.json
  report.csv
  summary.txt
  report.zip
  events.json
  timeline.json
```

## Observed Formal Scan Summary

```text
Security Score : 73
Overall Risk   : Medium
Events         : 1002
Matched Rules  : 12
```

## Known Limitations

- Browser extension names may show localization placeholders.
- Firewall, UAC, and BitLocker raw values need cross-version validation.
- Phase 3 technical events can be noisy.
- Services, scheduled tasks, network connections, and process events need grouping and summarization.
- Microsoft default services and scheduled tasks need allowlist tuning.
- HTML and PDF report polish is planned for a later QA pass.

## Security Notes

- SDMon Windows Beta 01 is read-only.
- The scan does not perform remediation.
- The scan does not modify registry values.
- The scan does not change system settings.
- The scan does not stop, start, enable, disable, or delete services or scheduled tasks.
- Credential metadata checks record file metadata only and do not read credential contents.

## Real Report Handling Rule

Real Windows reports must not be published. They may include real hostname, username, local IPs, process names, services, scheduled tasks, browser extension IDs, and network connections.

Use only synthetic, anonymized demo assets for public documentation.

## Next QA / Polish Backlog

- Validate Firewall, UAC, and BitLocker raw values on multiple Windows versions.
- Add grouping and summarization for large technical detail sections.
- Tune Microsoft default services and scheduled tasks.
- Add process and network event summarization.
- Review false positives.
- Produce final anonymized public demo screenshots after report layout is stable.
