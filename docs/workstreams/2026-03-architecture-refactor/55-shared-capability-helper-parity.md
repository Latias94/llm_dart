# Shared Capability Helper Parity

## Goal

This note closes the next capability-surface gap versus `repo-ref/ai` after the
main text-call naming decision was frozen:

> How should `llm_dart` expose shared non-text capability helpers without
> copying the reference repository's full internal module complexity?

## Decision

The current breaking round should expose a function-based shared capability
surface in `llm_dart_core`:

- `embed(...)`
- `embedMany(...)`
- `generateImage(...)`
- `generateSpeech(...)`
- `transcribe(...)`

These functions are now the recommended app-facing helper layer above the raw
capability model interfaces:

- `EmbeddingModel.embed(...)`
- `ImageModel.generate(...)`
- `SpeechModel.generateSpeech(...)`
- `TranscriptionModel.transcribe(...)`

## Why

### 1. The Reference Is Right About The Product Surface

`repo-ref/ai` is correct about one important architectural point:

- applications want capability-specific functions
- provider protocols should sit below those helpers
- Flutter, server, and CLI code all benefit from that shape

That is the right direction for `llm_dart` as well.

### 2. We Should Not Copy The Entire Internal Strategy

The reference implementation also includes richer internal behavior such as:

- shared embedding chunk splitting
- shared parallel scheduling policy
- telemetry hooks
- more elaborate response wrappers

Those are useful reference signals, but they should not be copied blindly into
the current Dart core.

For this round, the shared helper layer should stay intentionally thin and
truthful.

### 3. Thin Shared Invariants Still Matter

Even a thin helper layer should still own a few common invariants:

- `embedMany(...)` should reject empty input lists
- `embed(...)` and `embedMany(...)` should reject mismatched embedding counts
- `generateImage(...)` should reject non-positive image counts
- `transcribe(...)` should reject empty audio bytes

That keeps the shared contract honest without pushing provider policy into
`llm_dart_core`.

## Embedding Policy

The current shared embedding policy is:

- `EmbeddingModel.embed(...)` remains the raw low-level model call
- `embed(...)` is the single-value convenience wrapper
- `embedMany(...)` is the batch convenience wrapper
- batching strategy still belongs to the model/provider for now

That means `llm_dart_core` does **not** currently freeze:

- shared chunk splitting by per-provider limits
- shared parallelism controls
- shared embedding lifecycle callbacks

If multiple provider families later prove the same chunking contract, that can
be added in a separate round.

## Provider-Specific Features

Provider-specific capability behavior should continue to stay provider-owned:

- provider-specific model settings belong to provider packages
- provider-specific per-call options belong in typed
  `ProviderInvocationOptions`
- shared helpers should pass those options through `CallOptions`

The first concrete migrated examples now include two provider families:

- `OpenAI.embeddingModel(...)`
- `OpenAIEmbeddingModelSettings`
- `OpenAIEmbedOptions`
- `OpenAI.imageModel(...)`
- `OpenAIImageModelSettings`
- `OpenAIImageOptions`
- `OpenAI.speechModel(...)`
- `OpenAISpeechOptions`
- `OpenAI.transcriptionModel(...)`
- `OpenAITranscriptionOptions`
- `Google.embeddingModel(...)`
- `GoogleEmbeddingModelSettings`
- `GoogleEmbedOptions`
- `Google.imageModel(...)`
- `GoogleImageModelSettings`
- `GoogleImageOptions`
- `Google.speechModel(...)`
- `GoogleSpeechModelSettings`
- `GoogleSpeechOptions`

This keeps provider features typed without widening the shared helper surface.
It also means the OpenAI-family non-text migration surface now covers
embedding, image, speech, and transcription, Google now also has package-owned
embedding, image, and speech model surfaces, and the shared embedding helper
boundary is now also proven against more than one provider family.

## What Is Still Not Done

This decision does **not** mean non-text capability parity is complete.

The remaining work is still real:

- non-text provider migration parity is still incomplete outside the OpenAI
  family
- Google streamed TTS and safety/modality migration parity is incomplete
- Anthropic capability migration parity is incomplete
- shared embedding chunk-splitting policy is intentionally still undecided

## Conclusion

The capability-surface direction is now clearer:

- keep function-based shared helper entrypoints in `llm_dart_core`
- keep raw capability model methods below them
- keep provider-specific options in provider packages
- do not copy the reference repository's richer helper internals until a
  truthful multi-provider contract is proven
