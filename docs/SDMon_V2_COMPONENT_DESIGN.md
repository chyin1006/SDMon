# SDMon V2 Component Design

## 1. Framework Overview

SDMon V2 is a Framework for Agent behavior analysis. Its product positioning can remain cross-platform, while the first implementation priority is macOS.

Framework flow:

```text
Profile
  ↓
Sensor
  ↓
Collector
  ↓
Rule Engine
  ↓
Analyzer
  ↓
Reporter
  ↓
Output
```

Layer responsibilities:

### Profile

Defines the target Agent and analysis scope.

The Profile describes what should be observed, such as process identity, install paths, startup items, network endpoints, sensitive paths, platform, and report language preference.

### Sensor

Represents a platform-specific observation capability.

A Sensor knows what kind of evidence can be collected on a platform, such as process state, file activity, network activity, startup configuration, system metadata, or permission state.

### Collector

Executes a Sensor collection plan and produces raw evidence.

Collectors are responsible for capturing raw events and storing them in a run context. They do not perform final interpretation and do not generate reports.

### Rule Engine

Loads and applies behavior rules.

Rules describe behavior patterns and risk categories. The Rule Engine converts normalized events into rule matches.

### Analyzer

Turns normalized events and rule matches into findings, timelines, and risk explanations.

The Analyzer explains behavior. It does not collect evidence, render final reports, or make unsupported malware verdicts.

### Reporter

Renders analysis results into human-readable or machine-readable artifacts.

Reporters transform findings, timelines, summaries, and metadata into output formats such as text, HTML, CSV, or JSON.

### Output

Stores final artifacts for review and sharing.

Output includes reports, timelines, summaries, findings, and packaged evidence references. Runtime output must remain outside source control.

## 2. Component List

Core SDMon V2 components:

- Core
- Profile Manager
- Sensor Manager
- Collector
- Rule Engine
- Analyzer
- Reporter
- Plugin Manager
- Configuration Manager
- Internationalization Manager
- Log Manager
- Output Manager

These components define the framework boundary. Platform-specific details should remain behind Sensors, Collectors, Profiles, and future plugins.

## 3. Component Responsibilities

### Core

Purpose:

Coordinates the framework lifecycle and connects managers together.

Input:

- Framework command intent.
- Configuration context.
- Selected Profile.

Output:

- Run lifecycle state.
- Component execution plan.
- Framework status.

Lifecycle:

- Initialize.
- Validate configuration.
- Start or stop a run.
- Dispatch collection, analysis, and reporting phases.
- Finalize run state.

Dependencies:

- Configuration Manager.
- Profile Manager.
- Sensor Manager.
- Output Manager.
- Log Manager.

Plugin extension:

- Core itself should not be replaced by plugins.
- Core should expose stable extension points for other components.

### Profile Manager

Purpose:

Loads, validates, and exposes Profile data.

Input:

- Profile identifier or Profile path.
- Default Profile selection.
- Configuration overrides.

Output:

- Validated Profile object.
- Target Agent metadata.
- Platform and language preferences.

Lifecycle:

- Discover available Profiles.
- Load selected Profile.
- Validate required fields.
- Freeze Profile data for a run.

Dependencies:

- Configuration Manager.
- Log Manager.

Plugin extension:

- Profiles may be provided by plugins.
- Profile validation rules should remain framework-owned.

### Sensor Manager

Purpose:

Selects platform Sensors and prepares them for collection.

Input:

- Platform from Profile.
- Sensor capability list.
- Run context.

Output:

- Sensor plan.
- Enabled Sensor list.
- Sensor status metadata.

Lifecycle:

- Discover platform Sensors.
- Match Sensors to Profile requirements.
- Enable or disable Sensors for the run.
- Report Sensor readiness.

Dependencies:

- Profile Manager.
- Plugin Manager.
- Log Manager.

Plugin extension:

- Sensors are plugin extension points.
- V2 should implement macOS Sensors first.
- Windows and Linux Sensors remain future extensions.

