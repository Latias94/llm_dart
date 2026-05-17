# Anthropic Language Model Orchestration Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` Anthropic provider
layers, especially:

- `repo-ref/ai/packages/anthropic/src/anthropic-language-model.ts`
- `repo-ref/ai/packages/anthropic/src/convert-to-anthropic-prompt.ts`
- `repo-ref/ai/packages/anthropic/src/anthropic-prepare-tools.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps the language model as the provider adapter entrypoint while
separating request argument preparation, HTTP dispatch, JSON response handling,
and stream event transformation. The Dart implementation keeps
`AnthropicLanguageModel` as the provider-facing adapter and moves its
orchestration details behind focused internal modules.

## Problem

`packages/llm_dart_anthropic/lib/src/anthropic_language_model.dart` mixed
several independent reasons to change:

- Anthropic provider option resolution
- Messages request encoding
- token-count request encoding
- messages and count-tokens URI selection
- beta/header merging
- request timeout, retry, and cancellation projection
- non-streaming response JSON coercion and result decoding
- SSE JSON chunk parsing
- raw chunk event forwarding
- stream state ownership
- token-count response validation and result construction
- transport error mapping

The public model adapter seam was useful, but the implementation was shallow:
header policy, token-count behavior, stream decoding, and request preparation
all required editing the model entrypoint.

## Decision

Keep `AnthropicLanguageModel` as the public provider adapter and split internal
orchestration:

- `anthropic_language_model_request.dart`
  - provider option resolution
  - Messages request encoding
  - token-count request encoding
- `anthropic_language_model_transport.dart`
  - messages and count-tokens route URI resolution
  - `TransportRequest` construction
  - beta/header merging, timeout, retry, cancellation, and response type
    projection
- `anthropic_language_model_response.dart`
  - non-streaming response JSON coercion and result decoding
- `anthropic_language_model_stream.dart`
  - SSE JSON chunk parsing
  - raw chunk forwarding
  - stream state creation and chunk decoding
- `anthropic_language_model_token_count.dart`
  - token-count response JSON coercion
  - `input_tokens` validation and result construction
- `anthropic_language_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - generate/stream/token-count orchestration

This mirrors the OpenAI and Google provider adapter shape without changing
Anthropic Messages wire codecs or replay behavior.

## Behavior Contract

The refactor preserves these contracts:

- `AnthropicLanguageModel` constructor, fields, `providerId`,
  `capabilityProfile`, `messagesUri`, `countTokensUri`, `doGenerate`,
  `doStream`, and `countTokens` remain available.
- provider option resolution still rejects mismatched provider options.
- request warnings are still emitted before streaming transport starts.
- settings beta features, request beta features, runtime beta headers, custom
  headers, and Anthropic version headers are merged as before.
- messages and count-tokens request URIs, timeout, max retries, cancellation,
  response type, and body behavior are unchanged.
- non-streaming Messages response decoding is unchanged.
- stream raw chunk forwarding, stream state, chunk decoding, and transport
  error mapping are unchanged.
- token-count response `input_tokens` validation and warnings are unchanged.

## Benefits

Locality improves because request preparation, beta/header transport
projection, response decoding, stream decoding, and token-count decoding now
change in separate modules.

Leverage improves because `AnthropicLanguageModel` remains a small provider
model entrypoint over deeper Anthropic-specific adapters. OpenAI, Google, and
Anthropic now share the same provider adapter pattern.
