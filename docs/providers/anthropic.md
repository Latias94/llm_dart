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
  print(result.providerMetadata);
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

Legacy/best-effort escape hatches:

- `providerOptions['anthropic']['webSearchEnabled']`
- `providerOptions['anthropic']['webSearch']`

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

Legacy/best-effort escape hatches:

- `providerOptions['anthropic']['webFetchEnabled']`
- `providerOptions['anthropic']['webFetch']`

Official docs:

- Web fetch tool: https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-fetch-tool

## References

- Messages API: https://platform.claude.com/docs/en/api/messages
- Create message: https://platform.claude.com/docs/en/api/messages/create
- Token counting: https://platform.claude.com/docs/en/api/messages/count-tokens
- Models: https://platform.claude.com/docs/en/api/models

