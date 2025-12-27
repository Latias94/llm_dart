# DeepSeek (OpenAI-compatible) Guide

This guide documents how to use DeepSeek via `llm_dart_deepseek`.

DeepSeek is integrated through the **OpenAI Chat Completions compatible**
protocol layer (`llm_dart_openai_compatible`). LLM Dart follows a best-effort
approach: we forward requests as-is and do **not** maintain a provider/model
support matrix.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. DeepSeek-only
knobs live behind:

- `providerOptions['deepseek']`
- `providerMetadata['deepseek']`

Note: If you use the **pre-configured OpenAI-compatible** provider id
`deepseek-openai` (from `llm_dart_openai_compatible`), the namespace changes:

- `providerOptions['deepseek-openai']`
- `providerMetadata['deepseek-openai']`

## Packages

- Provider: `llm_dart_deepseek`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_openai_compatible` (internal dependency)

## Base URL

Default base URL:

- `https://api.deepseek.com/v1/`

## Authentication

LLM Dart uses OpenAI-style bearer auth:

- `Authorization: Bearer <DEEPSEEK_API_KEY>`

You can override/extend headers via:

- `providerOptions['deepseek']['extraHeaders']`

Official docs:

- DeepSeek API docs: https://api-docs.deepseek.com/
- List models: https://api-docs.deepseek.com/api/list-models

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

Future<void> main() async {
  registerDeepSeek();

  final model = await LLMBuilder()
      .provider(deepseekProviderId)
      .apiKey('DEEPSEEK_API_KEY')
      .model('deepseek-chat')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from DeepSeek!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Provider options (DeepSeek deltas)

DeepSeek supports a set of OpenAI-style optional parameters as best-effort
escape hatches.

Reference:

- `docs/provider_options_reference.md`
- `docs/protocols/openai_compatible.md`
- Vercel DeepSeek provider: `repo-ref/ai/packages/deepseek`

Common keys:

- `logprobs`: `bool` → `logprobs`
- `topLogprobs`: `int` → `top_logprobs`
- `frequencyPenalty`: `double` → `frequency_penalty`
- `presencePenalty`: `double` → `presence_penalty`
- `responseFormat`: `Map<String, dynamic>` → `response_format` (best-effort)
- Escape hatches:
  - `extraBody`: `Map<String, dynamic>`
  - `extraHeaders`: `Map<String, String>`

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For DeepSeek, the namespace is:

- `providerMetadata['deepseek']`

The OpenAI-compatible layer surfaces best-effort metadata such as:

- `id`, `model`, `systemFingerprint`, `finishReason`

## Conformance tests

DeepSeek config + provider tests:

- `test/providers/deepseek/deepseek_config_test.dart`
- `test/providers/deepseek/deepseek_factory_test.dart`
- `test/providers/deepseek/deepseek_provider_test.dart`

OpenAI-compatible baseline tests:

- `test/protocols/openai_compatible/request_builder_conformance_test.dart`
- `test/providers/openai_compatible/openai_compatible_stream_parts_test.dart`
