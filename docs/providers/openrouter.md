# OpenRouter (OpenAI-compatible) Guide

This guide documents how to use OpenRouter via the OpenAI-compatible provider
id `openrouter`.

OpenRouter is integrated through the **OpenAI Chat Completions compatible**
protocol layer (`llm_dart_openai_compatible`). LLM Dart follows a best-effort
approach: we forward requests as-is and do **not** maintain a provider/model
support matrix.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. OpenRouter-only
knobs live behind:

- `providerOptions['openrouter']`
- `providerMetadata['openrouter']`

## Packages

- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_openai_compatible`

Note: OpenRouter is currently shipped as an OpenAI-compatible provider
configuration (provider id `openrouter`), not as a dedicated `llm_dart_openrouter`
package.

## Base URL

Default base URL:

- `https://openrouter.ai/api/v1/`

## Authentication

LLM Dart uses OpenAI-style bearer auth:

- `Authorization: Bearer <OPENROUTER_API_KEY>`

You can override/extend headers via:

- `providerOptions['openrouter']['extraHeaders']`

Official docs:

- OpenRouter docs: https://openrouter.ai/docs

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

Future<void> main() async {
  registerOpenAICompatibleProviders();

  final model = await LLMBuilder()
      .provider('openrouter')
      .apiKey('OPENROUTER_API_KEY')
      .model('anthropic/claude-3.5-sonnet')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from OpenRouter!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Web search and the `:online` model suffix

OpenRouter enables web search via the `:online` model suffix (provider-specific).
LLM Dart does **not** rewrite models automatically.

Recommended:

- Set the model explicitly with `:online` when you want OpenRouter web search,
  e.g. `anthropic/claude-3.5-sonnet:online`.

Legacy/best-effort escape hatches (do not rewrite `model`):

- `providerOptions['openrouter']['webSearchEnabled']`: `bool`
- `providerOptions['openrouter']['webSearch']`: `Map<String, dynamic>`
- `providerOptions['openrouter']['useOnlineShortcut']`: `bool` (legacy; no longer rewrites the model)

References:

- `docs/provider_escape_hatches.md`
- `docs/provider_options_reference.md`
- `docs/protocols/openai_compatible.md`

## Reasoning options (best-effort)

OpenRouter supports its own reasoning parameter shape. In LLM Dart, you can use
the OpenAI-compatible `reasoningEffort` option (best-effort), which is compiled
to the OpenRouter request body as:

- `providerOptions['openrouter']['reasoningEffort']`: `low` / `medium` / `high`
  → `{"reasoning":{"effort":"..."}}`

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For OpenRouter, the namespace is:

- `providerMetadata['openrouter']`

The OpenAI-compatible layer surfaces best-effort metadata such as:

- `id`, `model`, `systemFingerprint`, `finishReason`

## Conformance tests

OpenRouter web search configuration tests:

- `test/providers/openai_compatible/openrouter_provider_options_web_search_test.dart`

OpenAI-compatible baseline tests:

- `test/protocols/openai_compatible/request_builder_conformance_test.dart`
- `test/providers/openai_compatible/openai_compatible_stream_parts_test.dart`