### Collector

Purpose:

Collects raw evidence through Sensors.

Input:

- Sensor plan.
- Profile target definitions.
- Run context.

Output:

- Raw Events.
- Raw Logs.
- Collector status.

Lifecycle:

- Prepare collection.
- Start collection.
- Stop collection.
- Flush raw evidence.
- Report collection status.

Dependencies:

- Sensor Manager.
- Output Manager.
- Log Manager.

Plugin extension:

- Collector behavior can be extended through Sensor plugins.
- Framework-level collection lifecycle should remain consistent.

### Rule Engine

Purpose:

Applies behavior rules to normalized events.

Input:

- Normalized Events.
- Rule sets.
- Profile context.

Output:

- Rule Matches.
- Rule metadata.
- Severity hints.

Lifecycle:

- Load rules.
- Validate rule structure.
- Apply rules to normalized events.
- Emit rule matches for Analyzer.

Dependencies:

- Profile Manager.
- Configuration Manager.
- Log Manager.

Plugin extension:

- Rule packs may be provided by plugins.
- Rule execution policy should remain framework-owned.

### Analyzer

Purpose:

Explains observed behavior by transforming events and rule matches into analytical outputs.

Input:

- Raw Events.
- Normalized Events.
- Rule Matches.
- Profile context.
- Collection metadata.

Output:

- Findings.
- Timeline.
- Summary data.
- Risk score.
- Limitations and missing-data notes.

Lifecycle:

- Load run data.
- Normalize raw events if needed.
- Apply rule match context.
- Build findings.
- Build timeline.
- Calculate risk score.
- Emit analyzer output.

Dependencies:

- Rule Engine.
- Output Manager.
- Log Manager.

Plugin extension:

- Analyzer modules may be added by plugins.
- Analyzer modules must not collect raw evidence directly.

### Reporter

Purpose:

Renders analyzer output into final artifacts.

Input:

- Findings.
- Timeline.
- Summary data.
- Risk score.
- Profile metadata.
- Language resources.

Output:

- `summary.txt`.
- `findings.txt`.
- `timeline.csv`.
- `report.html`.
- Optional machine-readable reports.

Lifecycle:

- Select report formats.
- Load language resources.
- Render templates.
- Write report artifacts.
- Report output status.

Dependencies:

- Analyzer.
- Internationalization Manager.
- Output Manager.
- Log Manager.

Plugin extension:

- Reporters are plugin extension points.
- Reporters must not collect raw evidence.

### Plugin Manager

Purpose:

Discovers and validates future extension packages.

Input:

- Plugin registry.
- Plugin metadata.
- Enabled plugin configuration.

Output:

- Registered Sensors.
- Registered Rules.
- Registered Analyzers.
- Registered Reporters.
- Registered Profiles.

Lifecycle:

- Discover plugins.
- Validate plugin metadata.
- Register extension points.
- Disable invalid plugins.

Dependencies:

- Configuration Manager.
- Log Manager.

Plugin extension:

- Plugin Manager manages plugins; it is not itself replaced by plugins.

### Configuration Manager

Purpose:

Loads framework configuration and resolves defaults.

Input:

- Default configuration.
- User configuration.
- Profile configuration.
- Runtime options.

Output:

- Effective configuration.
- Validation errors.
- Feature toggles.

Lifecycle:

- Load defaults.
- Apply user settings.
- Apply Profile settings.
- Apply runtime overrides.
- Emit effective configuration.

Dependencies:

- Log Manager.

Plugin extension:

- Plugins may contribute configuration keys.
- Configuration validation should remain centralized.

### Internationalization Manager

Purpose:

Selects language and resolves user-facing messages.

Input:

- `LANG=auto`.
- `zh-CN`.
- `en-US`.
- System language metadata.
- Message catalogs.

Output:

- Effective report language.
- Localized strings.
- Fallback messages.

Lifecycle:

