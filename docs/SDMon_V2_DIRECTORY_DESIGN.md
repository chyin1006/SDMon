# SDMon V2 Directory Design

## 1. V2 Directory Design Goals

SDMon V2 should evolve the repository from a script-oriented project into a framework-oriented project while keeping the current V1.1 baseline stable.

Directory design goals:

- Upgrade from a script project to a Framework project.
- Preserve V1.1 as the known-good baseline.
- Serve the macOS first implementation strategy.
- Preserve extension points for future Windows and Linux support.
- Avoid over-engineering.
- Keep runtime output outside source control.
- Keep collection, analysis, reporting, rules, profiles, and platform-specific sensors separated.

V2 should introduce structure gradually. The initial directory design is a target layout, not an instruction to immediately move or rewrite V1.1 files.

## 2. Recommended V2 Directory Structure

Recommended target structure:

```text
SDMon/
  core/
  sensors/
    macos/
    windows/
    linux/
  profiles/
    macos/
    windows/
    linux/
  rules/
    process/
    file/
    network/
    persistence/
    privilege/
  analyzers/
  reporters/
    text/
    html/
    json/
    csv/
  i18n/
    zh-CN/
    en-US/
  templates/
  plugins/
  examples/
  docs/
  tests/
  output/
```

Important status notes:

- `sensors/macos/` is the only sensor implementation target for V2.
- `sensors/windows/` and `sensors/linux/` are placeholders for future versions.
- `profiles/windows/` and `profiles/linux/` are placeholders for future profile formats and examples.
- `output/` is a development placeholder only; generated logs, pcaps, reports, and zip files must not be committed.

## 3. Directory Purpose

### `core/`

Shared framework logic.

Expected content:

- Common shell helpers.
- Configuration loading.
- Profile loading.
- Rule loading.
- State management.
- Run directory management.
- Command dispatch helpers.

`core/` should contain reusable framework code, not target-specific behavior.

### `sensors/`

Platform-specific raw evidence collectors.

This directory groups all Sensors by operating system.

### `sensors/macos/`

macOS Sensor implementation directory for V2.

Expected macOS Sensors:

- process sensor
- network sensor
- file sensor
- launchd sensor
- system sensor

V2 should implement this directory first.

### `sensors/windows/`

Future Windows Sensor extension point.

V2 should not implement Windows collection logic. This directory exists to reserve the architecture shape for V3 or later.

### `sensors/linux/`

Future Linux Sensor extension point.

V2 should not implement Linux collection logic. This directory exists to reserve the architecture shape for V4 or later.

### `profiles/`

Target Agent definitions.

Profiles describe what SDMon should observe. They should not contain collection logic.

### `profiles/macos/`

macOS Agent profiles.

Expected content:

- default macOS profile
- V1.1 compatibility profile
- custom macOS profile examples

### `profiles/windows/`

Future Windows Agent profile extension point.

V2 should not ship operational Windows profiles unless they are clearly marked as non-runnable examples.

### `profiles/linux/`

Future Linux Agent profile extension point.

V2 should not ship operational Linux profiles unless they are clearly marked as non-runnable examples.

### `rules/`

Behavior rules separated from code.

Rules should describe behavior risk categories and analysis patterns, not execute commands.

### `rules/process/`

Process-related behavior rules.

Examples:

- privileged process
- unexpected parent process
- missing expected process
- suspicious command-line pattern

### `rules/file/`

File and sensitive-path behavior rules.

Examples:

- browser history access
- keychain access
- SSH directory access
- document directory access

### `rules/network/`

Network behavior rules.

Examples:

- configured endpoint connection
- repeated external connection
- potential large upload
- unexpected port usage

### `rules/persistence/`

Startup and persistence behavior rules.

Examples:

- LaunchDaemon present
- LaunchAgent present
- service enabled
- recurring background execution

### `rules/privilege/`

Privilege and permission behavior rules.

Examples:

- process running as root
- privileged helper observed
- sensitive system path interaction

### `analyzers/`

Analysis modules that read raw logs and rules.

Expected responsibilities:

- Build `timeline.csv`.
- Generate findings.
- Calculate risk score.
- Explain observed behavior.
- Avoid final malicious/not-malicious verdicts.

Analyzers should not collect raw evidence directly when Sensors already provide logs.

### `reporters/`

Report rendering modules.

Reporters transform analyzer output into user-facing artifacts.

### `reporters/text/`

Text report output.

Expected outputs:

- `summary.txt`
- `findings.txt`

### `reporters/html/`

HTML report output.

Expected output:

- `report.html`

### `reporters/json/`

Machine-readable JSON report output.

Expected outputs may include:

- `findings.json`
- `metadata.json`
- `risk_score.json`

JSON output is useful for future automation and integrations.

### `reporters/csv/`

CSV report output.

Expected output:

- `timeline.csv`

### `i18n/`

Internationalization resources.

Report text should be separated from collection and analysis logic.

### `i18n/zh-CN/`

Simplified Chinese report messages and templates.

Expected file:

```text
i18n/zh-CN/messages.conf
```

### `i18n/en-US/`

English report messages and templates.

Expected file:

```text
i18n/en-US/messages.conf
```

### `templates/`

Reusable templates.

Expected content:

- report templates
- profile templates
- rule templates
- plugin templates

