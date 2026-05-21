# ElevenLabs Provider Features

ElevenLabs now has modern shared-capability surfaces in this workspace through
`package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart`:

- `elevenLabs(...).speechModel(...)`
- `elevenLabs(...).transcriptionModel(...)`
- `elevenLabs(...).voices().listVoices()`

This directory now uses a stable-first posture for normal speech and
transcription flows, while still keeping the broader voice/audio appendix
explicitly provider owned.

## When To Use Which Path

### Prefer The Dedicated Package Surface

Use `llm_dart_elevenlabs` when you need dedicated shared-capability speech
generation or direct-audio transcription, or when a product UI needs the
provider-owned voice catalog:

```dart
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:llm_dart/core.dart' as core;

final speechModel = elevenlabs_pkg.elevenLabs(
  apiKey: 'your-elevenlabs-key',
).speechModel('eleven_multilingual_v2');

final result = await core.generateSpeech(
  model: speechModel,
  text: 'Speak clearly and slowly.',
);
```

For transcription:

```dart
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:llm_dart/core.dart' as core;

final transcriptionModel = elevenlabs_pkg.elevenLabs(
  apiKey: 'your-elevenlabs-key',
).transcriptionModel('scribe_v1');

final result = await core.transcribe(
  model: transcriptionModel,
  audioBytes: yourAudioBytes,
  mediaType: 'audio/mpeg',
);
```

For voice selection UI:

```dart
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;

final voices = await elevenlabs_pkg.elevenLabs(
  apiKey: 'your-elevenlabs-key',
).voices().listVoices();

print(voices.map((voice) => voice.name).take(5).toList());
```

### Use This Directory's Examples

Use the compatibility shell in this directory only when you need broader
provider-specific behavior such as:

- voice ID defaults and richer voice controls
- compatibility audio-capability helpers
- file-path convenience flows and broader audio shell behavior
- realtime or admin-style provider-specific APIs

## Examples

### [audio_capabilities.dart](audio_capabilities.dart)
Stable shared speech/transcription plus provider-owned voice catalog,
streaming, convenience, and realtime-boundary appendix.

### Modern Shared Examples

- [ElevenLabs Speech Example](../../../packages/llm_dart_elevenlabs/example/elevenlabs_speech.dart)
- [ElevenLabs Transcription Example](../../../packages/llm_dart_elevenlabs/example/elevenlabs_transcription.dart)
- [ElevenLabs Voice Catalog Example](../../../packages/llm_dart_elevenlabs/example/elevenlabs_voice_catalog.dart)

## Setup

```bash
export ELEVENLABS_API_KEY="your-elevenlabs-api-key"

dart run audio_capabilities.dart
```

## Provider-Owned Boundary

The important distinction is:

- use `elevenLabs(...).speechModel(...)` and `transcriptionModel(...)` for
  stable app-facing media flows
- use `elevenLabs(...).voices().listVoices()` for voice-picker UI
- keep realtime/session behavior or broader audio shell methods as future
  provider-package work rather than reviving removed root provider subpaths

## What Is Not Being Forced Into The Shared Surface

- cloning and studio-style controls
- realtime or session-oriented audio APIs
- file-path convenience helpers that go beyond the shared byte-oriented
  `TranscriptionModel`
- provider admin or account management endpoints

## Next Steps

- [ElevenLabs Provider Package Guide](../../../packages/llm_dart_elevenlabs/README.md) - Modern Ollama and ElevenLabs shared-capability surfaces
- [Core Features](../../02_core_features/) - Shared audio capability examples
- [Advanced Features](../../03_advanced_features/) - Cross-provider multimodal work and provider-owned realtime appendix
- [Migration Guide](../../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md) - Current migration recommendations
