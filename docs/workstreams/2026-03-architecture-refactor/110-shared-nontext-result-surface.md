# 110. Shared Non-Text Result Surface

## Goal

Define the next shared-core boundary for speech and transcription results after
the community-provider event-gap review in
`109-community-provider-event-and-nontext-result-gap.md`.

The question is:

> How should `llm_dart_core` expose richer non-text result data without copying
> the full internal response-wrapper strategy of `repo-ref/ai`?

## Decision

The next shared non-text result round should stay additive but explicit.

`SpeechGenerationResult` should grow shared result metadata for:

- warnings
- response metadata

`TranscriptionResult` should grow shared result data for:

- warnings
- response metadata
- segments
- language
- duration

Provider-specific extras should continue to stay in `providerMetadata`.

## Why

## 1. The Current Shared Surface Is Too Thin

The current shared types are truthful but overly minimal:

- `SpeechGenerationResult` only exposes audio bytes, media type, and provider
  metadata
- `TranscriptionResult` only exposes text and provider metadata

That forces several cross-provider concerns into provider-owned metadata bags:

- transcript segments
- language
- duration
- response-level diagnostics that are not actually provider-exclusive

That is acceptable as a temporary migration step, but not as the long-term
shared capability contract.

## 2. The Reference Direction Is Useful, But We Should Narrow It

`repo-ref/ai` is directionally right:

- non-text result objects should expose more than the primary payload
- warnings and response metadata are useful across providers
- transcript timing and language data belong on the typed result

But `llm_dart` should still stay narrower than the full reference wrapper.

For the next Dart boundary, we do **not** need to copy all of:

- raw request metadata
- raw response body pass-through on shared result types
- full telemetry-first wrapper layering

That would widen the shared core faster than the current Dart ecosystem has
proven necessary.

## Proposed Shared Types

## Response Metadata

Add a lightweight shared response metadata value object for non-text model
calls:

```text
ModelResponseMetadata {
  DateTime timestamp
  String modelId
  Map<String, String> headers
}
```

Why this shape:

- `timestamp` is useful for diagnostics and persistence
- `modelId` belongs to shared result reporting, not provider metadata
- `headers` are often the only portable place to preserve request IDs, quota
  information, or retry hints

Why not add `body` now:

- speech responses may be binary and large
- response bodies are often provider-specific and debugging-oriented
- shared result payloads should stay lightweight for Flutter and mobile usage

Provider-specific raw bodies can still stay provider-owned if a concrete need
appears later.

## Transcription Segment

Add a shared typed segment value object:

```text
TranscriptionSegment {
  String text
  double startSeconds
  double endSeconds
}
```

Why this should be shared:

- segment timing is not ElevenLabs-specific
- multiple transcription providers expose equivalent timing slices
- Flutter voice UX benefits from typed segments for karaoke-style playback,
  highlighting, scrubbing, and review UIs

## Result Shapes

Recommended next result shapes:

```text
SpeechGenerationResult {
  List<int> audioBytes
  String? mediaType
  List<ModelWarning> warnings
  ModelResponseMetadata? responseMetadata
  ProviderMetadata? providerMetadata
}
```

```text
TranscriptionResult {
  String text
  List<TranscriptionSegment> segments
  String? language
  double? durationSeconds
  List<ModelWarning> warnings
  ModelResponseMetadata? responseMetadata
  ProviderMetadata? providerMetadata
}
```

## Boundary Rules

The following data should become shared:

- transcript segments
- transcript language
- transcript duration
- warnings about unsupported shared parameters
- response timestamp/model ID/headers

The following data should remain provider-owned:

- ElevenLabs `historyItemId`
- ElevenLabs `characterCost`
- ElevenLabs word-level raw structures
- ElevenLabs additional format payloads
- voice-catalog, realtime, cloning, and admin result shapes

## Why This Is Better For Flutter

Flutter chat-and-voice applications care about:

- audio bytes
- MIME type
- typed transcript segments
- language and duration
- stable response identifiers for logging and debugging

They usually do **not** need:

- raw provider HTTP bodies in shared state
- provider-specific admin payloads in shared result classes

So this shared result layer is a better fit for mobile and UI integrations than
either extreme:

- thinner-than-useful provider metadata tunneling
- or a fully telemetry-heavy shared response wrapper

## Compatibility And Migration

This can be an additive breaking-round change with a narrow migration path:

- keep `providerMetadata` unchanged
- add new shared fields with empty/default values
- migrate modern provider packages first
- keep root compatibility shells mapping their richer legacy data into the new
  shared fields where possible

That migration order is especially suitable for ElevenLabs:

- the modern package already has language and timing payloads available
- the current root shell still owns broader audio/admin residual APIs
- shared result enrichment improves the modern package without forcing more
  provider-specific APIs into the core

## What This Does Not Mean

This proposal does **not** imply:

- a new audio stream event family
- a shared realtime audio session abstraction beyond the current surface
- a shared voice catalog API
- a shared admin/account API
- a requirement to move provider-specific response bodies into the shared core

## Recommended Implementation Order

1. add shared `ModelResponseMetadata`
2. add shared `TranscriptionSegment`
3. extend `SpeechGenerationResult`
4. extend `TranscriptionResult`
5. migrate ElevenLabs modern models first
6. re-audit whether any other provider family can adopt the same richer result
   contract immediately

## Follow-Up

After this lands, the next question can be much narrower:

> Do we also need typed shared non-text error wrappers similar in spirit to the
> reference repository's speech/transcription no-result errors, or is the
> enriched result metadata enough for now?
