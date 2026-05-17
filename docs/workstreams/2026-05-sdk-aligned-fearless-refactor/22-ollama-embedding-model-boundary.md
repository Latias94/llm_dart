# Ollama Embedding Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the embedding adapter pattern established
from `repo-ref/ai`, especially:

- `repo-ref/ai/packages/google/src/google-embedding-model.ts`
- `repo-ref/ai/packages/openai/src/embedding/openai-embedding-model.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference repository does not provide a first-party Ollama provider in this
tree. The relevant lesson is still the same: keep the provider adapter as the
entrypoint while separating request validation, HTTP dispatch, successful JSON
response handling, and provider metadata projection.

## Problem

`packages/llm_dart_ollama/lib/src/ollama_embedding_model.dart` mixed several
independent reasons to change:

- Ollama embedding settings resolution
- empty input validation
- unsupported dimensions validation
- unsupported provider options validation
- embedding request body construction
- embedding route URI and header construction
- timeout, retry, and cancellation projection
- JSON response coercion
- embedding value validation
- response metadata and Ollama provider metadata construction

The public model adapter seam was useful, but the implementation was shallow:
request validation, transport projection, and response/provider metadata
changes all required editing the model entrypoint.

## Decision

Keep `OllamaEmbeddingModel` as the public provider adapter and split internal
orchestration:

- `ollama_embedding_model_request.dart`
  - settings resolution
  - empty input validation
  - unsupported dimensions validation
  - unsupported provider options validation
  - request body construction
- `ollama_embedding_model_transport.dart`
  - embedding route URI resolution
  - default and per-call header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `ollama_embedding_model_response.dart`
  - JSON object coercion
  - embedding response decoding
  - numeric embedding value validation
  - response metadata and provider metadata construction
- `ollama_embedding_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - embedding call orchestration

This finishes the same embedding adapter pattern now used by OpenAI, Google,
and Ollama.

## Behavior Contract

The refactor preserves these contracts:

- `OllamaEmbeddingModel` constructor, fields, `providerId`,
  `capabilityProfile`, `embedUri`, `defaultHeaders`, and `doEmbed` remain
  available.
- settings resolution still rejects mismatched model settings.
- empty embedding value lists still fail before dimensions and provider option
  checks.
- dimensions are still rejected.
- provider invocation options are still rejected because Ollama embeddings do
  not define provider call options yet.
- embedding request URI, headers, timeout, max retries, cancellation, response
  type, and body behavior are unchanged.
- embedding response decoding is unchanged.
- Ollama provider metadata still includes duration and prompt evaluation fields
  when present.

## Benefits

Locality improves because request validation/body construction, transport
projection, and response/provider metadata decoding now change in separate
modules.

Leverage improves because `OllamaEmbeddingModel` remains a small provider model
entrypoint over deeper Ollama-specific adapters. The three current embedding
providers now share the same orchestration shape without forcing Ollama to
invent provider options it does not yet support.
