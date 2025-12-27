# xAI (Grok, OpenAI-compatible) Guide

This guide documents how to use xAI Grok via `llm_dart_xai`.

xAI is integrated through the **OpenAI Chat Completions compatible** protocol
layer (`llm_dart_openai_compatible`). LLM Dart follows a best-effort approach:
we forward requests as-is and do **not** maintain a provider/model support matrix.

LLM Dart also supports xAI's **Responses API** surface (Vercel-style provider id
`xai.responses`) for agentic server-side tools and richer streaming events.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. xAI-only knobs
live behind:

- `providerOptions['xai']`
- `providerMetadata['xai']`

Note: If you use the **pre-configured OpenAI-compatible** provider id
`xai-openai` (from `llm_dart_openai_compatible`), the namespace changes:

- `providerOptions['xai-openai']`
- `providerMetadata['xai-openai']`

If you use the **Responses API** provider id `xai.responses`, the namespace is:

- `providerOptions['xai.responses']`
- `providerMetadata['xai.responses']`

## Packages

- Provider: `llm_dart_xai`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_openai_compatible` (internal dependency)

## Base URL

Default base URL:

- `https://api.x.ai/v1/`

## Authentication

LLM Dart uses OpenAI-style bearer auth:

- `Authorization: Bearer <XAI_API_KEY>`

You can override/extend headers via:

- `providerOptions['xai']['extraHeaders']`

Official docs:

- xAI docs: https://docs.x.ai/
- Live Search guide: https://docs.x.ai/docs/guides/live-search
- API reference (Responses): https://docs.x.ai/docs/api-reference#create-new-response

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

Future<void> main() async {
  registerXAI();

  final model = await LLMBuilder()
      .provider(xaiProviderId)
      .apiKey('XAI_API_KEY')
      .model('grok-3')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Grok!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Live search (`search_parameters`)

xAI supports provider-native “live search” via the Chat Completions request
field `search_parameters` (xAI-specific).

In LLM Dart this stays behind `providerOptions['xai']` (best-effort):

- `liveSearch`: `bool`
- `searchParameters`: `SearchParameters` JSON

Example:

```dart
import 'package:llm_dart_xai/llm_dart_xai.dart';

final model = await LLMBuilder()
    .provider(xaiProviderId)
    .apiKey('XAI_API_KEY')
    .model('grok-3')
    .providerOptions('xai', {
      'liveSearch': true,
      'searchParameters': SearchParameters.webSearch(maxResults: 5).toJson(),
    })
    .build();
```

Notes:

- `webSearchEnabled/webSearch` keys are legacy best-effort; prefer
  `liveSearch/searchParameters`.

References:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`
- `docs/protocols/openai_compatible.md`
- Vercel xAI provider: `repo-ref/ai/packages/xai`

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For xAI, the namespace is:

- `providerMetadata['xai']`

The OpenAI-compatible layer surfaces best-effort metadata such as:

- `id`, `model`, `systemFingerprint`, `finishReason`

## Conformance tests

xAI config + live search tests:

- `test/providers/xai/live_search_test.dart`
- `test/providers/xai/xai_config_test.dart`
- `test/providers/xai/xai_factory_test.dart`
- `test/providers/xai/xai_provider_test.dart`

OpenAI-compatible baseline tests:

- `test/protocols/openai_compatible/request_builder_conformance_test.dart`
- `test/providers/openai_compatible/openai_compatible_stream_parts_test.dart`

## Responses API (`xai.responses`)

The `xai.responses` provider id targets:

- `POST /v1/responses`
- streaming events such as `response.output_text.delta` and
  `response.reasoning_summary_text.delta`

### Quick start (Responses)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

Future<void> main() async {
  registerXAI();

  final model = await LLMBuilder()
      .provider('xai.responses')
      .apiKey('XAI_API_KEY')
      .model('grok-4-fast')
      .providerTool(const ProviderTool(id: 'xai.web_search'))
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('What is xAI?')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

### Provider-native tools (Responses)

Use `providerTools` (Vercel-style stable ids) to enable server-side tools:

- `xai.web_search`
- `xai.x_search`
- `xai.code_execution` (mapped to `code_interpreter`)
- `xai.view_image`
- `xai.view_x_video`
- `xai.file_search`
- `xai.mcp`

Tool options are forwarded best-effort. Prefer snake_case keys in
`ProviderTool.options` (e.g. `allowed_domains` / `excluded_domains`).

### Conformance tests (Responses)

Offline fixture replays:

- `test/providers/xai/xai_responses_streaming_fixtures_test.dart`
