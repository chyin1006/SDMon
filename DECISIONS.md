# SDMon Decisions

## 2026-06-29 - Use Bash and native macOS tools only

Decision:

- SDMon V1.1 will be implemented with Bash and macOS built-in tools.
- No Python.
- No Homebrew.

Reason:

- The user may run this on clean macOS endpoints.
- The tool should be double-click runnable and easy to copy.
- External dependencies make enterprise troubleshooting harder.

## 2026-06-29 - Monitoring must be read-only

Decision:

- SDMon must not stop, unload, delete, quarantine, or modify the monitored software.

Reason:

- The purpose is dynamic behavior observation, not remediation.
- The user wants evidence of what the software is doing while running.

## 2026-06-29 - Output goes to Downloads

Decision:

- Runtime output must go to `~/Downloads/2026-110`.

Reason:

- Easy for a non-developer user to find.
- Easy to package and share.

## 2026-06-29 - Do not commit runtime output

Decision:

- Logs, pcaps, zip files, and generated output must not be committed.

Reason:

- These may contain sensitive endpoint data.
- Git repository should contain source code and documentation only.

## 2026-06-29 - `fs_usage` must be filtered

Decision:

- `fs_usage` output must be filtered to `demo-agent` and `demo-helper`.

Reason:

- The first prototype produced a very large `fs_usage.log` because it captured too much system activity.

## 2026-06-29 - `network.log` must use sudo

Decision:

- Network snapshots must use `sudo lsof`.

Reason:

- The target processes run as root, and normal `lsof` may miss root-owned connections.
