# OpenAI (GPT) Guide

This guide documents how to use OpenAI via `llm_dart_openai`.

OpenAI is considered a “standard provider” in `llm_dart` (Vercel-style).
The recommended provider-agnostic surface is `llm_dart_ai` task APIs, while
OpenAI-specific functionality is accessed via:

- `providerOptions['openai']`
- `providerTools` (provider-executed tools)
- `providerMetadata['openai']` (canonical) + capability aliases (`openai.chat`, `openai.responses`)

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

In LLM Dart, the API surface is selected by provider id:

- Responses API (default OpenAI surface): providerId `openai`
- Chat Completions (explicit baseline surface): providerId `openai.chat`

Notes:

- Responses-only options (e.g. `previousResponseId`, `builtInTools`) require
  providerId `openai`.
- `openai.chat` rejects provider-native tools (`providerTools`).

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

- `OpenAIProviderTools.webSearchPreview(...)` → `web_search_preview`
- `OpenAIProviderTools.fileSearch(...)` → `file_search`
- `OpenAIProviderTools.computerUse(...)` → `computer_use_preview`

Example (web search):

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/provider_tools.dart';

final model = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('OPENAI_API_KEY')
    .model('gpt-4o')
    .providerTool(
      OpenAIProviderTools.webSearchPreview(
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

### Client-executed provider tools

Some OpenAI Responses tools are "provider-native" in the protocol, but require
**client execution** (e.g. `shell`, `local_shell`, `apply_patch`).

LLM Dart parses these as `LLMProviderToolCallPart(providerExecuted=false)` and
the tool loop can execute them locally.

The `llm_dart_ai` package provides lightweight handler templates:

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';

final toolHandlers = <String, ToolCallHandler>{
  'shell': OpenAIClientExecutedTools.shellHandler(
    onShell: (action, {cancelToken}) async {
      // Execute action.commands safely in your own sandbox.
      return {
        'output': [
          {
            'stdout': 'ok',
            'stderr': '',
            'outcome': {'type': 'exit', 'exitCode': 0},
          }
        ],
      };
    },
  ),
  'apply_patch': OpenAIClientExecutedTools.applyPatchHandler(
    execute: (input, {cancelToken}) async {
      // Apply patch operations in your own workspace logic.
      return const OpenAIApplyPatchOutput.completed('applied');
    },
  ),
};
```

Official docs:

- Built-in tools overview: https://platform.openai.com/docs/guides/tools

## Provider options (escape hatches)

Reference:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`

Common OpenAI keys (non-exhaustive):

- `previousResponseId`: `String` (Responses API only)
- `builtInTools`: `List<Map<String, dynamic>>` (Responses built-in tools)
- Prefer `providerTools` for Responses built-in tools (recommended).
- `extraBody` / `extraHeaders` (escape hatches)

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For OpenAI, the canonical namespace key is:

- `providerMetadata['openai']`

For Vercel AI SDK parity, LLM Dart also emits capability aliases:

- `providerMetadata['openai.chat']` (Chat Completions)
- `providerMetadata['openai.responses']` (Responses API)

The alias payload is deep-equal to `providerMetadata['openai']`.
Downstream code should prefer reading the canonical `openai` key.

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

### Streaming example (LLMStreamPart)

This is the recommended way to consume streaming output, because it exposes:

- `LLMStreamStartPart` warnings (if any)
- `LLMResponseMetadataPart` (response id/model/timestamp snapshots)
- citations/sources (`LLMSourceUrlPart` / `LLMSourceDocumentPart`)
- provider-executed tools (`LLMProviderTool*Part`)
- typed `usage` + `finishReason` (on `LLMFinishPart`, when available)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  registerOpenAI();

  final model = await LLMBuilder()
      .provider(openaiProviderId)
      .apiKey(Platform.environment['OPENAI_API_KEY'] ?? 'OPENAI_API_KEY')
      .model('gpt-4o')
      // Optional: enable provider-executed web search (Responses API).
      // .providerTool(OpenAIProviderTools.webSearch())
      .build();

  await for (final part in streamChatParts(
    model: model,
    messages: const [ChatMessage.user('Explain streaming in 2 sentences.')],
  )) {
    switch (part) {
      case LLMStreamStartPart(:final warnings):
        if (warnings.isNotEmpty) stderr.writeln('warnings: $warnings');
      case LLMResponseMetadataPart(:final id, :final modelId, :final timestamp):
        stderr.writeln('meta: id=$id modelId=$modelId ts=$timestamp');
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMSourceUrlPart(:final url, :final title):
        stderr.writeln('\nsource: ${title ?? '(no title)'} $url');
      case LLMProviderToolCallPart(:final toolName, :final toolCallId):
        stderr.writeln('\nprovider tool call: $toolName ($toolCallId)');
      case LLMProviderToolResultPart(:final toolName, :final toolCallId):
        stderr.writeln('\nprovider tool result: $toolName ($toolCallId)');
      case LLMFinishPart(:final finishReason, :final usage):
        stderr.writeln('\nfinish: $finishReason usage=$usage');
      case LLMErrorPart(:final error):
        stderr.writeln('error: $error');
      default:
        // Ignore other part types for this example.
        break;
    }
  }
}
```

### Notes

- Legacy `chatStream()` / `ChatStreamEvent` was removed (breaking).
- Consume `LLMStreamPart` via `streamChatParts()` / `streamToolLoopParts()`.

Official docs:

- Responses streaming: https://platform.openai.com/docs/api-reference/responses/streaming
- Chat Completions streaming: https://platform.openai.com/docs/api-reference/chat/streaming
