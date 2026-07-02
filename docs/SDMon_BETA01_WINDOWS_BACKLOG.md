# SDMon Beta 01 Windows Backlog

This backlog records known Windows Beta 01 QA and polish items that should not block the current collector implementation.

## QA / Polish Backlog

- Browser extension names may still show `__MSG_xxx` localization placeholders.
- Raw security evidence display needs improvement.
- Firewall, UAC, and BitLocker raw values need later validation across Windows versions and editions.
- Phase 3 event volume can be noisy and should be reduced later.
- Technical Details need grouping and summarization.
- Microsoft default services and scheduled tasks need allowlist and tuning.
- Process event noise needs tuning.
- Network connection summarization is needed.
- HTML and PDF report layout can be improved.
- False positive review is required after broader endpoint testing.
- Cross-version Windows testing is needed for Windows 10, Windows 11, Windows Server, PowerShell 5.1, and PowerShell 7.
- Public demo artifacts must remain anonymized and synthetic.
- Windows Beta release checklist must be completed before merging or release planning.

## Safety Notes

- Keep Windows Beta 01 read-only.
- Do not add remediation behavior.
- Do not treat review items as malicious.
- Do not publish real Windows reports.
