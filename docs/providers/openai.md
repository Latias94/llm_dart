# OpenAI (GPT) Guide

This guide documents how to use OpenAI via `llm_dart_openai`.

OpenAI is considered a “standard provider” in `llm_dart` (Vercel-style).
The recommended provider-agnostic surface is `llm_dart_ai` task APIs, while
OpenAI-specific functionality is accessed via:

- `providerOptions['openai']`
- `providerTools` (provider-executed tools)
- `providerMetadata['openai']`

## Packages

- Provider: `llm_dart_openai`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_openai_compatible` (Chat Completions baseline)

## Base URL

Default base URL:

- `https://api.openai.com/v1/`

## Authentication

LLM Dart uses OpenAI-style bearer auth:

- `Authorization: Bearer <OPENAI_API_KEY>`

You can override/extend headers via:

- `providerOptions['openai']['extraHeaders']`

Official docs:

- API reference: https://platform.openai.com/docs/api-reference

## Chat Completions vs Responses API

OpenAI has two “OpenAI-shaped” APIs:

- **Chat Completions**: widely implemented by OpenAI-compatible providers.
- **Responses**: OpenAI-only; includes OpenAI built-in tools (web search, file search, computer use).

In LLM Dart:

- `llm_dart_openai_compatible` targets **Chat Completions** only.
- The **Responses API** implementation lives in `llm_dart_openai` only
  (see `docs/adp/0007-openai-responses-openai-only.md`).

How the OpenAI provider decides:

- Default: Chat Completions
- Enable Responses API explicitly: `providerOptions['openai']['useResponsesAPI']=true`
- Responses is also enabled automatically when:
  - any OpenAI built-in tool is configured via `providerTools`, or
  - `webSearchEnabled` / `fileSearchEnabled` / `computerUseEnabled` is enabled.

Official docs:

- Responses API: https://platform.openai.com/docs/api-reference/responses
- Chat Completions: https://platform.openai.com/docs/api-reference/chat

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  registerOpenAI();

  final model = await LLMBuilder()
      .provider(openaiProviderId)
      .apiKey('OPENAI_API_KEY')
      .model('gpt-4.1-mini')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from OpenAI!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Provider-native built-in tools (Responses API)

OpenAI built-in tools are provider-executed (server-side). Configure them via
`providerTools` (recommended) using typed factories:

- `OpenAIProviderTools.webSearch(...)` → `web_search_preview`
- `OpenAIProviderTools.fileSearch(...)` → `file_search`
- `OpenAIProviderTools.computerUse(...)` → `computer_use_preview`

Example (web search):

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

final model = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('OPENAI_API_KEY')
    .model('gpt-4o')
    .providerTool(
      OpenAIProviderTools.webSearch(
        contextSize: OpenAIWebSearchContextSize.high,
      ),
    )
    .build();
```

Notes:

- The SDK does not rewrite `model`. If a built-in tool requires a specific model
  family, OpenAI should return an API error and the caller can adjust.
- If you also provide local `FunctionTool`s, LLM Dart applies tool name mapping
  to avoid collisions with built-in tool names (Vercel-style).

Official docs:

- Built-in tools overview: https://platform.openai.com/docs/guides/tools

## Provider options (escape hatches)

Reference:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`

Common OpenAI keys (non-exhaustive):

- `useResponsesAPI`: `bool`
- `previousResponseId`: `String` (Responses API only)
- `builtInTools`: `List<Map<String, dynamic>>` (Responses built-in tools)
- `webSearchEnabled` / `webSearch` (legacy best-effort; prefer `providerTools`)
- `fileSearchEnabled` / `fileSearch` (legacy best-effort; prefer `providerTools`)
- `computerUseEnabled` / `computerUse` (legacy best-effort; prefer `providerTools`)
- `extraBody` / `extraHeaders` (escape hatches)

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For OpenAI, the namespace is:

- `providerMetadata['openai']`

Chat Completions metadata (best-effort):

- `id`, `model`, `systemFingerprint`, `finishReason`

Responses metadata (best-effort, when available):

- `id`, `model`
- `webSearchCalls` (server-side web search calls)
- `fileSearchCalls` (server-side file search calls + results when included)
- `computerCalls` (computer use calls)
- `annotations` (e.g. URL citations from output text)

## Streaming

LLM Dart supports streaming on both API families:

- Chat Completions: SSE deltas mapped into `LLMStreamPart` via capability adapters.
- Responses: SSE events mapped into `LLMStreamPart`, including incremental tool call deltas.

Official docs:

- Responses streaming: https://platform.openai.com/docs/api-reference/responses/streaming
- Chat Completions streaming: https://platform.openai.com/docs/api-reference/chat/streaming

