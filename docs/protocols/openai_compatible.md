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