- Determine language.
- Load message catalog.
- Provide localized messages to Reporters.
- Fall back when a key is missing.

Dependencies:

- Configuration Manager.
- Reporter.
- Log Manager.

Plugin extension:

- Language packs may be added later.
- Report language selection policy should remain framework-owned.

### Log Manager

Purpose:

Provides framework-level logging and status messages.

Input:

- Component lifecycle events.
- Warnings.
- Errors.
- Status updates.

Output:

- Framework logs.
- Component status logs.
- Error records.

Lifecycle:

- Initialize run logging.
- Record component events.
- Record warnings and errors.
- Finalize log output.

Dependencies:

- Output Manager.

Plugin extension:

- Plugins may write through Log Manager.
- Plugins should not bypass framework logging for important lifecycle events.

### Output Manager

Purpose:

Controls output paths and artifact registration.

Input:

- Run context.
- Output configuration.
- Raw logs.
- Analyzer output.
- Reporter output.

Output:

- Run directory.
- Artifact registry.
- Packaged output references.

Lifecycle:

- Create run context.
- Register raw logs.
- Register analyzer artifacts.
- Register report artifacts.
- Finalize package metadata.

Dependencies:

- Configuration Manager.
- Log Manager.

Plugin extension:

- Output formats may be extended through Reporter plugins.
- Output path policy should remain framework-owned.

## 4. Component Communication

Components communicate through structured data and run context boundaries.

Communication rules:

- Sensor does not directly call Reporter.
- Sensor does not directly create final findings.
- Collector does not apply final report templates.
- Rule does not directly generate reports.
- Rule Engine does not collect evidence.
- Analyzer does not collect evidence.
- Analyzer does not own final rendering.
- Reporter does not collect raw events.
- Reporter does not mutate raw logs.
- Plugin components communicate through framework-managed extension points.

Single-responsibility boundaries:

- Profiles define target scope.
- Sensors define platform capabilities.
- Collectors produce raw evidence.
- Rule Engine identifies behavior matches.
- Analyzer explains behavior.
- Reporter renders output.
- Output Manager stores artifacts.

Preferred communication model:

```text
Component Output -> Run Context -> Next Component Input
```

This avoids hidden coupling and keeps each component replaceable.

## 5. Data Flow

Analysis data flow:

```text
Raw Event
  ↓
Normalized Event
  ↓
Rule Match
  ↓
Finding
  ↓
Timeline
  ↓
Summary
  ↓
Report
```

### Raw Event

Original event or observation from a Collector.

Examples:

- Process observation.
- Network connection observation.
- File access observation.
- Startup item observation.
- System metadata observation.

### Normalized Event

Framework-standard representation of a Raw Event.

Normalized Events allow Analyzer and Rule Engine logic to operate without depending on one platform's raw format.

### Rule Match

A behavior rule matched against a Normalized Event.

Rule Matches should include the rule type, severity hint, evidence reference, and matched event identity.

### Finding

Analyzer-generated behavior explanation.

A Finding should explain what was observed, why it matters, and where the evidence came from.

### Timeline

Time-ordered list of important events.

Timeline output supports human review and later report rendering.

### Summary

High-level interpretation of the run.

Summary should include observed behavior, key findings, limitations, and missing data.

### Report

Final user-facing output.

Reports may be text, HTML, CSV, JSON, or future plugin-provided formats.

## 6. Plugin Extension Points

Future plugin extension points:

- Sensor
- Rule
- Analyzer
- Reporter
- Profile

Plugins should not be implemented in this design document. Only interfaces and boundaries are defined.

### Sensor Plugin Interface

Purpose:

Adds a new evidence source or platform collection capability.

Expected interface fields:

- plugin id
- platform
- sensor type
- supported event types
- required permissions
- output event schema

### Rule Plugin Interface

Purpose:

Adds behavior rules or rule packs.

Expected interface fields:

- plugin id
- rule type
- severity model
- supported event schema
- rule metadata

### Analyzer Plugin Interface

