# SDMon RFCs

The SDMon RFC system records major architecture design decisions for the project.

RFC documents are used to:

- Record significant architecture designs.
- Explain why important design decisions were made.
- Help future contributors understand how the framework evolves.
- Describe design intent before implementation details are introduced.

RFCs only describe design. They do not directly implement code.

## RFC Status

An RFC may use one of these statuses:

- `Draft`: The RFC is proposed and still open for discussion.
- `Accepted`: The RFC has been accepted as the current design direction.
- `Superseded`: The RFC has been replaced by a newer RFC.
- `Deprecated`: The RFC is no longer recommended, but remains for historical context.

## Naming Rules

RFC files should use a zero-padded numeric identifier and a short kebab-case topic name.

Examples:

- `RFC-0001-event-model.md`
- `RFC-0002-plugin-api.md`
- `RFC-0003-rule-format.md`

## Recommended RFC Structure

A typical RFC should include:

- Title
- Status
- Summary
- Motivation
- Design Goals
- Proposed Design
- Non-goals
- Migration Notes

The structure may vary when a topic needs additional sections, but every RFC should be readable as a standalone design record.
