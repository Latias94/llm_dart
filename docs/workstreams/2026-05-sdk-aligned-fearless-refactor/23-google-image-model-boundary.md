# Google Image Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` Google image provider
adapter, especially:

- `repo-ref/ai/packages/google/src/google-image-model.ts`
- `repo-ref/ai/packages/google/src/google-image-model-options.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps `GoogleImageModel` as the provider adapter entrypoint while
separating Imagen versus Gemini routing, provider option parsing, request body
construction, HTTP dispatch, and successful JSON response handling. The Dart
implementation keeps the provider-facing image adapter stable and moves the
image-specific orchestration behind focused internal modules.

## Problem

`packages/llm_dart_google/lib/src/google_image_model.dart` mixed several
independent reasons to change:

- Google image settings resolution
- Google image provider option resolution
- Imagen versus Gemini image model detection
- generation and edit request validation
- Imagen `predict` request body construction
- Gemini `generateContent` request body construction
- image edit input encoding
- `predict` and `generateContent` route URI and header construction
- timeout, retry, and cancellation projection
- JSON response coercion
- Imagen and Gemini image response decoding
- usage, response metadata, and Google provider metadata construction

The public model adapter seam was useful, but the implementation was shallow:
request validation, wire body changes, transport projection, and response
decoding all required editing the model entrypoint.

## Decision

Keep `GoogleImageModel` as the public provider adapter and split internal
orchestration:

- `google_image_model_request.dart`
  - settings resolution
  - provider option resolution
  - Gemini image model detection
  - max images per call resolution
  - generation/edit request validation
  - Imagen generation request body construction
  - Gemini generation/edit request body construction
  - image edit input encoding
- `google_image_model_transport.dart`
  - `predict` and `generateContent` route URI resolution
  - request header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `google_image_model_response.dart`
  - JSON object coercion
  - Imagen response decoding
  - Gemini response decoding
  - usage, response metadata, and Google provider metadata construction
- `google_image_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - generation/edit/variation orchestration

This mirrors the embedding adapter splits while preserving the Dart-specific
provider-owned `edit` and `createVariation` helpers.

## Behavior Contract

The refactor preserves these contracts:

- `GoogleImageModel` constructor, fields, `providerId`, `capabilityProfile`,
  `isGeminiImageModel`, `maxImagesPerCall`, `predictUri`,
  `generateContentUri`, `doGenerate`, `edit`, and `createVariation` remain
  available.
- settings and provider option resolution still reject mismatched options.
- Gemini models still use `generateContent`; Imagen models still use `predict`.
- Gemini image generation still requires `count=1` by default.
- Imagen generation still defaults to four images per call unless overridden by
  settings.
- request `size`, Imagen safety settings, Gemini `personGeneration`, and edit
  input validation behavior are unchanged.
- request URI, headers, timeout, max retries, cancellation, response type, and
  body behavior are unchanged.
- Imagen response decoding is unchanged.
- Gemini response decoding, revised prompts, finish reasons, usage metadata,
  response metadata, and Google provider metadata are unchanged.

## Benefits

Locality improves because request validation/body construction, transport
projection, and response decoding now change in separate modules.

Leverage improves because `GoogleImageModel` remains a small provider model
entrypoint over deeper Google-specific adapters. The Google package now uses
the same adapter orchestration shape for language, embedding, and image models
while keeping Imagen/Gemini product differences explicit.
