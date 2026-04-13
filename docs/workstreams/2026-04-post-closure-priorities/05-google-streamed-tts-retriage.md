# Google Streamed TTS Re-Triage

## Purpose

This note re-triages the remaining Google streamed TTS question after the
post-closure UI/runtime boundary work is now frozen.

The question is no longer:

- should this block the shared architecture refactor

The narrower question is:

- does Google streamed TTS now justify a concrete provider-owned modern backlog
- or should it remain compatibility-only for longer

## What Was Reviewed

### Existing Deferred Decision

- `docs/workstreams/2026-03-architecture-refactor/178-google-streamed-tts-boundary.md`

### Current Stable Google Speech Surface

- `packages/llm_dart_google/lib/src/google_speech_model.dart`
- `example/04_providers/google/README.md`

### Current Compatibility Surface

- `example/04_providers/google/google_tts_example.dart`
- legacy builder-driven `GoogleTTSCapability` and `GoogleTTS*Event` flow

### Reference Signal From `repo-ref/ai`

The reference repository still mainly reinforces:

- a generic speech-model capability
- a one-shot `generateSpeech(...)` shape

It does **not** provide a Google-specific streamed TTS public contract that we
should mirror mechanically.

## Current Reality

### What Stable Google Already Covers

`llm_dart_google` already owns a useful stable baseline:

- `Google.speechModel(...)`
- `GoogleSpeechModel`
- `GoogleSpeechOptions`
- one-shot `generateSpeech(...)`
- single-speaker and multi-speaker request shaping

That already covers the most common application need:

- send text
- receive a complete generated audio payload

### What The Compatibility Example Actually Bundles Together

The old Google TTS compatibility example is not one single concern.

It currently mixes at least four different concerns:

1. streamed audio chunk delivery
2. raw PCM-to-WAV convenience
3. voice and language discovery helpers
4. broader legacy builder/configuration flow

That means “migrate streamed TTS” is too coarse as a backlog item. The real
candidate backlog is more granular.

### What The Runtime Refactor Proved

The recently closed UI/runtime work also makes one thing clearer:

- Google streamed TTS is **not** a missing chat-runtime feature
- it is **not** a reason to widen shared stream or UI abstractions
- it is a separate provider-owned speech utility question

So even if we reopen it, the right home remains provider-owned and outside the
shared chat/runtime layer.

## Re-Triage Decision

Google streamed TTS should remain **deferred as active implementation work**,
but it should now be classified more precisely as a **future provider-owned
utility backlog**, not a vague leftover gap.

That means:

- do **not** widen shared `SpeechModel` for streaming audio output
- do **not** migrate the old `GoogleTTSStreamEvent` family into the modern
  package as-is
- do **not** treat the old builder-era TTS example as architecture debt
- do keep the area visible as a provider-owned future utility candidate

## More Precise Future Candidate Split

If this area is revisited later, it should be split into separate decisions.

### Candidate A - Chunked Speech Output Helper

Possible future shape:

- provider-owned helper in `llm_dart_google`
- independent from shared `SpeechModel`
- returns typed provider-owned chunk values rather than old compatibility event
  classes

Potential scope:

- audio bytes or PCM chunks
- provider metadata needed during generation
- final completion signal

This is the only part that is truly “streamed TTS”.

### Candidate B - PCM / WAV Convenience Utilities

Possible future shape:

- small provider-owned or transport-neutral audio utility
- no coupling to the model invocation contract itself

Potential scope:

- PCM metadata constants
- WAV-header helper
- byte-format conversion helpers

This should stay separate from any future streaming model helper.

### Candidate C - Voice And Language Discovery

Possible future shape:

- provider-owned discovery helper or small API client
- separate from speech generation itself

Potential scope:

- available voice listing
- supported language listing
- static/typed metadata helpers if the provider contract is stable enough

This should not be bundled into a streamed-output decision by default.

## Why This Is The Right Boundary

### 1. It Aligns With The Reference Without Copying It

The reference repository validates the shared one-shot speech baseline.
It does not force a provider-specific streaming abstraction into the shared
surface.

### 2. It Avoids Freezing Compatibility-Shaped Events

The old `GoogleTTS*Event` family is too tied to the legacy shell.
Re-approving it unchanged would freeze an API that was never redesigned for the
new provider-owned workspace structure.

### 3. It Matches Real Ownership Better

The likely future features here are all provider-owned extras:

- chunked output
- voice discovery
- PCM/WAV convenience

None of them require shared `SpeechModel` widening.

### 4. It Keeps Flutter Concerns In The Right Layer

If a Flutter app later wants streamed TTS playback, that is still composition on
top of provider-owned speech helpers plus app playback code.

It is not a reason to push Google-specific audio-stream contracts into
`llm_dart_chat` or `llm_dart_flutter`.

## What Remains True Right Now

The public guidance should still say:

- stable Google speech today means one-shot `speechModel(...)`
- Google native streamed TTS remains compatibility-oriented
- any future modern streamed helper would be provider-owned and additive

## Bottom Line

Google streamed TTS is still not active migration debt.

The new post-closure refinement is:

- stop treating it as one fuzzy unresolved gap
- treat it as a future provider-owned utility cluster
- keep the current stable baseline on one-shot speech generation
- only reopen implementation when a concrete product need justifies one of the
  narrower candidates above
