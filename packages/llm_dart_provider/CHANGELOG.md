# Changelog

## Unreleased

- Added `ProviderModelFacetSupport` so provider facades can declare a narrower
  registry-visible model facet surface than their concrete class methods imply.
- Updated `ProviderRegistry` to respect provider-declared model facet support
  when listing providers and resolving dynamic model references.
- Added direct batching facts to `EmbeddingModel` and `ImageModel` contracts:
  `maxEmbeddingsPerCall`, `supportsParallelCalls`, and `maxImagesPerCall`.
- Expanded the shared image request contract with optional prompt support,
  aspect ratio, seed, file inputs, masks, and per-image provider metadata.
- Expanded `SpeechGenerationRequest` with shared `outputFormat`,
  `instructions`, `speed`, and `language` fields.
- Made provider-facing `TranscriptionRequest.mediaType` required so adapters no
  longer receive ambiguous audio bytes.

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the provider contract package.
- Provides shared contracts for prompts, content parts, tools, results,
  metadata, model capabilities, and stream events.
- Includes UI message/projection types and JSON codecs for prompt, stream, and
  chat UI transport.
- Most app code reaches these types through `llm_dart`; custom provider authors
  can depend on this package directly.
- Treats model interfaces as provider implementation contracts: text models
  implement `doGenerate(...)` and `doStream(...)`, embedding models implement
  `doEmbed(...)`, and image, speech, and transcription models implement
  `doGenerate(...)`.
- Defines the input/output boundary explicitly: provider-specific request
  controls belong in typed `ProviderInvocationOptions` or
  `ProviderPromptPartOptions`, while `ProviderMetadata` is reserved for output
  observations, replay data, and UI inspection.
