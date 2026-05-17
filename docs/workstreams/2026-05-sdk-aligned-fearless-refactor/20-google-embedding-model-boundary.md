# Google Embedding Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` Google embedding provider
adapter, especially:

- `repo-ref/ai/packages/google/src/google-embedding-model.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps `GoogleEmbeddingModel` as the provider adapter entrypoint
while separating provider option parsing, single versus batch endpoint
selection, HTTP dispatch, and successful JSON response handling. The Dart
implementation keeps the provider-facing model adapter stable and moves the
embedding-specific orchestration behind focused internal modules.

## Problem

`packages/llm_dart_google/lib/src/google_embedding_model.dart` mixed several
independent reasons to change:

- Google embedding settings resolution
- Google embedding provider option resolution
- single `embedContent` request body construction
- batch `batchEmbedContents` request body construction
- route URI and header construction
- timeout, retry, and cancellation projection
- JSON response coercion
- single and batch embedding value validation
- usage metadata and response metadata construction

The public model adapter seam was useful, but the implementation was shallow:
request shape changes, transport projection changes, and response decoding
changes all required editing the model entrypoint.

## Decision

Keep `GoogleEmbeddingModel` as the public provider adapter and split internal
orchestration:

- `google_embedding_model_request.dart`
  - settings resolution
  - provider option resolution
  - single and batch request body construction
- `google_embedding_model_transport.dart`
  - `embedContent` and `batchEmbedContents` route URI resolution
  - request header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `google_embedding_model_response.dart`
  - JSON object coercion
  - single embedding response decoding
  - batch embedding response decoding
  - usage and response metadata construction
- `google_embedding_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - single versus batch call orchestration

This mirrors the language-model adapter splits while keeping the current Dart
embedding contract and wire shape unchanged.

## Behavior Contract

The refactor preserves these contracts:

- `GoogleEmbeddingModel` constructor, fields, `providerId`,
  `capabilityProfile`, `embedContentUri`, `batchEmbedContentsUri`, and
  `doEmbed` remain available.
- provider option resolution still rejects mismatched provider options.
- a single value still uses `embedContent`; any other value count still uses
  `batchEmbedContents`.
- request URI, headers, timeout, max retries, cancellation, response type, and
  body behavior are unchanged.
- single embedding response decoding is unchanged.
- batch embedding response decoding keeps the existing
  `embeddings[].embedding.values` shape.
- usage metadata and response metadata construction are unchanged.

## Benefits

Locality improves because request body construction, transport projection, and
response decoding now change in separate modules.

Leverage improves because `GoogleEmbeddingModel` remains a small provider model
entrypoint over deeper Google-specific adapters. This gives text and embedding
providers the same adapter orchestration pattern without flattening
provider-native embedding options into the shared contract.
