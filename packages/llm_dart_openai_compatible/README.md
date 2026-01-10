# llm_dart_openai_compatible

OpenAI-compatible provider configs and factories for `llm_dart`.

This package is a Tier 3 (opt-in) protocol layer: it is intended for advanced
users and provider authors.

This package exists to reuse a single “wire protocol” implementation across
multiple providers that speak an OpenAI-compatible API.

Most users should depend on a concrete provider package (e.g. `llm_dart_groq`,
`llm_dart_xai`, `llm_dart_deepseek`) rather than this package directly.

When a first-party provider package exists, prefer it over the OpenAI-compatible
presets. The presets are best-effort and intended for OpenAI-compatible gateways
or when you must use a specific provider's OpenAI-flavored endpoint.

## Custom providers

To integrate an OpenAI-compatible gateway (LM Studio / LiteLLM / proxies), you
can register your own provider id:

- Example: `example/04_providers/others/openai_compatible_custom_providers.dart`

## Imports

The recommended entrypoint is:

```dart
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
```

Low-level transport utilities are intentionally opt-in and must be imported via
subpaths:

```dart
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/dio_strategy.dart';
```

## Provider options

This package reads provider-specific options from `LLMConfig.providerOptions[providerId]`:

- `headers` / `extraHeaders`: additional HTTP headers (merged; later keys win)
- `queryParams`: additional URL query parameters appended to all requests
- `endpointPrefix`: optional path prefix inserted before every endpoint (e.g. `openai` for DeepInfra)
- `includeUsage`: when streaming, adds `stream_options.include_usage=true`
- `supportsStructuredOutputs`: when `false`, downgrades JSON schema outputs to `{"type":"json_object"}`

Note: `apiKey` is optional for OpenAI-compatible endpoints. If omitted, auth
headers are not added and the server decides whether the request is allowed.

