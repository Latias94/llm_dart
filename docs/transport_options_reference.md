# Transport Options Reference

`llm_dart` keeps HTTP/transport configuration **provider-agnostic**.

Use:

- `LLMConfig.transportOptions` (preferred)
- `LLMBuilder.http((h) => ...)` (fluent wrapper that writes into `transportOptions`)

Advanced (Dio-based) helper utilities live in:

- `package:llm_dart_provider_utils/llm_dart_provider_utils.dart`

Providers should read from `transportOptions`.

---

## Keys

All keys live at the top-level of `transportOptions`:

- `httpProxy`: `String` (e.g. `http://proxy.example.com:8080`)
- `customHeaders`: `Map<String, String>`
- `bypassSSLVerification`: `bool` (IO only; ignored on web)
- `sslCertificate`: `String` (path; IO only; ignored on web)
- `connectionTimeout`: `Duration`
- `receiveTimeout`: `Duration`
- `sendTimeout`: `Duration`
- `enableHttpLogging`: `bool`
- `retry`: `Map<String, dynamic>` (opt-in; HTTP retries for non-streaming requests)
- `customDio`: `Object` (advanced; expected to be a `Dio` instance when using Dio-based providers)

Notes:

- `customDio` is not JSON-serializable and will be omitted from `LLMConfig.toJson()`.

---

## `retry` (opt-in)

Transport-level HTTP retries live in `llm_dart_provider_utils` and are **disabled by default**.

Configure via `LLMConfig.transportOptions['retry']`:

```dart
final config = LLMConfig(...).withTransportOptions({
  'retry': {
    'maxRetries': 2,
    'baseDelayMs': 200,
    'maxDelayMs': 2000,
    'backoffFactor': 2.0,
    'jitter': 0.2,
    'respectRetryAfter': true,
    'retryStatusCodes': [408, 429, 500, 502, 503, 504],
    'retryOnDioErrors': true,
    'retryOnFormData': false,
  },
});
```

Behavior notes:

- Only applies to **non-streaming** requests (Dio `ResponseType.stream` is never retried).
- When `respectRetryAfter=true`, `Retry-After: <seconds>` is honored best-effort.
- Requests with `FormData` are **not** retried unless `retryOnFormData=true` (to avoid accidental duplicate uploads).
