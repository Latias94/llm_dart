# 155 Outlier Client Request Executor Adoption

## Why

After the recent HTTP helper consolidation, two root-hosted provider clients
still kept bespoke request shells:

- `PhindClient`
- `ElevenLabsClient`

They were outliers because they still repeated:

- raw `dio.get(...)` / `dio.post(...)` dispatch,
- cancellation binding,
- `DioException` mapping,
- status validation boilerplate,
- plus small provider-local response projection rules.

Their response semantics differ from the main OpenAI-family path, but their
request mechanics were still the same kind of compatibility plumbing we have
been extracting.

## Decision

Move both clients onto the shared `CompatibilityDioRequestExecutor`, while
keeping their provider-specific response projections local.

This keeps the boundary explicit:

- the shared executor owns request dispatch and Dio exception mapping,
- the provider client still owns response-shape interpretation.

## What Changed

- `PhindClient`
  - now uses `CompatibilityDioRequestExecutor` for both JSON and stream
    requests,
  - keeps its provider-local text-stream-to-chat-completions projection,
  - keeps its provider-local empty-completion handling.
- `ElevenLabsClient`
  - now uses `CompatibilityDioRequestExecutor` for GET, list, binary, and form
    requests,
  - keeps its provider-local STT string-response wrapping and custom status
    wording.
- Added client-level regression tests for:
  - Phind streamed-text projection,
  - Phind raw stream decoding,
  - ElevenLabs plain-text STT response wrapping.

## Architectural Effect

This closes another root implementation-weight gap:

- fewer one-off request shells,
- more reuse through focused helpers,
- clearer separation between request mechanics and provider-specific response
  semantics.

It also leaves the remaining work more obvious:

- OpenAI still has the biggest residual custom request surface,
- Phind and ElevenLabs are no longer structural excuses for keeping generic
  request boilerplate duplicated across the root package.
