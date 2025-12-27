# llm_dart_minimax

MiniMax provider package for `llm_dart`.

This package currently focuses on MiniMax **Anthropic-compatible** text generation (e.g. MiniMax M2 via the Anthropic Messages API shape).

## Guide

- MiniMax guide (in this repo): [docs/providers/minimax.md](../../docs/providers/minimax.md)

## Notes (compatibility)

MiniMax's Anthropic-compatible interface currently:

- Is expected to follow Anthropic Messages API wire format (MiniMax docs).
- Uses `x-api-key: <apiKey>` and keeps `anthropic-version: 2023-06-01` (aligned with Vercel's `vercel-minimax-ai-provider` implementation).
- Note: Some MiniMax docs may show `Authorization: Bearer ...` for the OpenAI-compatible API. For the Anthropic-compatible API (this package), we follow Vercel's provider implementation and use `x-api-key`.
- MiniMax docs may mention Anthropic SDK-style environment variables
  (`ANTHROPIC_BASE_URL` / `ANTHROPIC_API_KEY`) for use with Anthropic SDKs.
  In LLM Dart, prefer MiniMax-scoped environment variables to avoid collisions
  with a real Anthropic configuration:
  - `MINIMAX_BASE_URL=https://api.minimax.io/anthropic` (international) or
    `MINIMAX_BASE_URL=https://api.minimaxi.com/anthropic` (China)
  - `MINIMAX_API_KEY=${YOUR_API_KEY}`
- MiniMax docs list provider-side limitations/behavior (LLM Dart does **not**
  enforce these constraints and does **not** strip request fields; the API is
  the source of truth):
  - Known Anthropic-compatible model ids include `MiniMax-M2.1` / `MiniMax-M2.1-lightning` / `MiniMax-M2` / `MiniMax-M1` / `MiniMax-M1-80k` (MiniMax docs; this list can change)
  - `temperature` range is `(0.0, 1.0]` (out-of-range values return an error)
  - Some Anthropic parameters are ignored: `thinking`, `top_k`, `stop_sequences`,
    `service_tier`, `mcp_servers`, `context_management`, `container`
  - Image/document inputs are not currently supported
- Requires tool-loop callers to preserve the **full assistant content blocks**
  between turns for function calling continuity (LLM Dart's `runToolLoop*` does
  this automatically)

## Install

```bash
dart pub add llm_dart_minimax llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

void main() {
  registerMinimax();
}
```

## Quick start (builder + task APIs)

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
      .baseUrl(minimaxAnthropicV1BaseUrl)
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

## Provider options (escape hatches)

MiniMax reuses the Anthropic-compatible transport, but reads provider options from:

- `providerOptions['minimax']` first
- then falls back to `providerOptions['anthropic']`

Common escape hatches:

- `providerOptions['minimax']['cacheControl']`: Anthropic prompt caching shape (e.g. `{'type': 'ephemeral'}`)
- `providerOptions['minimax']['extraBody']`: merged into request JSON (for provider-only parameters)
- `providerOptions['minimax']['extraHeaders']`: merged into request headers

Base URL notes:

- LLM Dart defaults to the Vercel-style Anthropic-compatible base URL:
  `https://api.minimax.io/anthropic/v1/`.
- MiniMax docs use `https://api.minimax.io/anthropic` (without `/v1`). LLM Dart
  accepts both and normalizes to an Anthropic Messages-style `/v1/` base.
- China-region users typically need to override the base URL explicitly:
  `https://api.minimaxi.com/anthropic` (normalized to `/anthropic/v1/`).

## Example

Tool approval interrupt + manual resume:

- `example/04_providers/minimax/anthropic_compatible_tool_approval.dart`

Local web search (FunctionTool) + tool loop:

- `example/04_providers/minimax/local_web_search_tool_loop.dart`
