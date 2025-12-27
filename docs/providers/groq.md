# Groq (OpenAI-compatible) Guide

This guide documents how to use Groq via `llm_dart_groq`.

Groq is integrated through the **OpenAI Chat Completions compatible** protocol
layer (`llm_dart_openai_compatible`). LLM Dart follows a best-effort approach:
we forward requests as-is and do **not** maintain a provider/model support matrix.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. Groq-only knobs
live behind:

- `providerOptions['groq']`
- `providerMetadata['groq']`

Note: If you use the **pre-configured OpenAI-compatible** provider id
`groq-openai` (from `llm_dart_openai_compatible`), the namespace changes:

- `providerOptions['groq-openai']`
- `providerMetadata['groq-openai']`

## Packages

- Provider: `llm_dart_groq`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_openai_compatible` (internal dependency)

## Base URL

Default base URL:

- `https://api.groq.com/openai/v1/`

## Authentication

LLM Dart uses OpenAI-style bearer auth:

- `Authorization: Bearer <GROQ_API_KEY>`

You can override/extend headers via:

- `providerOptions['groq']['extraHeaders']`

Official docs:

- Groq API (OpenAI-compatible): https://console.groq.com/docs

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';

Future<void> main() async {
  registerGroq();

  final model = await LLMBuilder()
      .provider(groqProviderId)
      .apiKey('GROQ_API_KEY')
      .model('qwen/qwen3-32b')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Groq!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Provider options (Groq deltas)

Groq follows the Vercel AI SDK provider option shapes and maps them into the
Chat Completions request body (best-effort).

Reference:

- `docs/provider_options_reference.md`
- `docs/protocols/openai_compatible.md`
- Vercel Groq provider: `repo-ref/ai/packages/groq`

Common keys:

- `reasoningFormat`: `String` (`parsed`/`raw`/`hidden`) → `reasoning_format`
- `reasoningEffort`: `String` (`low`/`medium`/`high`/`none`/`default`) → `reasoning_effort`
- `structuredOutputs`: `bool` (default: `true`)
  - When `true` and `jsonSchema` is set: uses `response_format.type=json_schema`
  - When `false` and `jsonSchema` is set: uses `response_format.type=json_object`
- `serviceTier`: `String` (`on_demand`/`flex`/`auto`) → `service_tier`
- `parallelToolCalls`: `bool` → `parallel_tool_calls`
- `user`: `String` → `user` (overrides `LLMConfig.user` if both are set)
- Escape hatches:
  - `extraBody`: `Map<String, dynamic>`
  - `extraHeaders`: `Map<String, String>`

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For Groq, the namespace is:

- `providerMetadata['groq']`

The OpenAI-compatible layer surfaces best-effort metadata such as:

- `id`, `model`, `systemFingerprint`, `finishReason`

## Conformance tests

Groq-specific request mapping tests:

- `test/providers/groq/groq_provider_options_request_body_test.dart`

OpenAI-compatible baseline tests:

- `test/protocols/openai_compatible/request_builder_conformance_test.dart`
- `test/providers/openai_compatible/openai_compatible_stream_parts_test.dart`
