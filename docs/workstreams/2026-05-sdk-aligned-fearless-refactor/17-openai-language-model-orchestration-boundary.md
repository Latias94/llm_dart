# OpenAI Language Model Orchestration Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` OpenAI provider layers,
especially:

- `repo-ref/ai/packages/openai/src/responses/openai-responses-language-model.ts`
- `repo-ref/ai/packages/openai/src/chat/openai-chat-language-model.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps the model object as the provider adapter entrypoint while
separating request argument preparation, HTTP dispatch, response decoding, and
stream event decoding. The Dart implementation keeps `OpenAILanguageModel` as
the provider-facing model adapter and moves the route-specific implementation
steps behind focused internal modules.

## Problem

`packages/llm_dart_openai/lib/src/openai_language_model.dart` had become the
place where several independent reasons to change met:

- OpenAI-family route selection
- Responses vs Chat Completions request encoding dispatch
- transport request URI, header, timeout, retry, and cancellation projection
- non-streaming response body decoding
- streaming SSE chunk parsing
- raw chunk event emission
- Responses and Chat Completions stream state ownership

The public model adapter seam was useful, but the implementation was shallow:
small changes to stream decoding or transport request projection required
editing the model entrypoint.

## Decision

Keep `OpenAILanguageModel` as the public provider adapter and split internal
orchestration:

- `openai_language_model_request.dart`
  - route-aware request encoding dispatch
  - prepared request body and warnings result
- `openai_language_model_transport.dart`
  - route URI resolution
  - `TransportRequest` construction
  - call option timeout, retry, cancellation, and header projection
- `openai_language_model_response.dart`
  - non-streaming response JSON coercion and route-aware result decoding
- `openai_language_model_stream.dart`
  - SSE JSON chunk parsing
  - raw chunk forwarding
  - Responses and Chat Completions stream-state creation and chunk decoding
- `openai_language_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - call resolution
  - generate/stream orchestration

## Behavior Contract

The refactor preserves these contracts:

- `OpenAILanguageModel` constructor, fields, `providerId`,
  `capabilityProfile`, `responsesUri`, `chatCompletionsUri`, and
  `defaultHeaders` remain available.
- route selection still uses `resolveOpenAILanguageModelCall`.
- Responses requests still receive `call.providerOptions.common`.
- Chat Completions requests still receive the full resolved provider options.
- request warnings are still emitted before streaming transport starts.
- transport request URI, headers, timeout, max retries, cancellation,
  JSON response type, and body behavior are unchanged.
- non-streaming Responses and Chat Completions decoding is unchanged.
- stream raw chunk forwarding and route-specific stream state behavior are
  unchanged.
- transport errors on the streaming path are still mapped to `ErrorEvent`.

## Benefits

Locality improves because request encoding, transport projection, response
decoding, and stream decoding now change in separate modules.

Leverage improves because `OpenAILanguageModel` remains a small provider model
entrypoint over deeper route-aware adapters. Future OpenAI-family provider
work can target the specific module that owns the reason to change, and the
same pattern can be used when deepening Anthropic and Google provider adapters.
