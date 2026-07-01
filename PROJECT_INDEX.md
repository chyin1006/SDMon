# SDMon Project Index

This file is the single source of truth for SDMon project knowledge navigation.

All developers, including ChatGPT, Codex, Copilot, Claude, and other AI assistants, should read `PROJECT_INDEX.md` before starting any development task.

`PROJECT_INDEX.md` does not store detailed design. It only explains where the authoritative documents live, how they relate to each other, and which documents should be read for each kind of task.

## 1. Document Positioning

`PROJECT_INDEX.md` is the first document to read before making project decisions or code changes.

Purpose:

- Provide the unique knowledge entry point for SDMon.
- Route developers to the smallest relevant document set.
- Prevent default full-document rereads when a focused module read is enough.
- Keep V1 legacy, V2 framework, RFC, and planning documents easy to discover.
- Help AI assistants avoid mixing implementation work with unrelated architecture documents.

Rules:

- Start here before any development task.
- Use this file for navigation only.
- Do not copy detailed design content into this file.
- When adding new documents, RFCs, or framework modules, update this index.

## 2. Project Overview

```text
SDMon
├── V1 Legacy
│   ├── Bash-only macOS targeted monitor
│   ├── demo-agent / demo-helper baseline
│   └── Read-only output under ~/Downloads/2026-110
│
├── V2 Framework
│   ├── Cross-platform Agent Behavior Analysis Framework
│   ├── macOS first implementation strategy
│   └── Windows / Linux extension points reserved
│
├── Profiles
│   └── Target Agent / App / Service definitions
│
├── Sensors
│   ├── macOS process sensor
│   ├── macOS file sensor
│   ├── macOS network sensor
│   ├── macOS launchd sensor
│   ├── macOS system sensor
│   └── macOS permission sensor
│
├── Rule Engine
│   └── Behavior rules that generate Findings from Normalized Events
│
├── Analyzer
│   └── Timeline, aggregation, confidence, correlation, and risk scoring
│
├── Reporter
│   └── txt / html / json / csv report rendering
│
├── Configuration
│   └── config.conf + profile.conf + rule.conf layered configuration
│
├── RFC
│   └── Long-lived architecture decisions and stable contracts
│
├── Tests
│   └── Future syntax, analyzer, fixture, and framework tests
│
└── Future Platforms
    ├── Windows Sensor
    └── Linux Sensor
```

## 3. Document Index

| Document | Purpose | Required Reading |
| --- | --- | --- |
| `PROJECT_INDEX.md` | Single source of truth for project knowledge navigation. | Yes, always |
| `README.md` | Current public project README for V1.1 usage and baseline behavior. | Yes for user-facing or onboarding work |
| `AGENTS.md` | Development rules for agents and V1.1 implementation constraints. | Yes before code changes |
| `PLANS.md` | V1.1 implementation plan and testing steps. | Yes for V1.1 work |
| `ROADMAP.md` | Version roadmap from V1.1 toward broader agent analysis. | Yes for planning work |
| `DECISIONS.md` | Accepted project decisions such as Bash-only, read-only, output location. | Yes before code or architecture changes |
| `TODO.md` | Current task checklist and acceptance notes. | Yes for implementation planning |
| `docs/SDMon_V2_ARCHITECTURE.md` | V2 architecture, major components, and migration direction. | Yes for V2 architecture work |
| `docs/SDMon_V2_PRODUCT_DIRECTION.md` | Product positioning, macOS-first strategy, platform roadmap, report language direction. | Yes for product or roadmap work |
| `docs/SDMon_V2_FRAMEWORK_DESIGN.md` | Framework design principles, data flow, module layout, and V2 boundaries. | Yes for V2 framework work |
| `docs/README_V2_PROPOSAL.md` | Proposed future GitHub README for V2 positioning and user-facing narrative. | No, only for README or messaging work |
| `docs/SDMon_V2_DIRECTORY_DESIGN.md` | Target V2 directory layout and V1.1 migration mapping. | Yes for structure or migration work |
| `docs/SDMon_V2_COMPONENT_DESIGN.md` | Core component list, responsibilities, dependencies, and communication rules. | Yes for component design work |
| `docs/SDMon_V2_PROFILE_ENGINE_DESIGN.md` | Profile Engine goals, fields, lifecycle, validation, and examples. | Yes for Profile work |
| `docs/SDMon_V2_RULE_ENGINE_DESIGN.md` | Rule Engine goals, rule format, risk levels, findings, and rule categories. | Yes for Rule work |
| `docs/SDMon_V2_ANALYZER_DESIGN.md` | Analyzer responsibilities, timeline, risk scoring, confidence, and report data. | Yes for Analyzer work |
| `docs/SDMon_V2_REPORTER_DESIGN.md` | Reporter responsibilities, report outputs, templates, i18n, and long-term exports. | Yes for Reporter work |
| `docs/SDMon_V2_SENSOR_DESIGN.md` | Sensor responsibilities, macOS Sensor types, normalized events, permissions, and migration. | Yes for Sensor work |
| `docs/SDMon_V2_CONFIGURATION_DESIGN.md` | Configuration layers, validation, safety, examples, and V1.1 migration. | Yes for Configuration work |
| `docs/rfc/README.md` | RFC system purpose, status values, naming rules, and RFC structure. | Yes before adding RFCs |
| `docs/rfc/RFC-0001-event-model.md` | Normalized Event Model, event categories, fields, examples, storage, and V1.1 migration. | Yes for Sensor, Rule, Analyzer, Reporter, or event model work |

