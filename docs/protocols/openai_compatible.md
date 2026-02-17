# OpenAI-compatible Protocol Layer (Chat Completions baseline)

This document tracks how `llm_dart_openai_compatible` aligns with the OpenAI
**Chat Completions** API documentation.

Scope:

- The **wire protocol** layer: request JSON compilation, streaming parsing, and
  best-effort passthrough for OpenAI-style optional params.
- Reused by multiple provider packages (Groq / DeepSeek / xAI / OpenRouter /
  Google OpenAI-compatible, etc.).

Non-goals:

- Modeling OpenAI **Responses API** semantics (OpenAI-only; see `docs/adp/0007-openai-responses-openai-only.md`).
- Maintaining provider/model support matrices (best-effort forwarding only).

## Official docs (baseline references)

Primary:

- Chat Completions API: https://platform.openai.com/docs/api-reference/chat
- Streaming (Chat Completions): https://platform.openai.com/docs/api-reference/chat/streaming

Related:

- Tool calling (OpenAI guides): https://platform.openai.com/docs/guides/function-calling
- Structured outputs (OpenAI guides): https://platform.openai.com/docs/guides/structured-outputs

Reference implementation (Vercel AI SDK):

- `repo-ref/ai/packages/openai-compatible`

## Package mapping (where things live)

Request compilation:

- `packages/llm_dart_openai_compatible/lib/src/request_builder.dart`

HTTP client + SSE parsing:

- `packages/llm_dart_openai_compatible/lib/src/client.dart`
- `packages/llm_dart_provider_utils/lib/utils/sse_chunk_parser.dart`

Streaming → standard parts:

- `packages/llm_dart_openai_compatible/lib/src/chat.dart`

## Escape hatches and provider-specific deltas

### Namespaced providerOptions (Vercel-style)

Provider-only knobs are read from `LLMConfig.providerOptions[providerId]`.

Important: `providerId` depends on **which provider you registered/selected**.

Examples (dedicated provider packages in `packages/`):

- Groq: `providerOptions['groq']`
- DeepSeek: `providerOptions['deepseek']`
- xAI: `providerOptions['xai']`
- OpenRouter: `providerOptions['openrouter']`
- Google OpenAI-compatible: `providerOptions['google-openai']` (fallback: `google`)

Examples (pre-configured OpenAI-compatible registries from `llm_dart_openai_compatible`):

- Groq: `providerOptions['groq-openai']`
- DeepSeek: `providerOptions['deepseek-openai']`
- xAI: `providerOptions['xai-openai']`

Reference:

- `docs/provider_options_reference.md`

### `extraBody` / `extraHeaders`

These are best-effort escape hatches used to forward provider-specific fields:

- `providerOptions[providerId]['extraBody']`: merged into request JSON (wins on collisions)
- `providerOptions[providerId]['extraHeaders']`: merged into request headers (wins on collisions)

Google OpenAI-compatible fallback/merge rules:

- When `providerId == 'google-openai'`, option reads fall back to `providerOptions['google']`.
- For map-shaped options, we merge with precedence:
  - `providerOptions['google-openai']` > `providerOptions['google']` > `providerOptions['openai-compatible']`
  - Applies to: `headers`, `extraHeaders`, `queryParams`, `extraBody`.
  - Non-map options (e.g. `includeUsage`) are best-effort fallback only (no merge).

Implementation:

- JSON merge happens at the end of request compilation in
  `packages/llm_dart_openai_compatible/lib/src/request_builder.dart`.
- Header merge is handled by the Dio strategy in
  `packages/llm_dart_openai_compatible/lib/src/dio_strategy.dart`.

### Known deltas implemented in this layer

These are intentionally **not standardized** in `llm_dart_ai`; they live behind
`providerOptions` and are compiled best-effort:

- Groq (`groq` / `groq-openai`):
  - `structuredOutputs=false` downgrades `json_schema` → `json_object`
  - `serviceTier` override
  - `reasoningFormat` / `reasoningEffort` raw passthrough
- DeepSeek (`deepseek` / `deepseek-openai`):
  - `responseFormat` passthrough to `response_format` (best-effort)
- xAI (`xai` / `xai-openai`):
  - `liveSearch` / `searchParameters` → `search_parameters`

Common best-effort OpenAI Chat Completions optional params are also forwarded
for all OpenAI-compatible providers (penalties, logprobs, etc.):

- `docs/provider_options_reference.md` (section “OpenAI-compatible (Chat Completions) optional params”)

## Conformance tests (offline/mocked)

Request builder conformance:

- `test/protocols/openai_compatible/request_builder_conformance_test.dart`

Streaming parts conformance:

- `test/providers/openai_compatible/openai_compatible_stream_parts_test.dart`
- `test/protocols/openai_compatible/openai_compatible_streaming_usage_tail_conformance_test.dart` (usage tail chunks)

Provider packages that reuse this protocol layer should add their own delta
tests under `test/providers/<provider>/...` (e.g. Groq/xAI/OpenRouter).

## Streaming (LLMStreamPart)

This protocol layer maps Chat Completions SSE deltas into `LLMStreamPart`
(parts-first, Vercel AI SDK style). This is the recommended way to consume
streaming output, because it exposes:

- `LLMResponseMetadataPart` (response id/model/timestamp snapshots)
- structural text/thinking/tool boundaries
- typed `usage` + `finishReason` (on `LLMFinishPart`, when available)

Note: provider-executed tools and citations are provider-specific. Some
OpenAI-compatible providers add extra fields (e.g. xAI `citations`) that LLM Dart
surfaces best-effort via parts.

### Streaming example (parts)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

Future<void> main() async {
  registerDeepSeek();

  final model = await LLMBuilder()
      .provider(deepseekProviderId)
      .apiKey(Platform.environment['DEEPSEEK_API_KEY'] ?? 'DEEPSEEK_API_KEY')
      .model('deepseek-chat')
      .build();

  await for (final part in streamChatParts(
    model: model,
    messages: const [ChatMessage.user('Write one sentence about HTTP.')],
  )) {
    switch (part) {
      case LLMResponseMetadataPart(:final id, :final modelId):
        stderr.writeln('meta: id=$id modelId=$modelId');
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMToolCallStartPart(:final toolCall):
        stderr.writeln('\ntool call: ${toolCall.function.name} (${toolCall.id})');
      case LLMSourceUrlPart(:final url):
        // Example: xAI citations (when enabled) are surfaced as sources.
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

### Notes

- Azure may send `usage` in a trailing chunk after the finish_reason chunk.
  LLM Dart captures it best-effort (guarded by conformance tests).
- Legacy `chatStream()` / `ChatStreamEvent` was removed (breaking). Use
  parts-first streaming (`chatStreamParts` / `LLMStreamPart`).