Templates should not contain runtime output.

### `plugins/`

Future plugin extension point.

Possible plugin types:

- sensor plugin
- analyzer plugin
- reporter plugin
- profile pack
- rule pack

V2 may define the plugin shape, but should avoid building a complex plugin runtime before the macOS framework is stable.

### `examples/`

Examples for profiles, rules, and reports.

Examples should be clearly marked as examples and should not contain sensitive real endpoint output.

### `docs/`

Design and user documentation.

Current and future documents:

- `SDMon_V2_ARCHITECTURE.md`
- `SDMon_V2_PRODUCT_DIRECTION.md`
- `SDMon_V2_FRAMEWORK_DESIGN.md`
- `SDMon_V2_DIRECTORY_DESIGN.md`
- `README_V2_PROPOSAL.md`

### `tests/`

Test fixtures and validation scripts.

Expected content:

- shell syntax checks
- analyzer fixtures
- report rendering fixtures
- profile validation tests
- rule parsing tests

### `output/`

Local development placeholder for generated output.

Rules:

- Do not commit generated logs.
- Do not commit packet captures.
- Do not commit reports from real systems.
- Do not commit zip packages.
- Prefer real runtime output under `~/Downloads/2026-110`.

## 4. V1.1 To V2 Migration Mapping

The following mapping describes possible future migration targets. It does not instruct immediate file movement.

| V1.1 File | V2 Target | Notes |
| --- | --- | --- |
| `bin/common.sh` | `core/common.sh` | Shared helpers move into framework core. |
| `bin/monitor.sh` | `core/monitor.sh` | Supervisor and orchestration logic move into core. Sensor-specific logic should later split out. |
| `bin/stop.sh` | `core/stop.sh` | Stop logic becomes framework lifecycle control. |
| `bin/analyse.sh` | `core/analyze.sh` | Analysis entrypoint dispatches analyzers and reporters. |
| `bin/summary.sh` | `reporters/text/summary.sh` | Text summary renderer. |
| `bin/findings.sh` | `analyzers/findings.sh` | Findings generation should become analyzer logic. Text rendering can call reporters. |
| `rules/*.conf` | `rules/` | Existing rules split into process, file, network, persistence, and privilege categories. |
| `config.conf` | `core/config.sh` or `profiles/macos/default.conf` | Global config and target-specific profile fields should be separated. |
| `Start_SDMon.command` | `commands/Start_SDMon.command` | GUI-friendly entry wrapper. |
| `Stop_SDMon.command` | `commands/Stop_SDMon.command` | GUI-friendly stop wrapper. |
| `Analyse.command` | `commands/Analyse.command` | GUI-friendly analysis wrapper. |

Potential Sensor split from `bin/monitor.sh`:

| Current Logic | V2 Target |
| --- | --- |
| process snapshots | `sensors/macos/process.sh` |
| `sudo lsof` snapshots | `sensors/macos/network.sh` |
| `tcpdump` capture | `sensors/macos/network.sh` or `sensors/macos/tcpdump.sh` |
| `fs_usage` filtering | `sensors/macos/file.sh` |
| `launchctl print` | `sensors/macos/launchd.sh` |
| system metadata | `sensors/macos/system.sh` |

## 5. Compatibility Strategy

V1.1 compatibility must be preserved during migration.

Compatibility rules:

- V1.1 command files should remain in place in the short term.
- Later versions can manage user-facing entrypoints through a `commands/` directory.
- When old paths are migrated, provide wrappers or clear documentation.
- Existing double-click workflows should not break without a documented replacement.
- Existing output names should remain stable until V2 reporting is tested.

Recommended wrapper strategy:

```text
Start_SDMon.command -> commands/Start_SDMon.command
Stop_SDMon.command  -> commands/Stop_SDMon.command
Analyse.command     -> commands/Analyse.command
```

The root-level `.command` files can eventually become thin wrappers that call the new `commands/` entrypoints.

## 6. Content Not To Execute Immediately

This directory design is not a request to perform migration now.

Do not immediately:

- Move files.
- Rewrite code.
- Implement Windows or Linux.
- Introduce Python.
- Introduce Homebrew dependencies.
- Add a background resident service.
- Replace the current README before V2 is runnable and tested.

V2 should remain Bash/native-tool oriented for the baseline macOS path unless a later design explicitly changes that decision.

## 7. Milestone 5.2 Migration Plan Recommendation

Milestone 5.2 should be a controlled directory migration phase.

Recommended order:

1. Create empty V2 directories.
2. Migrate documentation into the new documentation structure if needed.
3. Migrate command wrappers into `commands/` while keeping root-level compatibility wrappers.
4. Split macOS sensor logic from `bin/monitor.sh` into `sensors/macos/*`.
5. Split profiles into `profiles/macos/`.
6. Split rules into typed `rules/` subdirectories.
7. Move analyzer logic into `analyzers/`.
8. Move text and HTML report rendering into `reporters/`.
9. Add i18n message files.
10. Run syntax checks and V1.1 compatibility tests after each step.
11. Update README last.

Success criteria:

- V1.1 baseline still runs.
- macOS V2 path is runnable.
- No Windows/Linux runtime support is claimed.
- No generated output is committed.
- Documentation clearly explains old and new entrypoints.