## 4. Module Dependency Flow

Core behavior pipeline:

```text
Profile
  ↓
Sensor
  ↓
Normalized Event
  ↓
Rule Engine
  ↓
Finding
  ↓
Analyzer
  ↓
Reporter
```

Dependency rules:

- Profile defines target context.
- Sensor collects raw evidence and emits Normalized Events.
- Rule Engine consumes Normalized Events and emits Findings.
- Analyzer consumes Findings and events to produce timelines, summaries, risk scores, and report data.
- Reporter renders Analyzer output into final artifacts.
- Configuration affects all layers but should not execute arbitrary behavior.
- RFCs define stable contracts that modules should follow.

## 5. AI Reading Strategy

AI assistants should use minimum necessary reading.

Do not default to reading the entire `docs/` directory for every task.

### If modifying Rule behavior

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_RULE_ENGINE_DESIGN.md`
- `docs/SDMon_V2_CONFIGURATION_DESIGN.md`
- `docs/rfc/RFC-0001-event-model.md`

Do not read by default:

- `docs/SDMon_V2_REPORTER_DESIGN.md`

### If modifying Reporter behavior

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_REPORTER_DESIGN.md`
- `docs/SDMon_V2_ANALYZER_DESIGN.md`
- `docs/rfc/README.md`
- `docs/rfc/RFC-0001-event-model.md`

Do not read by default:

- `docs/SDMon_V2_RULE_ENGINE_DESIGN.md`

### If modifying Sensor behavior

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_SENSOR_DESIGN.md`
- `docs/SDMon_V2_PROFILE_ENGINE_DESIGN.md`
- `docs/SDMon_V2_CONFIGURATION_DESIGN.md`
- `docs/rfc/README.md`
- `docs/rfc/RFC-0001-event-model.md`

Do not read by default:

- `docs/SDMon_V2_REPORTER_DESIGN.md`

### If modifying Profile behavior

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_PROFILE_ENGINE_DESIGN.md`
- `docs/SDMon_V2_CONFIGURATION_DESIGN.md`
- `docs/rfc/RFC-0001-event-model.md`

### If modifying Analyzer behavior

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_ANALYZER_DESIGN.md`
- `docs/SDMon_V2_RULE_ENGINE_DESIGN.md`
- `docs/rfc/RFC-0001-event-model.md`

### If modifying Configuration behavior

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_CONFIGURATION_DESIGN.md`
- `docs/SDMon_V2_PROFILE_ENGINE_DESIGN.md`
- `docs/SDMon_V2_RULE_ENGINE_DESIGN.md`

### If modifying directory structure

Read:

- `PROJECT_INDEX.md`
- `docs/SDMon_V2_DIRECTORY_DESIGN.md`
- `docs/SDMon_V2_FRAMEWORK_DESIGN.md`
- `docs/SDMon_V2_COMPONENT_DESIGN.md`

