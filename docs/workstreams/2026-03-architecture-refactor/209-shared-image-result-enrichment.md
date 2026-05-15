# 209 Shared Image Result Enrichment

## Why This Slice Exists

The earlier non-text result enrichment covered speech and transcription, but
image generation still only returned generated images plus provider metadata.

That left a real gap versus the reference direction:

- image calls could not expose shared usage data
- image calls could not expose response metadata such as model ID and headers
- provider implementations had no shared warning slot for unsupported image
  request options
- OpenAI image metadata stayed flat, making multi-image token details hard to
  associate with individual images

## Decision

Extend the shared `ImageGenerationResult` with the same narrow diagnostic
fields that already proved useful for speech and transcription:

- `usage`
- `warnings`
- `responseMetadata`

Provider-specific details still stay in `providerMetadata`.

OpenAI also now mirrors the reference's more useful per-image metadata shape
under `providerMetadata.openai.images`, while keeping the previous flat OpenAI
metadata keys for compatibility:

- `revisedPrompt`
- `created`
- `size`
- `quality`
- `background`
- `outputFormat`
- distributed `imageTokens`
- distributed `textTokens`

Google image models now populate shared `responseMetadata`, and Gemini image
responses map `usageMetadata` into shared `UsageStats`.

## Why This Is Better

This makes image results match the same architectural split as the rest of the
modern non-text surface:

- shared fields carry cross-provider diagnostics
- provider metadata carries provider-owned extras
- multi-image OpenAI responses can attach provider details to the image index
  they describe

It avoids copying the reference repository's full response-wrapper machinery,
but adopts the part that improves real application ergonomics.

## Validation

This slice is validated with:

- `dart test test\provider_contracts_test.dart` in `packages/llm_dart_provider`
- `dart test test\openai_image_model_test.dart` in `packages/llm_dart_openai`
- `dart test test\google_image_model_test.dart` in `packages/llm_dart_google`

## Follow-Up

The next image-related parity question is whether any provider-owned image
warnings are worth exposing now. The shared slot exists, but the current Dart
shared image request shape does not yet include reference-only fields such as
`aspectRatio` or `seed`, so there is no honest shared warning to emit there
yet.
