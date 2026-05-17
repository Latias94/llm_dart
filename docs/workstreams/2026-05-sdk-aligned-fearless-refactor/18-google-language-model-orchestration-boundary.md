# Google Language Model Orchestration Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` Google provider layers,
especially:

- `repo-ref/ai/packages/google/src/google-language-model.ts`
- `repo-ref/ai/packages/google/src/convert-to-google-messages.ts`
- `repo-ref/ai/packages/google/src/google-prepare-tools.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps the language model as the provider adapter entrypoint while
separating request argument preparation, HTTP dispatch, JSON response handling,
and stream transform logic. The Dart implementation keeps
`GoogleLanguageModel` as the provider-facing adapter and moves its
orchestration details behind focused internal modules.

## Problem

`packages/llm_dart_google/lib/src/google_language_model.dart` mixed several
independent reasons to change:

- Google provider option resolution
- GenerateContent request encoding
- generate and stream URI selection
- request headers, timeout, retry, and cancellation projection
- non-streaming response JSON coercion and result decoding
- SSE JSON chunk parsing
- raw chunk event forwarding
- stream state ownership and final finish event emission
- transport error mapping

The public model adapter seam was useful, but the implementation was shallow:
transport projection, stream decoding, and request preparation changes all
required editing the model entrypoint.

## Decision

Keep `GoogleLanguageModel` as the public provider adapter and split internal
orchestration:

- `google_language_model_request.dart`
  - provider option resolution
  - GenerateContent request encoding
- `google_language_model_transport.dart`
  - generate/stream route URI resolution
  - `TransportRequest` construction
  - headers, timeout, retry, cancellation, and response type projection
- `google_language_model_response.dart`
  - non-streaming response JSON coercion and result decoding
- `google_language_model_stream.dart`
  - SSE JSON chunk parsing
  - raw chunk forwarding
  - stream state creation, chunk decoding, and finish event emission
- `google_language_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - generate/stream orchestration

This mirrors the OpenAI provider adapter shape without changing Google wire
codecs.

## Behavior Contract

The refactor preserves these contracts:

- `GoogleLanguageModel` constructor, fields, `providerId`,
  `capabilityProfile`, `generateContentUri`, and `streamGenerateContentUri`
  remain available.
- provider option resolution still rejects mismatched provider options and
  shared/provider response format conflicts.
- request warnings are still emitted before streaming transport starts.
- generate and stream request URIs, headers, timeout, max retries,
  cancellation, response type, and body behavior are unchanged.
- non-streaming GenerateContent response decoding is unchanged.
- stream raw chunk forwarding, stream state, chunk decoding, finish event
  emission, and transport error mapping are unchanged.

## Benefits

Locality improves because request preparation, transport projection, response
decoding, and stream decoding now change in separate modules.

Leverage improves because `GoogleLanguageModel` remains a small provider model
entrypoint over deeper Google-specific adapters. This gives OpenAI and Google a
shared provider adapter pattern that can be applied to Anthropic next.
