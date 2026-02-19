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
- `providerMetadata['xai']`

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
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

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

  final xai = readProviderMetadata<Map<String, dynamic>>(
    result.providerMetadata,
    xaiProviderId,
  );
  print(xai);
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

- Configure live search via `liveSearch/searchParameters`.

References:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`
- `docs/protocols/openai_compatible.md`
- Vercel xAI provider: `repo-ref/ai/packages/xai`

## Citations (Chat Completions)

xAI can return a top-level `citations` array (URLs) on Chat Completions
responses.

Enable it via `providerOptions['xai']` (AI SDK parity):

- Prefer: `searchParameters.returnCitations: true` → request field
  `search_parameters.return_citations: true`
- Legacy alias: `returnCitations: true` (only applied when live search is
  enabled via `liveSearch/searchParameters`)

When citations are present:

- Streaming (`chatStreamParts`): emits one `LLMSourceUrlPart` per cited URL
  (deduped).
- Non-streaming (`chat`): exposes `providerMetadata['xai']['citations']` as
  `List<String>` (URLs).

Example:

```dart
final model = await LLMBuilder()
    .provider(xaiProviderId)
    .apiKey('XAI_API_KEY')
    .model('grok-3')
    .providerOptions('xai', {
      'liveSearch': true,
      'searchParameters': SearchParameters.webSearch(
        returnCitations: true,
      ).toJson(),
    })
    .build();

final parts = await model
    .chatStreamParts([ChatMessage.user('Give me sources about xAI')])
    .toList();

final sources = parts.whereType<LLMSourceUrlPart>().toList();
print(sources.map((s) => s.url).toList());
```

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For xAI (Chat Completions), the canonical namespace key is:

- `providerMetadata['xai']`

Recommended access pattern (canonical + alias-safe):

```dart
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

final xai = readProviderMetadata<Map<String, dynamic>>(
  result.providerMetadata,
  xaiProviderId,
);

final id = xai?['id'];
final model = xai?['model'];
final finishReason = xai?['finishReason'];
final citations = xai?['citations'];
```

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

Provider metadata for `xai.responses` is emitted under:

- `providerMetadata['xai']`

Recommended access pattern:

```dart
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

final xaiResponses = readProviderMetadata<Map<String, dynamic>>(
  result.providerMetadata,
  'xai.responses',
);

final id = xaiResponses?['id'];
final model = xaiResponses?['model'];
final usage = xaiResponses?['usage'];
```

### Quick start (Responses)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
import 'package:llm_dart_xai/provider_tools.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

Future<void> main() async {
  registerXAI();

  final model = await LLMBuilder()
      .provider('xai.responses')
      .apiKey('XAI_API_KEY')
      .model('grok-4-fast')
      .providerTool(XAIProviderTools.webSearch())
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('What is xAI?')],
  );

  print(result.text);

  final xai = readProviderMetadata<Map<String, dynamic>>(
    result.providerMetadata,
    'xai.responses',
  );
  print(xai);
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

## Streaming (LLMStreamPart)

For the parts-first streaming surface, prefer `streamChatParts()` from
`llm_dart_ai`. This exposes:

- `LLMStreamStartPart` warnings (if any)
- `LLMResponseMetadataPart` snapshots (response id/model/timestamp)
- citations/sources (`LLMSourceUrlPart` / `LLMSourceDocumentPart`)
- provider-executed tools on `xai.responses` (`LLMProviderTool*Part`)
- typed `finishReason` + `usage` (on `LLMFinishPart`, when available)

### Streaming example (Chat Completions: `xai`)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

Future<void> main() async {
  registerXAI();

  final model = await LLMBuilder()
      .provider(xaiProviderId)
      .apiKey(Platform.environment['XAI_API_KEY'] ?? 'XAI_API_KEY')
      .model('grok-3')
      // Optional: request top-level citations (Chat Completions).
      .providerOptions('xai', const {'returnCitations': true})
      .build();

  await for (final part in streamChatParts(
    model: model,
    messages: const [ChatMessage.user('Give me 1 source about xAI.')],
  )) {
    switch (part) {
      case LLMResponseMetadataPart(:final id, :final modelId, :final timestamp):
        stderr.writeln('meta: id=$id modelId=$modelId ts=$timestamp');
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMSourceUrlPart(:final url):
        stderr.writeln('\nsource: $url');
      case LLMFinishPart(:final finishReason, :final usage):
        stderr.writeln('\nfinish: $finishReason usage=$usage');
      case LLMErrorPart(:final error):
        stderr.writeln('error: $error');
      default:
        break;
    }
  }
}
```

### Streaming example (Responses: `xai.responses`)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
import 'package:llm_dart_xai/provider_tools.dart';

Future<void> main() async {
  registerXAI();

  final model = await LLMBuilder()
      .provider('xai.responses')
      .apiKey(Platform.environment['XAI_API_KEY'] ?? 'XAI_API_KEY')
      .model('grok-4-fast')
      // Optional: enable provider-executed web search (server tool).
      .providerTool(XAIProviderTools.webSearch())
      .build();

  await for (final part in streamChatParts(
    model: model,
    messages: const [ChatMessage.user('Search and answer: what is Grok?')],
  )) {
    switch (part) {
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
        break;
    }
  }
}
```

Notes:

- Legacy `chatStream()` / `ChatStreamEvent` was removed (breaking).
- On `xai.responses`, provider-executed tools (web search, code execution, MCP)
  are surfaced via `LLMProviderTool*Part` (parts-only) and must never be executed locally.
