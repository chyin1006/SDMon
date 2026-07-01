# SDMon V2 Product Direction

## 1. Project Name

Primary name:

- SDMon

Full name:

- Security Dynamic Monitor

The short name should be used in scripts, directories, and command wrappers. The full name should be used in product descriptions, documentation, and reports when additional clarity is useful.

## 2. Product Positioning

SDMon is a Cross-platform Agent Behavior Analysis Framework.

Chinese positioning:

- 跨平台 Agent 行为分析框架

SDMon is designed to help analysts observe and explain the runtime behavior of endpoint agents in a controlled, evidence-first, read-only way. It should collect process, file, network, startup, permission, and sensitive-path evidence, then produce reports that help users understand what an agent did during the observation window.

The product is not limited to one vendor or one agent family. V2 should turn the current macOS targeted monitor into a reusable framework for agent behavior analysis.

## 3. Current Implementation Strategy

The current implementation strategy is macOS first.

For V2:

- Focus on making the macOS Agent analysis framework stable first.
- Do not develop Windows and Linux support at the same time.
- Keep Windows and Linux as architecture-level extension targets.
- Implement Windows and Linux support in later versions after the macOS framework is reliable.

This keeps the project practical. V1.1 already provides a working macOS baseline, so V2 should improve the architecture, profile model, rules model, collector boundaries, analyzer pipeline, and report output on macOS before expanding to other platforms.

## 4. Support Scope

Long-term SDMon support scope includes:

- macOS Agent
- Windows Agent
- Linux Agent
- Enterprise VPN client
- EDR Agent
- MDM Agent
- Zero Trust Agent
- AI Agent

Support does not mean every category is implemented in V2. V2 should define the framework and stabilize macOS support. Other platforms and target classes can be added through future Sensor, Profile, and Rules extensions.

## 5. Version Roadmap

Recommended version direction:

- V1.1: macOS targeted monitor baseline
- V2: macOS framework architecture
- V3: Windows support
- V4: Linux support

The roadmap should stay incremental. Each version should preserve the core read-only behavior and avoid mixing platform expansion with too many unrelated product changes.

## 6. Why macOS First

SDMon should start with macOS for these reasons:

- The project already has a runnable V1.1 macOS foundation.
- The user's current primary test environment is macOS.
- macOS, Windows, and Linux collection methods differ significantly.
- Supporting multiple operating systems from the beginning would increase complexity and bugs.

macOS-first does not mean macOS-only. It means the framework should prove its model on the platform that already has working code and active test coverage.

## 7. Why Keep A Cross-platform Architecture

SDMon should keep a cross-platform architecture because the core model of agent behavior analysis is shared across platforms.

Reusable concepts include:

- Processes
- Files
- Network connections
- Startup items
- Permissions
- Sensitive paths
- Reports

The platform-specific implementation will differ, but the analysis model can remain consistent. Future versions can extend SDMon through platform-specific Sensors, Profiles, and Rules:

- Sensors collect raw evidence from each operating system.
- Profiles define target agents and expected behavior.
- Rules define what evidence should be highlighted.
- Analyzers normalize raw evidence into findings.
- Report templates present findings in a user-readable form.

This lets SDMon support new platforms without rewriting the whole product model.

## 8. Report Language Strategy

V2 should support report language selection through `REPORT_LANG`.

Default behavior:

```bash
REPORT_LANG="auto"
```

When `REPORT_LANG="auto"`:

- SDMon should detect the system language automatically.
- Chinese systems should produce Chinese reports.
- Non-Chinese systems should produce English reports.

Users should be able to force the report language in `config.conf` or in a selected profile:

```bash
REPORT_LANG="zh-CN"
REPORT_LANG="en-US"
```

V2 report outputs should include at least:

- `summary.txt`
- `findings.txt`
- `timeline.csv`
- `report.html`

Report templates should be separated from collection logic. Collectors should only gather evidence. Analyzers should convert evidence into findings. Report templates should decide how those findings are displayed in each language.

A later i18n directory should be designed, for example:

```text
i18n/
  zh-CN/
    messages.conf
  en-US/
    messages.conf
```

Recommended responsibilities:

- `REPORT_LANG` chooses the language.
- `i18n/*/messages.conf` stores user-facing strings.
- Report generators load messages by key.
- Collectors and analyzers avoid hard-coded report prose where practical.

## 9. What SDMon Does Not Do

SDMon must not become an offensive, destructive, or hidden monitoring tool.

Out of scope:

- Do not build malware.
- Do not bypass security software.
- Do not uninstall, damage, disable, or destroy agents.
- Do not perform hidden monitoring.
- Do not perform employee monitoring without awareness.
- Do not collect personal content unrelated to target analysis.

SDMon is for transparent, controlled, read-only behavior analysis. It should collect only the evidence needed to understand the selected target agent during the observation window.

## 10. Recommended Future README Updates

A future README update should:

- Upgrade the project positioning from a macOS targeted monitor to a cross-platform agent behavior analysis framework.
- Clearly state that the current implementation is macOS first.
- Add bilingual project descriptions in English and Chinese.
- Add report language auto-detection details.

Suggested README positioning:

```text
SDMon, Security Dynamic Monitor, is a cross-platform Agent behavior analysis framework.

SDMon（Security Dynamic Monitor）是一个跨平台 Agent 行为分析框架。

Current implementation: macOS first. V2 focuses on stabilizing the macOS Agent analysis framework while preserving future Windows and Linux extension points.
```

Suggested README report language note:

```text
Reports use REPORT_LANG="auto" by default. SDMon should generate Chinese reports on Chinese systems and English reports on non-Chinese systems. Users can force REPORT_LANG="zh-CN" or REPORT_LANG="en-US" in config.conf or a profile.
```

README updates should be made in a later commit so this document-only change remains scoped to product direction.
