# Audio Models Decomposition

## Goal

This note records the decomposition of the large shared `audio_models.dart`
file without changing the public audio-model API.

The goal was narrow:

- keep existing shared audio model names stable
- separate TTS, STT, stream events, and value objects by responsibility
- make the audio model layer easier to extend for Flutter and provider-owned
  audio integrations without continuing a single-file growth pattern

## 1. Why `audio_models.dart` Was The Next Good Target

After the compatibility cleanup slices, the next largest shared-model hotspot
was `audio_models.dart`.

That file mixed:

- shared audio enums and format helpers
- TTS request/response models
- STT request/response models
- translation request models
- stream event models
- metadata value objects such as alignment, voices, languages, and segments

Those concepts belong to the same domain, but not to one source block.

## 2. Frozen Decomposition Rule

This slice keeps the public shared audio API stable:

- no rename of existing audio model types
- no JSON payload changes
- no constructor or factory signature changes
- no provider-specific behavior moved into the shared model layer

The change is purely an internal source decomposition.

## 3. Landed Split

The main `audio_models.dart` file is now reduced to the library shell plus
same-library parts:

- `audio_models_primitives.dart`
- `audio_models_tts.dart`
- `audio_models_stt.dart`
- `audio_models_metadata.dart`
- `audio_models_events.dart`

This maps better to how the shared audio surface is actually used:

- primitive enums stay separate from request/response payloads
- TTS and STT flows stop competing in the same source block
- metadata value objects stay reusable across both directions
- stream events stay isolated from request serialization models

## 4. Why This Matters Architecturally

This split is aligned with the broader refactor direction:

- shared cross-provider model surfaces stay shared
- provider-owned audio behavior still lives in provider packages
- Flutter-facing integration can depend on clearer shared request, response, and
  event boundaries without importing provider-specific code

That is closer to the reference layering discipline without copying its package
granularity.

## 5. Validation

This slice was validated with:

- `dart analyze lib/models lib/core/capability_audio.dart test/models/audio_models_test.dart test/providers/google/google_tts_test.dart`
- `dart test test/models/audio_models_test.dart test/providers/google/google_tts_test.dart`

## 6. Next Step

After `audio_models.dart`, the remaining large shared-model hotspots are mostly
`assistant_models.dart`, `image_models.dart`, `tool_models.dart`, and
`file_models.dart`, which can be decomposed with the same low-risk
same-library-part strategy if needed.
