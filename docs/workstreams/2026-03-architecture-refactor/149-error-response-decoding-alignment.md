# 149 Error Response Decoding Alignment

## Why

After moving streamed response decoding into `llm_dart_transport`, the root
compatibility layer still duplicated one lower-level HTTP concern:

- reading `ResponseBody` error payloads into text,
- parsing JSON error envelopes out of that text, and
- reimplementing similar extraction logic in both `DioErrorHandler` and the
  OpenAI compatibility client.

That left the root package carrying transport-shaped mechanics instead of only
compatibility-owned error semantics.

## Decision

Move raw Dio error-body text collection into `llm_dart_transport`, then let the
root compatibility layer reuse a shared parsed-error extraction path.

The new layering becomes:

1. `llm_dart_transport`
   - owns `collectDioResponseTextBody(...)`,
   - owns byte-stream extraction and UTF-8 decoding,
   - does not map provider or SDK-level error types.
2. Root compatibility HTTP helpers
   - own `LLMError` mapping and status-code interpretation,
   - reuse the shared transport helper for `ResponseBody` reading,
   - expose a shared `extractErrorResponseDetails(...)` path.
3. Provider-specific compatibility clients
   - may supply a provider-specific message extractor,
   - keep provider-specific wording without reimplementing stream reading.

## What Changed

- `llm_dart_transport` now exposes `collectDioResponseTextBody(...)` alongside
  the existing streaming-response helpers.
- `DioTransportClient` now reuses the same helper when it needs to read failed
  response bodies for transport exceptions.
- Root `DioErrorHandler` now normalizes error payload extraction through
  `extractErrorResponseDetails(...)` instead of manually reading `ResponseBody`
  streams inline.
- The OpenAI compatibility client now reuses that shared extraction path and
  only supplies its provider-specific message formatting callback so `type` and
  `code` context stay preserved.

## Architectural Effect

This is a small but important boundary cleanup:

- transport owns transport mechanics,
- the root compatibility layer owns SDK error semantics,
- provider compatibility code only owns provider-specific message enrichment.

It also creates a better next step for future refactors:

- if more root compatibility clients still duplicate error extraction,
  they can migrate onto the same helper without widening the transport package
  into provider-aware logic.
