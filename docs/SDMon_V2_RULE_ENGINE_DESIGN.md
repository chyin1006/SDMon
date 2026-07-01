# SDMon V2 Rule Engine Design

This document defines the SDMon V2 Rule Engine at the framework design level. It does not define concrete implementation code and does not change the V1.1 baseline.

## 1. Rule Engine Goals

The Rule Engine separates behavior judgment logic from framework code.

Primary goals:

- Move behavior judgment logic out of code and into Rule files.
- Keep Rules independent from any specific Agent, vendor, App, or Service.
- Use Sensor-collected events and Profile context to generate Findings.
- Support future expansion for MDM, EDR, VPN, Zero Trust, AI Agent, and Custom Agent targets.
- Keep Rule behavior readable, auditable, and safe.
- Keep Rules focused on risk explanation rather than remediation.
- Preserve SDMon's read-only analysis model.

A Rule describes a behavior pattern worth highlighting. It does not collect evidence, alter the target, or render the final report.

## 2. Rule Engine Position In The Framework

The Rule Engine sits between normalized evidence and analysis output.

Framework data flow:

```text
Profile
  ↓
Sensor
  ↓
Raw Event
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

Layer responsibilities:

- Profile defines the target context.
- Sensor collects raw evidence in a read-only way.
- Raw Event preserves the original observation.
- Normalized Event gives Rules a platform-neutral event shape.
- Rule Engine applies behavior rules to normalized events.
- Finding records a matched behavior and its evidence.
- Analyzer aggregates Findings into timelines, correlations, and scores.
- Reporter renders final outputs for users.

The Rule Engine should not depend on one macOS tool output format. It should consume normalized events produced by the framework.

## 3. Rule Responsibilities

A Rule is responsible for deciding whether a specific behavior signal deserves attention.

A Rule should define:

- Whether a behavior category is notable.
- Risk level.
- Risk explanation.
- Evidence fields.
- Recommended action.

A Rule may describe behavior such as:

- A target process accessed a sensitive path.
- A target process connected to a configured endpoint.
- A target service appears persistent.
- A process runs with elevated privileges.
- A large outbound transfer was observed.

A Rule is not responsible for:

- Collecting data.
- Starting or stopping Sensors.
- Generating final reports.
- Modifying or intercepting the target Agent.
- Deleting files.
- Quarantining files.
- Blocking network connections.
- Making final malicious or benign verdicts.

Rules are evidence interpretation hints. They are not remediation instructions.

## 4. Rule Types

V2 Rule types should cover the core Agent behavior model.

Required Rule types:

- process rule
- file rule
- network rule
- launchd / persistence rule
- privilege rule
- sensitive path rule
- upload / traffic rule
- correlation rule
- risk scoring rule

### process rule

Identifies notable process state or process metadata.

Examples:

- Target process observed.
- Expected process missing.
- Process running under a privileged user.
- Process command line includes a notable argument.

### file rule

Identifies notable file access or file inventory behavior.

Examples:

- Target path exists.
- Target process accessed a configured path.
- File operation occurred under an application support directory.

### network rule

Identifies notable network behavior.

Examples:

- Connection to configured endpoint.
- Connection to unexpected port.
- Repeated outbound connection.

### launchd / persistence rule

Identifies startup or persistence behavior.

Examples:

- LaunchDaemon exists.
- LaunchAgent exists.
- Startup label is active.
- Persistent helper is associated with the target.

### privilege rule

Identifies privilege-related behavior.

Examples:

- Process runs as root.
- Privileged helper is present.
- Process accesses privileged system areas.

### sensitive path rule

Identifies access to sensitive user or system paths.

Examples:

- Keychain access.
- SSH private key access.
- Browser credential store access.
- Documents, Desktop, Downloads, Photos, or messaging data access.

### upload / traffic rule

Identifies notable transfer behavior.

Examples:

- Large outbound transfer.
- Repeated upload bursts.
- Upload to configured external endpoint.

### correlation rule

Combines multiple Findings or events into a higher-level behavior signal.

Examples:

- Sensitive file access followed by network upload.
- Persistence plus privileged process.
- Unexpected process plus external connection.

### risk scoring rule

Contributes to risk score calculation.

Examples:

- Adds weight for high-severity sensitive path access.
- Adds weight for repeated evidence.
- Adds weight for correlated behavior.

## 5. Rule File Format Design

V2 should use a Bash-friendly `.conf` format for Rules.

Reasons:

- Keeps the baseline macOS workflow dependency-free.
- Avoids Python, Homebrew, or external parsers.
- Allows simple editing and review.
- Matches the project direction of Bash-friendly configuration.
- Keeps Rule files easy to copy, audit, and version.

Recommended Rule format:

```bash
RULE_ID="file_sensitive_keychain_access"
RULE_NAME="Sensitive Keychain Access"
RULE_TYPE="file"
RULE_LEVEL="high"
RULE_CATEGORY="sensitive_access"
RULE_DESCRIPTION="Detects access to macOS Keychain related files."
RULE_MATCH_FIELD="file_path"
RULE_MATCH_PATTERN="Library/Keychains"
RULE_EVIDENCE_FIELDS="timestamp process_name pid file_path operation"
RULE_RECOMMENDATION="Review whether the target agent is expected to access Keychain data."
RULE_TAGS="macos,keychain,credential-access"
RULE_ENABLED="true"
```

Recommended optional fields:

```bash
RULE_WEIGHT="1.0"
RULE_CONFIDENCE="medium"
RULE_PLATFORM="macos"
RULE_EVENT_TYPE="file_access"
RULE_SCOPE="common"
```

Format design rules:

- `RULE_ID` should be stable and machine-friendly.
- `RULE_NAME` should be human-readable.
- `RULE_TYPE` should map to a known Rule type.
- `RULE_LEVEL` should map to a known risk level.
- `RULE_MATCH_FIELD` should reference a normalized event field.
- `RULE_MATCH_PATTERN` should be a safe literal or simple pattern.
- `RULE_ENABLED="false"` should disable the Rule without deleting it.
- Rule files should not execute commands.
- Rule files should not contain credentials, tokens, or private content.

Future formats:

- YAML may be useful for richer nested metadata.
- JSON may be useful for machine-generated rules or external integrations.
- V2 should start with `.conf` to stay Bash-friendly.
- Future YAML or JSON support should preserve the same conceptual Rule schema.

## 6. Rule Lifecycle

Rule lifecycle stages:

```text
discover -> load -> validate -> apply -> match -> generate finding -> deduplicate -> score -> output
```

### discover

The Rule Engine finds available Rule files in supported Rule directories.

Discovery should include common Rules, platform Rules, and optional Profile-selected Rules.

### load

The Rule Engine loads enabled Rule definitions into the active run context.

Loading should not execute arbitrary code from Rule files.

### validate

The Rule Engine validates required fields, known types, known levels, and supported match fields.

Invalid Rules should be skipped or fail the run according to framework policy.

### apply

The Rule Engine selects Rules relevant to the active Profile, platform, and enabled Rule set.

### match

The Rule Engine compares normalized events against Rule match fields and patterns.

A match should preserve the source event reference.

### generate finding

A matched Rule produces a structured Finding.

The Finding should include Rule metadata, Profile context, evidence fields, risk level, score, confidence, and source event reference.

### deduplicate

Repeated matches should be aggregated when they represent the same behavior signal within a short time window.

### score

The Rule Engine may assign initial risk score hints from Rule level, Rule weight, evidence count, Profile weight, and confidence.

Final scoring may be refined by the Analyzer.

### output

The Rule Engine outputs Rule Matches and Findings for Analyzer consumption.

The Rule Engine does not render final user reports.

## 7. Rule Validation

Rule validation should make Rule behavior predictable and safe.

Required fields:

- `RULE_ID`
- `RULE_NAME`
- `RULE_TYPE`
- `RULE_LEVEL`
- `RULE_MATCH_FIELD`
- `RULE_MATCH_PATTERN`

Optional fields:

- `RULE_DESCRIPTION`
- `RULE_CATEGORY`
- `RULE_EVIDENCE_FIELDS`
- `RULE_RECOMMENDATION`
- `RULE_TAGS`
- `RULE_ENABLED`
- `RULE_WEIGHT`
- `RULE_CONFIDENCE`
- `RULE_PLATFORM`
- `RULE_EVENT_TYPE`
- `RULE_SCOPE`

Recommended validation rules:

- `RULE_ID` should be lowercase, stable, and filename-friendly.
- `RULE_TYPE` should be one of the supported Rule types.
- `RULE_LEVEL` should be one of `critical`, `high`, `medium`, `low`, or `info`.
- `RULE_MATCH_FIELD` should exist in the normalized event schema for the selected Rule type.
- `RULE_MATCH_PATTERN` should not be empty.
- `RULE_ENABLED` should default to `true` when omitted.
- `RULE_WEIGHT` should be numeric when present.
- `RULE_CONFIDENCE` should use a defined confidence value when present.
- Platform-specific Rules should not be applied to incompatible platforms.

Validation output should explain the exact Rule and field that failed.

## 8. Risk Level And Risk Score Design

Risk Level represents severity.

Recommended Risk Levels:

| Risk Level | Score Range | Meaning |
| --- | --- | --- |
| critical | 90-100 | Strong behavior signal with potentially severe impact. |
| high | 70-89 | Important behavior signal that deserves review. |
| medium | 40-69 | Meaningful behavior signal with contextual risk. |
| low | 10-39 | Weak or expected signal that may still be useful. |
| info | 0-9 | Informational observation. |

Confidence represents how trustworthy the match is.

Recommended Confidence values:

- high
- medium
- low
- unknown

Risk Score may be calculated from:

- Rule Level.
- Profile Weight.
- Evidence Count.
- Correlation.
- Rule Weight.
- Confidence.

Example scoring factors:

```text
risk_score = base_level_score * rule_weight * profile_weight * confidence_factor + evidence_bonus + correlation_bonus
```

This is a conceptual model, not an implementation requirement.

Scoring principles:

- Risk Score is not a malware verdict.
- Risk Score should be explainable.
- Score contributors should be visible in Analyzer output.
- Missing data should lower confidence or appear as a limitation.
- Repeated events should be counted carefully to avoid inflated scores.

## 9. Rule And Profile Relationship

Profiles provide target context. Rules provide behavior logic.

Relationship principles:

- Profile provides target context.
- Rule does not hard-code specific software when the behavior can be generic.
- The same Rule can apply to multiple Profiles.
- Profile can adjust Rule weight.
- Profile can enable or disable specific Rules.
- Profile can select common, platform-specific, or category-specific Rule packs.

Examples:

- A Keychain access Rule can apply to MDM, EDR, VPN, Zero Trust, AI Agent, and Custom Agent Profiles.
- A Profile identifies the target process or install path that makes the event relevant.
- A VPN Profile may lower the weight of expected network tunnel behavior.
- An AI Agent Profile may raise the weight of unexpected SSH private key access.

Profile-controlled Rule behavior should remain transparent in reports and metadata.

## 10. Rule And Sensor Relationship

Sensors produce Normalized Events. Rules consume Normalized Events.

Rules should not know the low-level data source.

A Rule should not depend on whether an event came from:

- `fs_usage`
- `lsof`
- `tcpdump`
- EndpointSecurity
- Windows Event Log
- Linux audit logs
- any future Sensor source

Relationship principles:

- Sensor collects raw evidence.
- Sensor or framework normalizes events.
- Rule consumes normalized event fields.
- Rule preserves source event references for evidence.
- Rule does not start, stop, or configure Sensors directly.

This separation allows future Windows and Linux Sensors to feed the same Rule model.

## 11. Rule And Analyzer Relationship

The Rule Engine generates Findings. The Analyzer aggregates and explains them.

Rule responsibilities:

- Match normalized events.
- Generate initial Finding records.
- Provide risk level, score hints, confidence, and evidence references.

Analyzer responsibilities:

- Aggregate Findings.
- Build timeline.
- Perform correlation analysis.
- Refine risk scoring.
- Add limitations and missing-data notes.
- Prepare structured output for Reporters.

A Rule does not generate the final report.

The Analyzer should be able to run repeatedly against the same raw logs, normalized events, and Rule outputs without modifying raw evidence.

## 12. Finding Data Structure

A Finding is the structured output produced from a Rule match.

Recommended Finding fields:

```text
FINDING_ID
RULE_ID
PROFILE_ID
TIMESTAMP
RISK_LEVEL
RISK_SCORE
CONFIDENCE
TITLE
DESCRIPTION
EVIDENCE
RECOMMENDATION
TAGS
SOURCE_EVENT
```

Recommended extended fields:

```text
RULE_TYPE
RULE_CATEGORY
PROCESS_NAME
PID
FILE_PATH
ENDPOINT
OPERATION
EVIDENCE_COUNT
FIRST_SEEN
LAST_SEEN
DEDUP_KEY
CORRELATION_ID
```

Field notes:

- `FINDING_ID` should uniquely identify the Finding within one run.
- `RULE_ID` links the Finding back to the Rule definition.
- `PROFILE_ID` links the Finding to the target context.
- `TIMESTAMP` records when the evidence was observed or when the Finding was generated.
- `RISK_LEVEL` records severity.
- `RISK_SCORE` records numeric risk.
- `CONFIDENCE` records match confidence.
- `EVIDENCE` should reference source data, not copy unrelated personal content.
- `SOURCE_EVENT` should point back to the normalized event or raw evidence reference.

## 13. Deduplication Strategy

Repeated matches should be aggregated when they describe the same behavior signal.

Deduplication principle:

The same Rule, same Process, same Path, or same Endpoint repeating in a short time window should become one Finding with evidence count and first/last seen timestamps.

Recommended deduplication key fields:

- `RULE_ID`
- `PROFILE_ID`
- `PROCESS_NAME`
- `FILE_PATH`
- `ENDPOINT`
- `OPERATION`
- time window bucket

Deduplication output should preserve:

- First seen time.
- Last seen time.
- Evidence count.
- Representative evidence reference.
- Optional sample evidence references.

Deduplication should not hide important changes. If risk level, endpoint, file path, or process identity changes materially, a separate Finding may be appropriate.

## 14. Correlation Rules

Correlation Rules combine multiple events or Findings into a higher-level behavior signal.

Future correlation examples:

- File access + network upload.
- Persistence + high-privilege process.
- Sensitive path access + large traffic upload.
- Unexpected process + external connection.

V2 should design the correlation model but should not require complex correlation implementation before the macOS baseline is stable.

Correlation design principles:

- Correlation should operate on Findings or normalized events.
- Correlation should preserve evidence from each contributing signal.
- Correlation should produce a clear explanation.
- Correlation should not imply maliciousness without evidence.
- Correlation score contribution should be explainable.

Example conceptual correlation:

```text
sensitive_file_access + large_upload_to_external_endpoint -> elevated review priority
```

## 15. Rule Directory Categories

Recommended Rule directories:

```text
rules/process/
rules/file/
rules/network/
rules/persistence/
rules/privilege/
rules/correlation/
rules/risk/
rules/macos/
rules/common/
```

Directory purpose:

- `rules/process/`: process state and process metadata Rules.
- `rules/file/`: file operation and file inventory Rules.
- `rules/network/`: connection, endpoint, and traffic Rules.
- `rules/persistence/`: launchd, startup, and persistence Rules.
- `rules/privilege/`: privilege and permission Rules.
- `rules/correlation/`: multi-signal correlation Rules.
- `rules/risk/`: scoring and weighting Rules.
- `rules/macos/`: macOS-specific behavior Rules.
- `rules/common/`: cross-platform behavior Rules.

V2 should start with a small, useful set of macOS and common Rules. More categories can be populated incrementally.

## 16. Rule Examples

These examples define Rule shape, not implementation code.

### sensitive Keychain access

```bash
RULE_ID="file_sensitive_keychain_access"
RULE_NAME="Sensitive Keychain Access"
RULE_TYPE="sensitive_path"
RULE_LEVEL="high"
RULE_CATEGORY="credential_access"
RULE_DESCRIPTION="Detects access to macOS Keychain related files."
RULE_MATCH_FIELD="file_path"
RULE_MATCH_PATTERN="Library/Keychains"
RULE_EVIDENCE_FIELDS="timestamp process_name pid file_path operation"
RULE_RECOMMENDATION="Review whether the target agent is expected to access Keychain data."
RULE_TAGS="macos,keychain,credential-access"
RULE_ENABLED="true"
RULE_WEIGHT="1.0"
RULE_CONFIDENCE="medium"
```

### SSH private key access

```bash
RULE_ID="file_sensitive_ssh_private_key_access"
RULE_NAME="SSH Private Key Access"
RULE_TYPE="sensitive_path"
RULE_LEVEL="high"
RULE_CATEGORY="credential_access"
RULE_DESCRIPTION="Detects access to SSH private key paths."
RULE_MATCH_FIELD="file_path"
RULE_MATCH_PATTERN=".ssh/id_"
RULE_EVIDENCE_FIELDS="timestamp process_name pid file_path operation"
RULE_RECOMMENDATION="Confirm whether the target agent is expected to read SSH private keys."
RULE_TAGS="ssh,private-key,credential-access"
RULE_ENABLED="true"
RULE_WEIGHT="1.0"
RULE_CONFIDENCE="medium"
```

### browser credential store access

```bash
RULE_ID="file_browser_credential_store_access"
RULE_NAME="Browser Credential Store Access"
RULE_TYPE="sensitive_path"
RULE_LEVEL="high"
RULE_CATEGORY="browser_data"
RULE_DESCRIPTION="Detects access to browser credential or login data stores."
RULE_MATCH_FIELD="file_path"
RULE_MATCH_PATTERN="Login Data"
RULE_EVIDENCE_FIELDS="timestamp process_name pid file_path operation"
RULE_RECOMMENDATION="Review whether the target agent should access browser credential storage."
RULE_TAGS="browser,credential-access,macos"
RULE_ENABLED="true"
RULE_WEIGHT="1.0"
RULE_CONFIDENCE="medium"
```

### unexpected launch daemon

```bash
RULE_ID="persistence_unexpected_launch_daemon"
RULE_NAME="Unexpected LaunchDaemon"
RULE_TYPE="persistence"
RULE_LEVEL="medium"
RULE_CATEGORY="startup_item"
RULE_DESCRIPTION="Detects a LaunchDaemon associated with the target that is not expected by the active Profile."
RULE_MATCH_FIELD="launchd_label"
RULE_MATCH_PATTERN="unexpected"
RULE_EVIDENCE_FIELDS="timestamp launchd_label program_path user state"
RULE_RECOMMENDATION="Review whether the LaunchDaemon is expected for this target Profile."
RULE_TAGS="macos,launchd,persistence"
RULE_ENABLED="true"
RULE_WEIGHT="1.0"
RULE_CONFIDENCE="low"
```

### large upload to external endpoint

```bash
RULE_ID="network_large_upload_external_endpoint"
RULE_NAME="Large Upload To External Endpoint"
RULE_TYPE="upload_traffic"
RULE_LEVEL="medium"
RULE_CATEGORY="network_transfer"
RULE_DESCRIPTION="Detects a potentially large outbound transfer to an external endpoint."
RULE_MATCH_FIELD="bytes_out"
RULE_MATCH_PATTERN="large_upload_threshold"
RULE_EVIDENCE_FIELDS="timestamp process_name pid endpoint bytes_out protocol"
RULE_RECOMMENDATION="Review whether the upload volume is expected for the target agent and collection window."
RULE_TAGS="network,upload,traffic"
RULE_ENABLED="true"
RULE_WEIGHT="1.0"
RULE_CONFIDENCE="low"
```

Example notes:

- These examples are templates.
- They do not claim a behavior is malicious by themselves.
- Real threshold values and match semantics should be defined during implementation.
- Rule examples should be tested against fixture data before being marked ready.

## 17. Internationalization

Rule internal identifiers should use English, stable IDs.

Examples:

- `RULE_ID`
- `RULE_TYPE`
- `RULE_CATEGORY`
- `RULE_TAGS`

Report display text should be resolved through i18n mappings when possible.

Supported language strategy:

- `zh-CN`
- `en-US`
- `REPORT_LANG=auto`

Internationalization principles:

- Rule IDs remain stable across languages.
- Reporter display text can be localized.
- Rule names and descriptions may have i18n keys in future versions.
- Chinese systems should receive Chinese report text when `REPORT_LANG=auto`.
- Non-Chinese systems should receive English report text when `REPORT_LANG=auto`.
- Missing translations should fall back to English.

Recommended future i18n mapping concept:

```text
i18n/zh-CN/rules.conf
i18n/en-US/rules.conf
```

Example conceptual keys:

```text
rule.file_sensitive_keychain_access.name=Sensitive Keychain Access
rule.file_sensitive_keychain_access.description=Detects access to macOS Keychain related files.
```

## 18. What V2 Does Not Do

V2 Rule Engine does not include:

- Malware verdicts.
- Automatic quarantine.
- Automatic deletion.
- Security software bypass.
- Hidden monitoring.
- Network downloading of Rules.
- Execution of remote Rules.
- Blocking, intercepting, or modifying target Agent behavior.
- Collection of unrelated personal content.

Rules should remain local, auditable, read-only behavior definitions.

## 19. V1.1 To V2 Migration

V1.1 includes hard-coded or tightly coupled behavior checks that should gradually become Rule files.

Migration targets:

```text
rules/file/sensitive_keychain_access.conf
rules/network/target_endpoint_connection.conf
rules/process/target_process_running.conf
```

Additional V1.1 migration candidates:

```text
rules/file/sensitive_ssh_access.conf
rules/file/browser_history_access.conf
rules/file/browser_credential_store_access.conf
rules/persistence/target_launchd_present.conf
rules/privilege/target_process_root_user.conf
```

Migration principles:

1. Preserve V1.1 as the runnable baseline.
2. Move sensitive path checks into file and sensitive path Rules.
3. Move network endpoint checks into network Rules.
4. Move process running checks into process Rules.
5. Move launchd checks into persistence Rules.
6. Keep target-specific values in Profiles, not Rules.
7. Keep Rules behavior-oriented and reusable across Profiles.
8. Update Analyzer and Reporter behavior only after Rule output is stable.
9. Update README after the V2 Rule workflow is runnable and tested.

This migration separates behavior judgment from code while preserving the original V1.1 monitoring scope and read-only safety model.
