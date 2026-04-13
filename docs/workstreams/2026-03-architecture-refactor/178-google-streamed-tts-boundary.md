# 178 Google Streamed TTS Boundary

## Why This Decision Exists

Google still has one visible residual audio gap:

- the legacy compatibility layer exposes `generateSpeechStream(...)` and
  `GoogleTTSStreamEvent`
- the modern package currently exposes only `GoogleSpeechModel` through the
  shared `SpeechModel`

This creates an obvious question:

- should streamed TTS now become a provider-owned modern surface in
  `llm_dart_google`
- or should it remain deferred instead of reviving the old compatibility event
  contract

## What Was Reviewed

Legacy compatibility-owned streamed TTS:

- `lib/src/compatibility/providers/google/tts.dart`
- `lib/models/google_tts_models.dart`

Modern package-owned speech surface:

- `packages/llm_dart_google/lib/src/google_speech_model.dart`
- `packages/llm_dart_google/lib/src/google_options.dart`

Existing workstream notes:

- `docs/workstreams/2026-03-architecture-refactor/55-shared-capability-helper-parity.md`
- `docs/workstreams/2026-03-architecture-refactor/57-google-compatibility-modality-status.md`
- `docs/workstreams/2026-03-architecture-refactor/124-google-residual-api-classification.md`

Reference signal from `repo-ref/ai`:

- the reference repository clearly has shared speech-model support
- it does not provide a Google-specific streamed TTS event family that should be
  copied mechanically here

## Current Reality

### What The Modern Package Already Covers

`llm_dart_google` already supports the high-value modern Google speech path:

- one request in
- one generated audio payload out
- typed provider-owned request options for single-speaker and multi-speaker
  shaping

That is the current product path most applications actually need.

### What The Legacy Streamed TTS Surface Really Is

The old streamed TTS compatibility API is very narrow:

- `GoogleTTSAudioDataEvent`
- `GoogleTTSMetadataEvent`
- `GoogleTTSErrorEvent`
- `GoogleTTSCompletionEvent`

That surface is tightly coupled to:

- the old compatibility provider shell
- old event-model naming
- one provider-specific chunk interpretation path

It is not a proven shared abstraction, and it is not an obviously stable
provider-owned modern API either.

## Frozen Decision

Google streamed TTS should remain **deferred for now**.

That means:

- do **not** widen the shared `SpeechModel` for streaming audio output
- do **not** migrate the old `GoogleTTSStreamEvent` contract into
  `llm_dart_google` as-is
- keep the existing modern Google speech path non-streaming
- keep the old streamed TTS API as compatibility-only residual surface

## Why This Is Better

### 1. The reference does not force this move

The reference validates the existence of a speech model surface, not the need to
copy a Google-specific streamed TTS event contract.

### 2. The old stream API is too compatibility-shaped

The current legacy event family is a thin transport-era shape, not a carefully
designed long-term provider utility.

Moving it directly into the modern package would freeze an API that was never
really re-designed for the new architecture.

### 3. Flutter and chat integration are not blocked on it

The current refactor priority is the text generation and chat stack, plus
provider-owned non-text helpers where the product contract is already clear.

Google streamed TTS is not currently required to complete:

- the shared chat runtime
- the modern Google speech model
- the provider/package boundary cleanup

### 4. If it lands later, it should be a separate provider-owned utility

If real demand appears later, the right design direction is:

- a provider-owned modern helper outside the shared `SpeechModel`
- a new API shaped around stable audio-chunk semantics
- no automatic reuse of the old `GoogleTTSStreamEvent` classes unless that
  legacy contract is intentionally re-approved

## Allowed Current Surface

The following remains the modern Google speech baseline:

- `Google.speechModel(...)`
- `GoogleSpeechModel`
- `GoogleSpeechOptions`
- `generateSpeech(...)`

The old compatibility stream API may continue to exist for migration support,
but it is not the model for the modern package.

## If We Revisit This Later

Any future Google streamed TTS helper should satisfy these conditions:

- clear product demand beyond the current non-streaming speech path
- provider-owned utility surface outside shared `SpeechModel`
- typed chunk/result semantics designed for the modern package, not copied from
  compatibility leftovers
- explicit decision on whether partial audio, metadata, and completion should
  integrate with Flutter/UI helpers or stay independent

## Non-Goals

This decision does not:

- remove the legacy streamed TTS compatibility API yet
- change the current non-streaming `GoogleSpeechModel`
- add streaming speech primitives to shared core
- rule out a future provider-owned streamed speech helper forever

## Conclusion

Google streamed TTS is a **deferred provider-owned candidate**, not current
migration debt that must be closed now.

The modern package keeps the already-valuable non-streaming speech model, while
the legacy streamed TTS contract stays compatibility-only until a real modern
utility shape is justified.
