# 150 Compatibility HTTP Request Executor

## Why

After the earlier root-dependency slimming work, some root compatibility
clients still repeated the same request shell:

- call `dio.request(...)` or `dio.post(...)`,
- bind `TransportCancellation`,
- catch `DioException`,
- log a provider-local failure message,
- then either rethrow or delegate provider-specific error mapping.

This duplication was still present even when the provider kept owning its own
response parsing and error semantics.

## Decision

Introduce a very thin compatibility-owned request executor for raw Dio request
dispatch, but keep it intentionally narrow.

`CompatibilityDioRequestExecutor` owns only:

- request dispatch,
- cancellation binding,
- request-option forwarding,
- failure logging,
- delegation of `DioException` mapping back to the caller.

It does **not** own:

- provider-specific error semantics,
- status-code interpretation,
- response parsing,
- JSON decoding,
- shared transport-layer mechanics that belong in `llm_dart_transport`.

## Initial Adoption

This first pass moves `AnthropicClient` and `GoogleClient` onto the new helper.

That is enough to prove the boundary without prematurely rewriting the more
customized OpenAI compatibility client.

## Architectural Effect

This gives the root compatibility layer a cleaner split:

- `llm_dart_transport`
  - low-level Dio and stream mechanics,
- root compatibility HTTP helpers
  - compatibility-only request shell and `LLMError` mapping,
- provider clients
  - provider semantics, endpoint shaping, and response parsing.

The helper is intentionally conservative so later migrations can either:

- adopt it directly,
- wrap it with provider-specific policies,
- or skip it when a client still needs a more specialized path.
