# ElevenLabs (Audio) Guide

This guide documents how to use ElevenLabs via `llm_dart_elevenlabs`.

ElevenLabs is an **audio-focused** provider (TTS/STT/voices). The recommended
provider-agnostic surface is `llm_dart_ai` task APIs, while provider-specific
voice knobs are accessed via:

- `providerOptions['elevenlabs']`

In addition to the standard audio tasks, `llm_dart_elevenlabs` exposes
provider-specific APIs for:

- speech-to-speech (voice conversion)
- forced alignment (timing alignment)

## Packages

- Provider: `llm_dart_elevenlabs`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`

## Base URL

Default base URL:

- `https://api.elevenlabs.io/v1/`

Official docs:

- ElevenLabs docs: https://elevenlabs.io/docs
- API reference: https://elevenlabs.io/docs/api-reference

## Authentication

LLM Dart uses ElevenLabs API key header authentication:

- `xi-api-key: <ELEVENLABS_API_KEY>`

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_elevenlabs/elevenlabs.dart';

Future<void> main() async {
  registerElevenLabs();

  final model = await LLMBuilder()
      .provider(elevenLabsProviderId)
      .apiKey('ELEVENLABS_API_KEY')
      .build();

  final audio = await generateSpeech(
    model: model,
    text: 'Hello from ElevenLabs!',
  );

  print(audio.bytes.length);
}
```

## Provider options (voice settings)

ElevenLabs voice knobs are configured via `providerOptions['elevenlabs']`:

- `voiceId`: `String`
- `stability`: `double`
- `similarityBoost`: `double`
- `style`: `double`
- `useSpeakerBoost`: `bool`

These act as **defaults** and can be overridden per-request via the audio task
request fields (when provided).

Reference:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`

## Conformance tests

ElevenLabs provider tests:

- `test/providers/elevenlabs/elevenlabs_config_test.dart`
- `test/providers/elevenlabs/elevenlabs_factory_test.dart`
- `test/providers/elevenlabs/elevenlabs_provider_test.dart`

## Provider-specific APIs

### Speech-to-speech (voice conversion)

Official API:

- `POST /v1/speech-to-speech/{voice_id}`
- `POST /v1/speech-to-speech/{voice_id}/stream`

LLM Dart:

- `ElevenLabsProvider.convertSpeechToSpeech(...)`
- `ElevenLabsProvider.convertSpeechToSpeechStream(...)`

### Forced alignment

Official API:

- `POST /v1/forced-alignment`

LLM Dart:

- `ElevenLabsProvider.createForcedAlignment(...)`
