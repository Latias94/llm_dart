# 111. Shared Non-Text Result Enrichment

## What Changed

The shared non-text result layer in `llm_dart_core` is now richer than the
earlier minimal payload-only shape.

The following shared additions have landed:

- `ModelResponseMetadata`
- `SpeechGenerationResult.warnings`
- `SpeechGenerationResult.responseMetadata`
- `TranscriptionSegment`
- `TranscriptionResult.segments`
- `TranscriptionResult.language`
- `TranscriptionResult.durationSeconds`
- `TranscriptionResult.warnings`
- `TranscriptionResult.responseMetadata`

The package-owned modern ElevenLabs models now populate those new shared
fields:

- `packages/llm_dart_community/lib/src/elevenlabs_speech_model.dart`
- `packages/llm_dart_community/lib/src/elevenlabs_transcription_model.dart`

## Why This Matters

This is the first implementation step after:

- `109-community-provider-event-and-nontext-result-gap.md`
- `110-shared-nontext-result-surface.md`

Those notes concluded that the next structural gap versus `repo-ref/ai` was no
longer shared text events.

It was the shared non-text result surface.

That conclusion is now reflected in code:

- common non-text result data no longer has to hide only inside provider
  metadata
- Flutter or other app layers can read transcript timing and language directly
- diagnostics now have a shared response-metadata slot for speech and
  transcription calls

## What Stayed The Same

This enrichment is intentionally narrow.

It does not:

- add a new audio stream-event family
- add shared realtime-session abstractions
- add shared voice-catalog or admin APIs
- move provider-specific audio payloads out of provider metadata
- add raw request or raw response body wrappers to the shared core

Provider-specific extras still remain provider-owned, including the current
ElevenLabs metadata such as:

- `requestId`
- `historyItemId`
- `characterCost`
- raw `words`
- `additionalFormats`

## Why The Boundary Is Better

The landed split is now more honest:

- shared fields cover cross-provider concepts
- provider metadata carries provider-specific leftovers

That is closer to the reference repository's ownership discipline without
copying its full telemetry-heavy response-wrapper strategy.

## Validation

This slice was validated with:

- `dart analyze .`
- `dart test packages/llm_dart_core/test/capability_helpers_test.dart packages/llm_dart_community/test/elevenlabs_speech_model_test.dart packages/llm_dart_community/test/elevenlabs_transcription_model_test.dart`

## Remaining Work

This does not finish all non-text alignment work.

The next likely follow-ups are:

- decide whether additional provider families should populate the same shared
  response metadata immediately
- decide whether shared non-text no-result error wrappers are worth adding
- decide whether any provider-specific raw payloads deserve provider-owned typed
  helpers instead of long-term metadata-map access
