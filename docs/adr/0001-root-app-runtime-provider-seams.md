# ADR-0001: Root, App Runtime, And Provider Seams

Status: Accepted
Date: 2026-05-27

## Context

The project previously carried too much implementation weight through broad
root surfaces and compatibility-era concepts. Recent refactors split provider
contracts, app runtime orchestration, chat transport, and root facades into
separate Modules.

## Decision

The root package remains a thin facade. App-facing generation and tool-loop
runtime behavior belongs in `llm_dart_ai`. Provider contracts belong in
`llm_dart_provider`. Concrete provider request, stream, and result behavior
belongs in provider packages.

## Consequences

- Root entrypoints are guarded by release manifests.
- Provider packages must not depend on root facades.
- App runtime helpers may compose provider contracts, but provider packages do
  not own app orchestration.
- A future broad root facade expansion needs a superseding ADR.
