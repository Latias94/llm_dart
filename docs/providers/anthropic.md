# Anthropic (Claude) Guide

This guide documents how to use Anthropic via `llm_dart_anthropic`.

Anthropic is considered a “standard provider” in `llm_dart` (Vercel-style).
The recommended provider-agnostic surface is `llm_dart_ai` task APIs, while
provider-specific functionality is accessed via:

- `providerOptions['anthropic']`
- `providerTools` (provider-executed tools)
- `providerMetadata['anthropic']`

## Packages

- Provider: `llm_dart_anthropic`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_anthropic_compatible` (internal dependency)

## Base URL

Default base URL:

- `https://api.anthropic.com/v1/`

## Authentication headers

LLM Dart uses Anthropic-style headers:

- `x-api-key: <ANTHROPIC_API_KEY>`
- `anthropic-version: 2023-06-01`

Beta features are enabled by adding an `anthropic-beta` header. LLM Dart adds
some beta headers automatically when a feature requires it (see below), and you
can always override/extend headers via `providerOptions['anthropic']['extraHeaders']`.

Official docs:

- Beta headers: https://platform.claude.com/docs/en/api/beta-headers

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_anthropic/provider_tools.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

Future<void> main() async {
  registerAnthropic();

  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey('ANTHROPIC_API_KEY')
      .model('claude-sonnet-4-20250514')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Anthropic!')],
  );

  print(result.text);

  final anthropic = readProviderMetadata<Map<String, dynamic>>(
    result.providerMetadata,
    anthropicProviderId,
  );
  print(anthropic);
}
```

## Thinking (extended thinking)

Enable thinking via provider options (best-effort):

- `providerOptions['anthropic']['reasoning'] = true`
- `providerOptions['anthropic']['thinkingBudgetTokens'] = <int>`
- `providerOptions['anthropic']['interleavedThinking'] = <bool>`

Note: When thinking is enabled, tool loops must preserve the full assistant
content blocks between turns. `llm_dart_ai` tool loop helpers handle this for you.

Official docs:

- Extended thinking: https://platform.claude.com/docs/en/build-with-claude/extended-thinking

## Prompt caching

Configure default caching via:

- `providerOptions['anthropic']['cacheControl']` (Anthropic `cache_control` shape)

LLM Dart applies caching markers best-effort when compiling requests.

Official docs:

- Prompt caching: https://platform.claude.com/docs/en/build-with-claude/prompt-caching

## Provider-native web search (server tool)

Anthropic supports provider-executed web search via the server tool:

- tool type: `web_search_20250305`
- tool name: `web_search`

Recommended configuration (typed `providerTools`):

```dart
LLMConfig(
  providerTools: [
    AnthropicProviderTools.webSearch(
      toolType: 'web_search_20250305',
      options: const AnthropicWebSearchToolOptions(maxUses: 3),
    ),
  ],
);
```

Official docs:

- Web search tool: https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool

## Provider-native web fetch (server tool)

Anthropic supports provider-executed web fetch via the server tool:

- tool type: `web_fetch_20250910`
- tool name: `web_fetch`

Important: the docs require the beta header:

- `anthropic-beta: web-fetch-2025-09-10`

LLM Dart automatically adds this beta header when provider-native web fetch is
enabled (Anthropic provider only). You can always override headers via
`providerOptions['anthropic']['extraHeaders']`.

Recommended configuration (typed `providerTools`):

```dart
LLMConfig(
  providerTools: [
    AnthropicProviderTools.webFetch(
      toolType: 'web_fetch_20250910',
      options: const AnthropicWebFetchToolOptions(maxUses: 2),
    ),
  ],
);
```

Official docs:

- Web fetch tool: https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-fetch-tool

## Provider-native code execution (server tool)

Anthropic supports provider-executed code execution via the server tool:

- tool type: `code_execution_20250825`
- tool name: `code_execution`

Recommended configuration (typed `providerTools`):

```dart
LLMConfig(
  providerTools: const [
    AnthropicProviderTools.codeExecution(toolType: 'code_execution_20250825'),
  ],
);
```

## Provider-native tools (client-executed)

Anthropic also defines provider-specific tools that are **client-executed**:

- `bash` (`anthropic.bash_20250124`)
- `computer` (`anthropic.computer_20251124`, `computer_20250124`, ...)
- text editor (`anthropic.text_editor_*` => tool name is `str_replace_editor` or `str_replace_based_edit_tool` depending on version)
- `memory` (`anthropic.memory_20250818`)

In `llm_dart`:

- Enable them via `providerTools` (so the request includes the tool definition).
- Provide local handlers in the tool loop. Anthropic streaming parsers surface
  these tool calls as `LLMProviderToolCallPart(providerExecuted=false)` and the
  tool loop executes them using `toolHandlers` (tool name == function name).

Helper module: `AnthropicClientExecutedTools` (in `llm_dart_ai`) provides input
parsers and handler factories.

Example (bash):

```dart
final model = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey('ANTHROPIC_API_KEY')
    .model('claude-sonnet-4-20250514')
    .providerTool(AnthropicProviderTools.bash())
    .build();

await streamToolLoopParts(
  model: model,
  messages: const [ChatMessage.user('Run: echo hello')],
  tools: const [],
  toolHandlers: {
    'bash': AnthropicClientExecutedTools.bashHandler(
      execute: (input, {cancelToken}) async {
        // Run input.command in your environment and return a string result.
        return 'ok';
      },
    ),
  },
  needsApproval: AnthropicClientExecutedTools.alwaysRequireApproval(),
).drain();
```

## Streaming

Anthropic streaming uses SSE. LLM Dart parses the stream and emits `LLMStreamPart`
items (parts-first, Vercel AI SDK style).

### Streaming example (LLMStreamPart)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

Future<void> main() async {
  registerAnthropic();

  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey(Platform.environment['ANTHROPIC_API_KEY'] ?? 'ANTHROPIC_API_KEY')
      .model('claude-sonnet-4-20250514')
      // Optional: enable provider-executed web search (server tool).
      // .providerTool(AnthropicProviderTools.webSearch())
      .build();

  await for (final part in streamChatParts(
    model: model,
    messages: const [ChatMessage.user('Give me 3 bullet points about SSE.')],
  )) {
    switch (part) {
      case LLMStreamStartPart(:final warnings):
        if (warnings.isNotEmpty) stderr.writeln('warnings: $warnings');
      case LLMResponseMetadataPart(:final id, :final modelId, :final timestamp):
        stderr.writeln('meta: id=$id modelId=$modelId ts=$timestamp');
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMReasoningDeltaPart(:final delta):
        // Extended thinking (if enabled) streams here.
        stderr.write(delta);
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
- Provider-executed server tools (e.g. `web_search` / `web_fetch`) are surfaced
  via `LLMProviderTool*Part` (parts-only) and must never be executed locally.

## References

- Messages API: https://platform.claude.com/docs/en/api/messages
- Create message: https://platform.claude.com/docs/en/api/messages/create
- Token counting: https://platform.claude.com/docs/en/api/messages/count-tokens
- Models: https://platform.claude.com/docs/en/api/models
