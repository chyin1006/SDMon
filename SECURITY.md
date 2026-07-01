# Security Policy

## Supported Versions

| Version | Status |
| --- | --- |
| V2 Alpha Preview | Security reports accepted; fixes are best effort during Alpha. |
| V1.1 Legacy | Legacy validation path; security-impacting reports accepted. |

## Security Boundaries

SDMon is intended for local, read-only Agent behavior analysis.

SDMon should not:

- Upload collected data automatically.
- Modify target Agents.
- Stop, unload, delete, quarantine, or bypass software.
- Change system security settings.
- Perform hidden monitoring.
- Collect unrelated personal content.

## Reporting a Vulnerability

Please open a GitHub issue using the security report template.

Do not include secrets, credentials, private keys, personal data, or sensitive production logs in public issues.

Include:

- SDMon version or commit.
- Platform and macOS version.
- A clear description of the issue.
- Minimal reproduction steps.
- Whether the issue affects read-only behavior, local output, or report correctness.

## Scope

In scope:

- Behavior that breaks read-only guarantees.
- Unintended data upload or exposure.
- Unsafe Rule or template handling.
- Unsafe file writes outside the selected output directory.
- Misleading security claims in reports or documentation.

Out of scope:

- Requests to bypass security tools.
- Requests to modify, stop, uninstall, or hide Agents.
- Reports based only on Alpha feature incompleteness.