Purpose:

Adds specialized behavior interpretation.

Expected interface fields:

- plugin id
- input event types
- input rule match types
- output finding schema
- risk score contribution model

### Reporter Plugin Interface

Purpose:

Adds report output formats or templates.

Expected interface fields:

- plugin id
- report format
- language support
- input artifact requirements
- output artifact list

### Profile Plugin Interface

Purpose:

Adds reusable target Agent profiles.

Expected interface fields:

- plugin id
- profile id
- platform
- target Agent category
- required Sensors
- associated rule packs

Plugin constraints:

- Plugins must preserve read-only behavior.
- Plugins must not bypass framework lifecycle management.
- Plugins must not claim platform support without compatible Sensors.
- Plugins must not collect unrelated personal content.

## 7. Cross-platform Strategy

The Framework model should remain consistent across platforms.

### macOS

macOS is the first priority.

V2 should stabilize the component model with macOS Profiles, macOS Sensors, macOS rules, macOS analyzer output, and macOS reports.

### Windows

Windows support should be added later through Windows Sensors.

The Framework should not change its top-level model when Windows support is added. Windows should provide platform-specific Sensors and Profiles that feed the same normalized event and analysis pipeline.

### Linux

Linux support should be added later through Linux Sensors.

The Framework should not change its top-level model when Linux support is added. Linux should provide platform-specific Sensors and Profiles that feed the same normalized event and analysis pipeline.

Cross-platform invariant:

```text
Profile -> Sensor -> Collector -> Rule Engine -> Analyzer -> Reporter -> Output
```

Platform-specific implementation should stay behind Sensor and Profile boundaries.

## 8. Internationalization

Supported language modes:

- `LANG=auto`
- `zh-CN`
- `en-US`

Language strategy:

- `LANG=auto` detects the system language.
- Chinese systems should produce Chinese reports.
- Non-Chinese systems should produce English reports.
- Users may force `zh-CN` or `en-US`.
- Report templates and prompt text should be separated from collection logic.
- Missing localized strings should fall back to English.

Internationalization responsibilities:

- Internationalization Manager selects the language.
- Reporters request localized strings by key.
- Sensors and Collectors avoid user-facing report prose.
- Analyzer output should remain structured enough for different languages.

## 9. Future Architecture

SDMon should support new Agent categories without changing the Framework core.

Future categories:

- MDM
- EDR
- VPN
- Zero Trust
- Enterprise Agent

How future support should be added:

- Add or extend Profiles for the Agent category.
- Add Rule packs for category-specific behavior patterns.
- Add platform Sensors only when the platform requires new evidence sources.
- Add Analyzer plugins for specialized interpretation when generic analysis is insufficient.
- Add Reporter templates only when output requirements differ.

Framework components should remain stable:

- Profile Manager still loads target scope.
- Sensor Manager still selects collection capabilities.
- Rule Engine still applies behavior rules.
- Analyzer still produces findings and timeline.
- Reporter still renders output.

This lets SDMon grow from macOS Agent monitoring into broader enterprise Agent behavior analysis without rewriting the Framework.

## 10. Design Principles

### Single Responsibility

Each component should have one clear job.

### Loose Coupling

Components should communicate through explicit inputs, outputs, and run context artifacts.

### Plugin First

Future variability should be handled through extension points rather than hard-coded product assumptions.

### Framework Stable

The Framework lifecycle should remain stable as new platforms and Agent categories are added.

### Sensor Replaceable

Sensors should be replaceable or extendable without changing Analyzer or Reporter responsibilities.

### Analyzer Independent

Analyzers should work from normalized events and rule matches, not from one Collector's private format.

### Reporter Independent

Reporters should render analyzer output and should not collect evidence or perform platform-specific logic.

### Language Independent

Reports should be generated from language resources rather than hard-coded prose.

### Cross-platform Ready

The Framework should preserve a common model for macOS, future Windows, and future Linux support while implementing only macOS first in V2.
