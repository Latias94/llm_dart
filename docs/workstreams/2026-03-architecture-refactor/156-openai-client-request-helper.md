# 156 OpenAI Client Request Helper

## Why

After the recent compatibility HTTP consolidation, `OpenAIClient` still had the
largest residual batch of repeated request shells in the root-hosted legacy
layer:

- `postJson(...)`
- `postForm(...)`
- `postRaw(...)`
- `get(...)`
- `getRaw(...)`
- `delete(...)`
- `postStreamRaw(...)`

Those methods still repeated the same mechanics:

- API-key presence checks,
- request logging,
- cancellation binding,
- request dispatch,
- success-status validation,
- `DioException` mapping,
- generic error wrapping.

Unlike the smaller compatibility clients we already migrated onto shared
helpers, OpenAI still owns enough provider-specific failure semantics that it
would be a mistake to keep pushing more behavior into the shared compatibility
HTTP layer.

## Decision

Add a provider-local request helper inside `OpenAIClient` instead of expanding
the shared compatibility HTTP helper surface again.

The boundary stays explicit:

- shared compatibility HTTP utilities keep owning generic status validation and
  lower-level transport mechanics,
- `OpenAIClient` keeps owning OpenAI-specific error extraction and message
  wording,
- OpenAI request-shell deduplication happens locally, not by making the shared
  helper more OpenAI-shaped.

## What Changed

- Added private `OpenAIClient` helpers for:
  - API-key validation,
  - request logging,
  - shared success-status validation wiring,
  - repeated request dispatch / catch / decode flow.
- Moved all seven residual request entrypoints onto the same provider-local
  helper path.
- Kept OpenAI-specific error interpretation local through:
  - `_handleErrorResponse(...)`
  - `_extractErrorMessageFromMap(...)`
  - `handleDioError(...)`
- Added a regression test that verifies a non-200 OpenAI response still
  rethrows the mapped provider error instead of being wrapped as a generic
  unexpected failure.

## Architectural Effect

This is intentionally a local cleanup, not a new shared abstraction round.

It reduces root implementation weight in the biggest remaining compatibility
outlier while preserving a healthy boundary:

- less duplicated OpenAI request plumbing,
- no extra OpenAI-specific branching in shared helpers,
- clearer separation between transport mechanics and provider-owned failure
  semantics.

It also makes the remaining structural work more honest: if future OpenAI
cleanup is still needed, it should focus on provider-owned capability modules
and legacy-surface slimming rather than inventing broader generic HTTP helper
APIs.
