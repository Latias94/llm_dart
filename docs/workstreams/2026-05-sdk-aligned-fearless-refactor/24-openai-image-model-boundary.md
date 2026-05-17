# OpenAI Image Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` OpenAI image provider
adapter, especially:

- `repo-ref/ai/packages/openai/src/image/openai-image-model.ts`
- `repo-ref/ai/packages/openai/src/image/openai-image-model-options.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps `OpenAIImageModel` as the provider adapter entrypoint while
separating generation versus edit routing, provider option parsing, JSON and
multipart request body construction, HTTP dispatch, and successful JSON
response handling. The Dart implementation keeps the provider-facing image
adapter stable and moves image-specific orchestration behind focused internal
modules.

## Problem

`packages/llm_dart_openai/lib/src/openai_image_model.dart` mixed several
independent reasons to change:

- OpenAI-family image settings resolution
- OpenAI image provider option resolution
- max images per call and response-format policy
- generation request validation
- edit request and edit input validation
- generation JSON request body construction
- edit multipart request body construction
- image filename inference
- generation and edit route URI and header construction
- timeout, retry, and cancellation projection
- JSON response coercion
- generated/edited image response decoding
- usage, per-image token distribution, response metadata, and OpenAI provider
  metadata construction

The public model adapter seam was useful, but the implementation was shallow:
request validation, JSON body changes, multipart changes, transport projection,
and response decoding all required editing the model entrypoint.

## Decision

Keep `OpenAIImageModel` as the public provider adapter and split internal
orchestration:

- `openai_image_model_request.dart`
  - settings resolution
  - provider option resolution
  - max images per call and response-format policy
  - generation and edit request validation
  - edit input validation
  - generation JSON body construction
  - edit multipart body construction
  - image filename inference
- `openai_image_model_transport.dart`
  - generation and edit route URI resolution
  - default and per-call header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `openai_image_model_response.dart`
  - JSON object coercion
  - image response decoding
  - base64/url image projection
  - usage and per-image token metadata decoding
  - response metadata and OpenAI provider metadata construction
- `openai_image_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - generation/edit orchestration

This mirrors the Google image split while preserving the Dart-specific
provider-owned `edit` helper and current multipart encoding path.

## Behavior Contract

The refactor preserves these contracts:

- `OpenAIImageModel` constructor, fields, `providerId`, `capabilityProfile`,
  `maxImagesPerCall`, `imageGenerationUri`, `imageEditUri`, `defaultHeaders`,
  `doGenerate`, and `edit` remain available.
- settings and provider option resolution still reject mismatched options.
- model max image limits and response-format omission for `gpt-image-*` and
  `chatgpt-image-*` models are unchanged.
- generation JSON request URI, headers, timeout, max retries, cancellation,
  response type, and body behavior are unchanged.
- edit multipart request URI, headers, timeout, max retries, cancellation,
  response type, field order, filenames, and body behavior are unchanged.
- generation and edit validation behavior is unchanged, including
  output-compression range checks and generation-only option rejection during
  edits.
- base64 and URL response decoding is unchanged.
- usage metadata, per-image token distribution, response metadata, and OpenAI
  provider metadata are unchanged.

## Benefits

Locality improves because request validation/body construction, multipart
encoding, transport projection, and response decoding now change in separate
modules.

Leverage improves because `OpenAIImageModel` remains a small provider model
entrypoint over deeper OpenAI-family image adapters. OpenAI and Google image
providers now share the same adapter orchestration shape while preserving their
provider-native option surfaces.
