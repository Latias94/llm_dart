# MiniMax (Anthropic-compatible) Guide

This guide documents how to use MiniMax via `llm_dart_minimax`.

MiniMax is integrated through the **Anthropic Messages API compatible** protocol
layer (`llm_dart_anthropic_compatible`). LLM Dart follows a best-effort approach:
we forward requests as-is and do **not** maintain a provider/model support matrix.

## Packages

- Provider: `llm_dart_minimax`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_anthropic_compatible` (internal dependency)

## Base URL (and normalization)

MiniMax docs list Anthropic-compatible base URLs without `/v1`:

- International: `https://api.minimax.io/anthropic`
- China: `https://api.minimaxi.com/anthropic`

Official docs:

- https://platform.minimax.io/docs/api-reference/text-anthropic-api

Vercel's community provider defaults to the international endpoint
(`https://api.minimax.io/anthropic/v1`) and expects China-region users to
override `baseURL` explicitly.

LLM Dart accepts both forms and normalizes them to an Anthropic Messages-style
`/v1/` base URL:

- `https://api.minimax.io/anthropic` → `https://api.minimax.io/anthropic/v1/`
- `https://api.minimaxi.com/anthropic` → `https://api.minimaxi.com/anthropic/v1/`

Constants exported by `llm_dart_minimax`:

- `minimaxAnthropicBaseUrl` / `minimaxiAnthropicBaseUrl` (without `/v1/`)
- `minimaxAnthropicV1BaseUrl` / `minimaxiAnthropicV1BaseUrl` (with `/v1/`)

Recommended: use the `*V1BaseUrl` constants.

## Environment variables (recommended naming)

MiniMax docs sometimes use Anthropic SDK naming (`ANTHROPIC_BASE_URL` /
`ANTHROPIC_API_KEY`). In LLM Dart, prefer MiniMax-scoped env vars to avoid
collisions with a real Anthropic configuration:

- `MINIMAX_API_KEY`
- `MINIMAX_BASE_URL` (set to either `https://api.minimax.io/anthropic` or
  `https://api.minimaxi.com/anthropic`)

## Authentication headers

For the Anthropic-compatible API, LLM Dart uses Anthropic-style headers:

- `x-api-key: <MINIMAX_API_KEY>`
- `anthropic-version: 2023-06-01`

Note: Some MiniMax docs show `Authorization: Bearer ...` for the OpenAI-compatible
API. `llm_dart_minimax` targets the Anthropic-compatible API, so it uses `x-api-key`.

## Model ids

LLM Dart provides `minimaxDefaultModel` and a `minimaxKnownModels` list as a
**documentation snapshot** (not a support matrix). MiniMax can change model ids
over time; the API is the source of truth.

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

Future<void> main() async {
  registerMinimax();

  final model = await LLMBuilder()
      .provider(minimaxProviderId)
      .apiKey('MINIMAX_API_KEY')
      .baseUrl(minimaxAnthropicV1BaseUrl) // China: minimaxiAnthropicV1BaseUrl
      .model(minimaxDefaultModel)
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from MiniMax!')],
  );

  print(result.text);
  print(result.providerMetadata); // optional provider-specific metadata
}
```

## Provider options and escape hatches

MiniMax reads provider options from:

1) `providerOptions['minimax']`
2) then falls back to `providerOptions['anthropic']` for shared Anthropic shapes

Common keys (best-effort):

- `reasoning`, `thinkingBudgetTokens`, `interleavedThinking`
- `metadata`, `container`, `mcpServers`
- `cacheControl` (Anthropic prompt caching shape)
- `extraHeaders`: merged into request headers
- `extraBody`: merged into request JSON

Reference:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`

## Tool calling and tool loops

MiniMax (Anthropic-compatible) may require callers to preserve the **full
assistant content blocks** between turns for function calling continuity. LLM
Dart’s `runToolLoop*` / `streamToolLoop*` utilities do this automatically.

If you implement your own loop, store and replay the full assistant message
content blocks instead of reconstructing them from plain text.

## Web search

LLM Dart does not provide a single cross-provider “web search” abstraction.

- Provider-native web search (e.g. Anthropic-compatible `web_search_*`) is
  configured via `providerTools` / `providerOptions` and executed server-side by
  the provider when supported.
- Local web search (HTTP fetch + parsing) is an app concern and should be built
  as local tools (function tools) in your application or examples.

## References

- Vercel AI SDK docs (MiniMax community provider): `repo-ref/ai/content/providers/03-community-providers/50-minimax.mdx`
- MiniMax Vercel provider source: https://github.com/MiniMax-AI/vercel-minimax-ai-provider
