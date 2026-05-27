# ADR-0003: Release State Is Ledger-Guarded

Status: Accepted
Date: 2026-05-27

## Context

Release readiness was previously spread across migration docs, workstream
closeouts, package state, and manual command memory. That made publish posture
hard to verify quickly.

## Decision

`docs/release/release_ledger.json` is the machine-readable release posture.
`tool/check_release_ledger.dart` validates package list, workstream status,
required gate tools, and known deferrals. Successful gates do not automatically
publish packages.

## Consequences

- New prepublish workstreams must be added to the ledger while active.
- Closing a prepublish workstream must update the ledger back to
  `release_ready`.
- Maintainer-approved `pub publish` remains an explicit external step.
