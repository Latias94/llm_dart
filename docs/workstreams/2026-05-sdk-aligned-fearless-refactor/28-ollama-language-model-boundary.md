# Ollama Language Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` provider adapter shape,
especially:

- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`
- language-model adapters that keep request preparation, transport dispatch,
  response decoding, and stream decoding in separate implementation modules

The Dart package already had focused Ollama chat request, response, and stream
codecs. This refactor moves the remaining model-owned orchestration for HTTP
dispatch and stream lifecycle out of the public adapter entrypoint.

## Problem

`packages/llm_dart_ollama/lib/src/ollama_language_model.dart` was thinner than
the original provider adapters, but still mixed several reasons to change:

- chat model settings resolution
- chat request codec construction
- chat response codec construction
- chat stream codec construction
- `/api/chat` URI and default header construction
- per-call header, timeout, retry, cancellation, and response type projection
- non-streaming JSON response coercion
- streaming start-event emission
- NDJSON stream decoding dispatch
- transport error projection into model stream errors

The public model adapter seam was useful, but still shallow compared with the
embedding adapter and the already-split OpenAI, Anthropic, Google, and
ElevenLabs adapters.

## Decision

Keep `OllamaLanguageModel` as the public provider adapter and split internal
orchestration:

- `ollama_language_model_request.dart`
  - settings resolution
  - request codec construction
  - generate/stream request preparation
- `ollama_language_model_transport.dart`
  - `/api/chat` URI resolution
  - default header construction
  - per-call header merging
  - generate `TransportRequest` construction
  - stream `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `ollama_language_model_response.dart`
  - response codec construction
  - non-streaming JSON response coercion and decoding
- `ollama_language_model_stream.dart`
  - stream codec construction
  - start-event emission
  - byte stream decoding dispatch
  - transport error projection
- `ollama_language_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - generate/stream orchestration

This completes the same adapter orchestration shape for Ollama language and
embedding models while preserving the existing lower-level chat codecs.

## Behavior Contract

The refactor preserves these contracts:

- `OllamaLanguageModel` constructor, fields, `providerId`,
  `capabilityProfile`, `chatUri`, `defaultHeaders`, `doGenerate`, and
  `doStream` remain available.
- model settings resolution still rejects mismatched model settings.
- request encoding remains owned by `OllamaChatRequestCodec`.
- response decoding remains owned by `OllamaChatResponseCodec`.
- stream chunk decoding remains owned by `OllamaChatStreamCodec`.
- `/api/chat` URI construction, default headers, per-call headers, timeout,
  max retries, cancellation, response type, and stream `accept` header are
  unchanged.
- generate response decoding still uses `responseName: 'chat response'` and
  preserves request warnings.
- stream generation still emits a `StartEvent` before transport dispatch.
- stream decoding still honors `includeRawChunks`.
- transport errors during streaming are still converted with
  `transportErrorToModelError`.

## Benefits

Locality improves because request preparation, transport projection,
non-streaming response decoding, and stream lifecycle handling now change in
separate modules.

Leverage improves because `OllamaLanguageModel` becomes a small provider model
entrypoint over deeper Ollama chat modules. The package keeps its provider-
native prompt projection, binary resolver, reasoning, and NDJSON stream support
without forcing those concerns into shared provider contracts.
