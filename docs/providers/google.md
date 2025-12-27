# Google (Gemini) Guide

This guide documents how to use Google Gemini via `llm_dart_google`.

Google (Gemini) is considered a “standard provider” in `llm_dart` (Vercel-style).
The recommended provider-agnostic surface is `llm_dart_ai` task APIs, while
Gemini-specific functionality is accessed via:

- `providerOptions['google']`
- `providerTools` (provider-executed tools)
- `providerMetadata['google']`

## Packages

- Provider: `llm_dart_google`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`

## Base URL

Default base URL:

- `https://generativelanguage.googleapis.com/v1beta/`

## Authentication

LLM Dart uses Gemini API key authentication via query parameter:

- `?key=<GEMINI_API_KEY>`

You can still customize HTTP behavior via `transportOptions`, and provider-only
request knobs via `providerOptions['google']`.

Official docs:

- Gemini API docs: https://ai.google.dev/gemini-api/docs
- API reference: https://ai.google.dev/api

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  registerGoogle();

  final model = await LLMBuilder()
      .provider(googleProviderId)
      .apiKey('GEMINI_API_KEY')
      .model('gemini-2.0-flash')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Gemini!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Provider-native tools (grounding / web search)

Gemini grounding / web search is treated as a **provider-executed** tool.

Recommended configuration (typed `providerTools`):

```dart
import 'package:llm_dart_google/llm_dart_google.dart';

final model = await LLMBuilder()
    .provider(googleProviderId)
    .apiKey('GEMINI_API_KEY')
    .model('gemini-2.0-flash')
    .providerTool(
      GoogleProviderTools.webSearch(
        options: const GoogleWebSearchToolOptions(
          mode: GoogleDynamicRetrievalMode.dynamic,
          dynamicThreshold: 0.3,
        ),
      ),
    )
    .build();
```

Legacy/best-effort escape hatches:

- `providerOptions['google']['webSearchEnabled']`
- `providerOptions['google']['webSearch']` (legacy; prefer `providerTools`)

Notes:

- LLM Dart handles tool name collisions via `ToolNameMapping` (local function
  tools are rewritten only if they collide with provider-native tool names).

## Thinking / reasoning options

Gemini-specific thinking knobs live behind provider options (best-effort):

- `providerOptions['google']['includeThoughts'] = true`
- `providerOptions['google']['thinkingBudgetTokens'] = <int>`
- `providerOptions['google']['reasoningEffort'] = 'low'|'medium'|'high'`

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For Google, the namespace is:

- `providerMetadata['google']`

The provider surfaces best-effort metadata such as:

- request/response identifiers (when available)
- safety/usage details (when available)

## Streaming

Gemini streaming uses a JSON stream (not SSE). LLM Dart parses the stream and
emits standard `LLMStreamPart` items, including text deltas and tool call parts.

Official docs:

- Streaming: https://ai.google.dev/gemini-api/docs/text-generation#streaming

## References

- Provider tools catalog: `docs/provider_tools_catalog.md`
- Provider options reference: `docs/provider_options_reference.md`
- Escape hatches: `docs/provider_escape_hatches.md`
