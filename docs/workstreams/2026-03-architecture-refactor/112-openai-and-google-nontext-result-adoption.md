# 112. OpenAI And Google Non-Text Result Adoption

## What Changed

The shared non-text result enrichment introduced in
`111-shared-nontext-result-enrichment.md` is no longer only used by the modern
ElevenLabs package.

It is now also adopted by:

- `packages/llm_dart_openai/lib/src/openai_speech_model.dart`
- `packages/llm_dart_openai/lib/src/openai_transcription_model.dart`
- `packages/llm_dart_google/lib/src/google_speech_model.dart`

These provider-owned modern models now populate shared result fields such as:

- `responseMetadata`
- `warnings`
- `segments`
- `language`
- `durationSeconds`

where their APIs actually support those fields.

## Why This Matters

This is the first proof that the richer shared non-text result layer is not an
ElevenLabs-only abstraction.

That matters architecturally because it shows:

- the new shared result contract is already useful across multiple provider
  families
- the boundary is broad enough to be shared
- the boundary is still narrow enough that provider-specific payloads can stay
  provider-owned

In other words, this is the point where the design stops being speculative and
starts being a real shared-core contract.

## Provider Status

## OpenAI

OpenAI modern non-text model coverage now includes:

- speech with shared `responseMetadata`
- transcription with shared `responseMetadata`
- transcription with shared `language`
- transcription with shared `durationSeconds`
- transcription with shared typed `segments`

OpenAI still keeps provider-specific transcription extras such as raw `words`
and raw `segments` payloads in provider metadata for compatibility and richer
provider-owned access.

## Google

Google modern non-text model coverage now includes:

- speech with shared `responseMetadata`

Google does not yet have a package-owned modern transcription model in this
workspace, so there was no Google transcription surface to migrate in this
round.

That absence is important to state explicitly:

- this round did not skip a migrated Google transcription model by accident
- the next Google question was whether such a model should exist at all
- that boundary is now frozen separately in
  `113-google-transcription-boundary.md`

## What Did Not Change

This adoption round does not:

- add a Google transcription model
- add new audio stream-event families
- move provider-specific raw speech/transcription payloads into the shared core
- change the provider-owned status of voice catalogs, realtime APIs, or admin
  helpers

## Validation

This slice was validated with:

- `dart analyze .`
- `dart test packages/llm_dart_openai/test/openai_speech_model_test.dart packages/llm_dart_openai/test/openai_transcription_model_test.dart packages/llm_dart_google/test/google_speech_model_test.dart`

## Remaining Work

The next remaining questions are now narrower:

- whether any additional provider families should populate the same shared
  response metadata immediately
- whether shared non-text no-result error wrappers are worth adding beyond the
  enriched result metadata already available
- whether Google should later gain a provider-owned audio-understanding helper
  above multimodal prompting instead of a shared transcription abstraction
