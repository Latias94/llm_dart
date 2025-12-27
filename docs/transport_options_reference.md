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
- `customDio`: `Object` (advanced; expected to be a `Dio` instance when using Dio-based providers)

Notes:

- `customDio` is not JSON-serializable and will be omitted from `LLMConfig.toJson()`.
