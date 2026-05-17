# OpenAI Embedding Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` OpenAI embedding provider
adapter, especially:

- `repo-ref/ai/packages/openai/src/embedding/openai-embedding-model.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps `OpenAIEmbeddingModel` as the provider adapter entrypoint
while separating provider option parsing, embedding request dispatch, successful
JSON response handling, and response usage projection. The Dart implementation
keeps the provider-facing model adapter stable and moves the embedding-specific
orchestration behind focused internal modules.

## Problem

`packages/llm_dart_openai/lib/src/openai_embedding_model.dart` mixed several
independent reasons to change:

- OpenAI-family embedding settings resolution
- OpenAI embedding provider option resolution
- max embeddings per call validation
- embeddings request body construction
- embeddings route URI and header construction
- timeout, retry, and cancellation projection
- JSON response coercion
- indexed embedding response sorting and numeric validation
- usage metadata and response metadata construction

The public model adapter seam was useful, but the implementation was shallow:
request body changes, transport projection changes, and response decoding
changes all required editing the model entrypoint.

## Decision

Keep `OpenAIEmbeddingModel` as the public provider adapter and split internal
orchestration:

- `openai_embedding_model_request.dart`
  - settings resolution
  - provider option resolution
  - max embeddings per call validation
  - request body construction
- `openai_embedding_model_transport.dart`
  - embeddings route URI resolution
  - default and per-call header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `openai_embedding_model_response.dart`
  - JSON object coercion
  - indexed embedding response decoding and sorting
  - numeric embedding value validation
  - usage and response metadata construction
- `openai_embedding_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - embedding call orchestration

This mirrors the language-model adapter split and the Google embedding split
without changing the OpenAI-family embedding contract.

## Behavior Contract

The refactor preserves these contracts:

- `OpenAIEmbeddingModel` constructor, fields, `providerId`,
  `capabilityProfile`, `maxEmbeddingsPerCall`, `embeddingsUri`,
  `defaultHeaders`, and `doEmbed` remain available.
- settings resolution still rejects mismatched model settings.
- provider option resolution still rejects mismatched provider options before
  max embeddings per call validation.
- max embeddings per call remains 2048.
- embeddings request URI, headers, timeout, max retries, cancellation, response
  type, and body behavior are unchanged.
- `encoding_format` still defaults to `float`.
- embedding response `data` entries are still sorted by provider index.
- usage metadata and response metadata construction are unchanged.

## Benefits

Locality improves because request validation/body construction, transport
projection, and response decoding now change in separate modules.

Leverage improves because `OpenAIEmbeddingModel` remains a small provider model
entrypoint over deeper OpenAI-family embedding adapters. This also gives
OpenAI and Google embedding providers the same orchestration pattern while
preserving OpenAI-family profile headers and provider-native options.
