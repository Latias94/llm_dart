# 153 Provider-Specific postJson Error Mapping

## Why

`HttpResponseHandler.postJson(...)` had become the shared compatibility helper
for root-hosted provider clients, but it still hard-coded one assumption:

- every `DioException` should be mapped by the shared `DioErrorHandler`.

That assumption was too strong.

Some providers, especially DeepSeek, still intentionally own provider-specific
error semantics above the generic HTTP mapping layer. In practice, the old
shared helper could swallow that specialization because it converted
`DioException` before provider clients had a chance to apply their own mapper.

## Decision

Keep `HttpResponseHandler.postJson(...)` as the shared request/parse helper, but
add an optional provider-specific Dio error mapper hook.

This preserves the current layering:

- `HttpResponseHandler`
  - owns shared request logging, success validation, and JSON-object parsing.
- `DioErrorHandler`
  - remains the default shared compatibility mapper.
- provider clients
  - may override Dio exception mapping when their API needs provider-specific
    error semantics.

## What Changed

- Added an optional `mapDioException` callback to
  `HttpResponseHandler.postJson(...)`.
- Switched `DeepSeekClient.postJson(...)` to pass
  `DeepSeekErrorHandler.handleDioError`, so its provider-specific quota/balance
  and request-shape semantics now actually take effect on the shared helper
  path.
- Removed the dead outer `DioException` catch from `XAIClient.postJson(...)`
  because the shared helper already performs the same mapping.

## Architectural Effect

This is an important compatibility-boundary refinement:

- shared helpers stay shared,
- but they no longer erase provider-specific semantics by accident.

It also sets the correct precedent for the remaining root-hosted provider
clients:

- use shared HTTP helpers for mechanics,
- inject provider-specific error mapping only where the semantics are genuinely
  different.
