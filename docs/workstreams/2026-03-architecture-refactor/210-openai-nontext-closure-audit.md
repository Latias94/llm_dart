# 210 OpenAI Non-Text Closure Audit

## Purpose

This note closes the current OpenAI non-text parity round against `repo-ref/ai`.

The scope is the modern `llm_dart_openai` package-owned non-text surface:

- embeddings
- image generation and editing
- speech generation
- transcription

The goal is not to copy the reference repository's internal module graph. The
goal is to confirm that the Dart provider surface now follows the same useful
contract boundaries while preserving the Dart library's unified helper layer
and typed provider options.

## What Was Closed

### Embeddings

OpenAI embeddings now align with the reference on the important request
semantics:

- request bodies default to `encoding_format: "float"`
- `OpenAIEmbedOptions.user` is supported as provider-owned abuse-monitoring
  metadata
- each call is capped at 2048 input values
- shared `EmbedRequest.dimensions` remains the Dart-owned unified interface for
  output dimensions
- the existing `OpenAIEmbedOptions.encodingFormat` remains as a Dart provider
  escape hatch rather than being removed

The shared `EmbedResult` now also carries:

- `warnings`
- `responseMetadata`

OpenAI, Google, and Ollama embedding models populate the shared response
metadata where their response headers are available.

### Images

OpenAI image generation and editing now cover the useful reference-aligned
surface:

- `gpt-image-2` and other default-response-format image models omit
  `response_format`
- `maxImagesPerCall` is model-aware
- GPT image options cover `moderation`, `outputFormat`, and
  `outputCompression`
- image output compression is validated
- shared `ImageGenerationResult` carries `usage`, `warnings`, and
  `responseMetadata`
- OpenAI provider metadata includes per-image entries under
  `providerMetadata.openai.images`
- OpenAI image token details are distributed across per-image metadata entries
  in the same spirit as the reference implementation

The older flat OpenAI image metadata keys remain for migration compatibility.

### Speech

OpenAI speech generation now follows the reference behavior that matters at the
provider boundary:

- defaults `voice` to `alloy`
- defaults `response_format` to `mp3`
- validates speed in the OpenAI-supported `0.25..4.0` range
- warning-fallbacks unsupported output formats to `mp3`
- warning-drops unsupported `language`
- keeps provider-owned `instructions` and `speed` in `OpenAISpeechOptions`

### Transcription

OpenAI transcription now aligns with the reference behavior while preserving
Dart's explicit typed options:

- `OpenAITranscriptionOptions.include` maps to multipart `include[]`
- timestamp requests default to `verbose_json` for Whisper-style models
- timestamp requests default to `json` for `gpt-4o-transcribe` and
  `gpt-4o-mini-transcribe`
- transcription temperature is validated in `0..1`
- responses decode `segments` first and fall back to `words`
- OpenAI language names such as `english` normalize to shared ISO language
  codes such as `en`

## What Intentionally Remains Different

### No Full Reference Response Wrapper

The reference returns richer raw request/response wrapper data in some model
families. The Dart shared result layer intentionally keeps only the common
diagnostic subset:

- usage
- warnings
- response metadata
- provider metadata

Raw response bodies remain provider-owned or test-only until a concrete app
need proves they belong in shared core.

### No Shared Image `aspectRatio` Or `seed`

The reference image model can warn on shared `aspectRatio` and `seed` request
fields because its shared TypeScript image request shape has those fields.

The Dart shared `ImageGenerationRequest` does not expose those fields. Google
aspect ratio stays provider-owned through `GoogleImageOptions`; OpenAI image
seed remains unsupported rather than becoming a shared request parameter.

### No Shared Embedding Chunking Policy

OpenAI now enforces its per-call limit locally, but shared `embedMany(...)`
still does not perform provider-independent chunk splitting.

That remains deliberate. Chunking needs a truthful multi-provider scheduling
contract before it belongs in shared core.

## Closure Verdict

OpenAI non-text is no longer an architecture blocker for the current refactor.

The modern provider-owned surface now has:

- typed provider options for OpenAI-specific knobs
- shared helper compatibility through `llm_dart_ai`
- model-aware request validation where OpenAI has known limits
- useful shared result diagnostics across embedding, image, speech, and
  transcription
- provider metadata for OpenAI-specific response details

Future work should reopen only for concrete product needs, not for broad
"finish OpenAI non-text" migration.

## Validation

This closure was validated with:

- `dart test test\openai_embedding_model_test.dart test\openai_image_model_test.dart test\openai_speech_model_test.dart test\openai_transcription_model_test.dart test\openai_model_describer_test.dart` in `packages/llm_dart_openai`
- `dart test test\provider_contracts_test.dart` in `packages/llm_dart_provider`
- `dart test test\capability_helpers_test.dart` in `packages/llm_dart_core`
- `dart test test\capability_helpers_test.dart` in `packages/llm_dart_ai`
- `dart test test\google_embedding_model_test.dart` in `packages/llm_dart_google`
- `dart test test\ollama_embedding_model_test.dart` in `packages/llm_dart_ollama`
