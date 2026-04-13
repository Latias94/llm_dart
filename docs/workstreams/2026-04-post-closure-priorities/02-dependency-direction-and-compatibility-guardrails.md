# Dependency Direction And Compatibility Guardrails

## Verified Current Dependency Shape

The current workspace dependency graph is already close to the intended shape.

### Package-Level Direction

- `llm_dart_core`
  - foundational shared contracts
  - no runtime package dependencies
- `llm_dart_transport`
  - transport and networking support
  - depends on `llm_dart_core`
- `llm_dart_openai`
  - depends on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_google`
  - depends on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_anthropic`
  - depends on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_community`
  - depends on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_chat`
  - depends on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_flutter`
  - depends on `flutter`, `llm_dart_chat`, and `llm_dart_core`
- root `llm_dart`
  - aggregates and re-exports the workspace packages
  - still owns compatibility APIs

### Import-Direction Audit

An implementation-import audit on 2026-04-13 shows that package implementation
files under `packages/` do not currently import `package:llm_dart/...`.

That is important because it means the root package is no longer acting as a
hidden base layer for workspace implementation code.

## Runtime Dependency Policy

The next phase should freeze the following runtime dependency rules:

### `llm_dart_core`

- no networking packages
- no logging packages
- no Flutter dependencies
- no provider-family-specific runtime helpers

### `llm_dart_transport`

- owns HTTP, SSE, cancellation adapters, shared logging helpers, and transport
  diagnostics
- is the preferred place for shared runtime dependencies such as `dio` or
  `logging`

### Provider Packages

- should depend only on `llm_dart_core` and `llm_dart_transport`
- should keep provider wire codecs, provider-owned summaries, and
  provider-specific options local
- should not depend on `llm_dart_chat`, `llm_dart_flutter`, or root
  compatibility files

### `llm_dart_chat`

- may depend on `llm_dart_core` and `llm_dart_transport`
- should remain provider-neutral
- should not absorb provider-specific JSON parsing or provider-specific widget
  concerns

### `llm_dart_flutter`

- may depend on Flutter SDK, `llm_dart_chat`, and `llm_dart_core`
- should remain thin and adapter-oriented
- should not become a provider-specific rendering bus

## Root Package Policy

The root `llm_dart` package still matters, but its role should now be frozen
more explicitly.

### What The Root Package Still Owns

- the default documented modern facade
- curated re-exports
- compatibility-era entrypoints such as `legacy.dart`
- deprecation routing and migration guidance

### What The Root Package Should Stop Growing

- new provider-owned implementation helpers
- new transport primitives
- new shared model ownership
- new Flutter/session-specific logic

New modern implementation work should land in the workspace package that owns
that layer, not in root compatibility files.

## Compatibility-Only Default Rule

For the remaining root-local helpers, the default interpretation should now be:

> compatibility-owned unless a concrete modern ownership reason proves
> otherwise

This keeps the repository from reintroducing a second implementation center
while the migration window is still open.

## Suggested Enforcement

The next implementation pass should consider lightweight enforcement:

- a CI check that rejects package implementation imports from
  `package:llm_dart/...`
- a small dependency policy note in contributing or architecture docs
- review guidance that new runtime dependencies normally enter through
  `llm_dart_transport`, not provider packages or the root package

## Why This Matters

The reference repository shows the value of strong ownership boundaries, but the
important lesson is not “split into many packages”.

The important lesson is:

- dependencies should flow one way
- shared layers should stay small
- provider-specific code should stay provider-owned
- compatibility should not silently become the real implementation center again