### If modifying public README or product messaging

Read:

- `PROJECT_INDEX.md`
- `README.md`
- `docs/README_V2_PROPOSAL.md`
- `docs/SDMon_V2_PRODUCT_DIRECTION.md`

## 6. Document Categories

### Core

- `PROJECT_INDEX.md`
- `README.md`
- `AGENTS.md`
- `DECISIONS.md`

### Architecture

- `docs/SDMon_V2_ARCHITECTURE.md`
- `docs/SDMon_V2_PRODUCT_DIRECTION.md`
- `docs/SDMon_V2_FRAMEWORK_DESIGN.md`
- `docs/SDMon_V2_DIRECTORY_DESIGN.md`
- `docs/SDMon_V2_COMPONENT_DESIGN.md`
- `docs/SDMon_V2_PROFILE_ENGINE_DESIGN.md`
- `docs/SDMon_V2_RULE_ENGINE_DESIGN.md`
- `docs/SDMon_V2_ANALYZER_DESIGN.md`
- `docs/SDMon_V2_REPORTER_DESIGN.md`
- `docs/SDMon_V2_SENSOR_DESIGN.md`
- `docs/SDMon_V2_CONFIGURATION_DESIGN.md`

### RFC

- `docs/rfc/README.md`
- `docs/rfc/RFC-0001-event-model.md`

### Planning

- `PLANS.md`
- `ROADMAP.md`
- `TODO.md`

### Legacy

- `README.md`
- `AGENTS.md`
- `PLANS.md`
- `DECISIONS.md`
- `TODO.md`

### Reference

- `docs/README_V2_PROPOSAL.md`

## 7. Architecture Status

Current status:

```text
Architecture Frozen
```

Coding stage:

```text
Preparing V2 Alpha
```

Meaning:

- The current V2 architecture documents define the intended framework direction.
- New implementation work should align with the documented module boundaries.
- New architecture changes should be proposed through docs or RFCs before large code changes.
- V2 remains macOS first.
- Windows and Linux remain future platform extensions.

## 8. Future Development Order

Recommended development sequence:

```text
V2 Alpha
  ↓
Plugin API
  ↓
Windows Sensor
  ↓
Linux Sensor
  ↓
HTML Report
  ↓
Public Beta
  ↓
1.0 Release
```

Notes:

- V2 Alpha should prioritize stable macOS framework behavior.
- Plugin API should come after the core framework contracts are stable.
- Windows and Linux Sensors should not be implemented before the macOS Sensor and event model are proven.
- HTML Report should build on Analyzer and Reporter contracts.
- Public Beta should wait until documentation, tests, and output behavior are consistent.

## 9. AI Development Rules

Before any code modification, an AI assistant must:

1. Read `PROJECT_INDEX.md`.
2. Identify the target module.
3. Read only the related module documents listed in the AI Reading Strategy.
4. Check `DECISIONS.md` for global constraints when changing code behavior.
5. Avoid reading the entire `docs/` directory by default.
6. Avoid modifying README unless explicitly requested.
7. Avoid moving files unless explicitly requested.
8. Avoid changing V1.1 logic when the task is V2 documentation or architecture only.
9. Avoid committing runtime output, logs, packet captures, zip files, or generated reports.
10. Preserve read-only monitoring behavior.

Code changes should follow the smallest safe scope. Documentation changes should update this index when they add new knowledge entry points.

## 10. Maintenance Principles

When adding project knowledge:

- New document: update `PROJECT_INDEX.md`.
- New RFC: add it to the Document Index and RFC category.
- New module: add it to the module dependency flow when it affects architecture.
- New platform: add it to Future Platforms and relevant reading strategy.
- New report type: update Reporter references.
- New event category: update `docs/rfc/RFC-0001-event-model.md` and this index if it changes dependencies.
- New configuration layer: update Configuration references and AI reading strategy.

Maintenance rules:

- Keep this file short enough to navigate quickly.
- Do not duplicate detailed design content here.
- Prefer links to authoritative documents.
- Keep Required Reading values honest and task-specific.
- Keep module dependencies current.
- Treat this file as the first stop, not the whole map.
