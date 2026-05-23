# Alpha Release Hardening

## Why This Workstream Exists

The provider and AI runtime split has reached an architecture-complete state
for the breaking preview. The remaining work should no longer be framed as
open-ended refactoring.

This workstream turns the refactor into a publishable alpha line. It is a
release-hardening phase: prove the package graph, automate the release gate,
validate clean consumers, and fix only issues that block publishing or
migration.

Status: closed as local release hardening on 2026-05-23. Actual `pub publish`
execution remains an explicit maintainer-approved external follow-on.

## Goal

Prepare the `0.11.0-alpha.x` line for maintainer-approved publication with
confidence that:

- the focused packages resolve and analyze outside the monorepo
- the root facade remains a good default entrypoint
- historical root/core compatibility imports stay removed and guarded
- package metadata and README guidance match the implemented ownership model
- release validation is repeatable without relying on memory or chat history

## Release Posture

This is still an alpha preview, not a stability promise.

Breaking changes can still happen before `1.0.0`, but the package boundaries
introduced by the architecture split should be treated as the intended
direction. Release-hardening changes should therefore preserve the new
architecture unless a real consumer, packaging, or migration issue proves that
the boundary is wrong.

## Scope

This workstream should:

- add a repeatable release-readiness command
- validate publish dry-runs for all publishable workspace packages
- validate clean Dart and Flutter consumers
- check package names, versions, dependency order, metadata, README language,
  changelog entries, and migration docs
- rebaseline the release checklist after the fearless boundary reset removed
  `llm_dart_core` and made `llm_dart_provider_utils` a real publishable seam
- document publish sequencing and post-publish verification
- fix release blockers discovered by those gates

## Non-Goals

This workstream should not:

- keep splitting compatibility files by size
- redesign provider/model data structures without a concrete release blocker
- add new provider features
- recreate `legacy.dart`, `llm_dart_core`, or a broad compatibility bucket
- broaden shared abstractions for reference-repository parity

Those may be valid future workstreams, but only after alpha release feedback or
real product pressure.

## Success Criteria

The workstream is complete when:

- a single release-readiness command exists and is documented
- the command runs guards, analysis, tests, publish dry-run, and consumer smoke
  checks or clearly documents which steps are manual
- package versions and publish order are verified
- release notes and migration guidance cover the breaking preview
- clean consumer validation passes for Dart and Flutter
- the alpha publish sequence is ready to execute after explicit maintainer
  approval
- post-publish verification steps are documented

## Tracks

### P0 - Release Gate Automation

Create a Dart-based tool that orchestrates the current manual checklist and
prints a concise release report.

### P1 - Package And Metadata Audit

Confirm that every publishable package has accurate descriptions, dependency
constraints, changelog entries, README guidance, repository links, and publish
expectations.

### P1 - Consumer Smoke Validation

Keep real clean-consumer checks in the release gate so missing exports and
dependency override mistakes are caught outside the monorepo.

### P1 - Publish Sequencing

Freeze the dependency-aware publish order and the expected local override
hints before running publication.

After the boundary reset, the publish order excludes the deleted
`llm_dart_core` package and includes the now-public
`llm_dart_provider_utils` package between transport and chat/provider
adapters.

### P2 - Post-Publish Verification

After explicit maintainer-approved publishing, repeat clean consumer checks
against pub.dev versions and record any alpha feedback as targeted follow-up
work.

## Documents

- [00-priority-map.md](00-priority-map.md)
  - Ordered release-hardening priorities and stop conditions.
- [01-release-readiness-command.md](01-release-readiness-command.md)
  - Desired behavior for the release-readiness automation.
- [03-release-readiness-audit-2026-05-15.md](03-release-readiness-audit-2026-05-15.md)
  - Current branch release-readiness audit, fixture-path fix record, final
    13-step release gate evidence, publish dry-run evidence, pub.dev version
    availability, and publish-order confirmation.
- [04-post-boundary-reset-release-rebaseline-2026-05-21.md](04-post-boundary-reset-release-rebaseline-2026-05-21.md)
  - Rebaseline after the fearless boundary reset: package graph, publish
    order, API surface drift, and fresh validation evidence.
- [EVIDENCE_AND_GATES.md](EVIDENCE_AND_GATES.md)
  - Closed local release-hardening evidence and external publish follow-on.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria.
- [TODO.md](TODO.md)
  - Executable checklist.
