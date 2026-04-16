# ElevenLabs Provider Features

ElevenLabs now has modern shared-capability surfaces in this workspace through
`package:llm_dart_community/llm_dart_community.dart`:

- `ElevenLabs(...).speechModel(...)`
- `ElevenLabs(...).transcriptionModel(...)`

This directory now uses a stable-first posture for normal speech and
transcription flows, while still keeping the broader voice/audio appendix
explicitly provider owned.

## When To Use Which Path

### Prefer The Modern Community Surface

Use `llm_dart_community` when you need shared-capability speech generation or
direct-audio transcription:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart/core.dart' as core;

final speechModel = community.ElevenLabs(
  apiKey: 'your-elevenlabs-key',
).speechModel('eleven_multilingual_v2');

final result = await core.generateSpeech(
  model: speechModel,
  text: 'Speak clearly and slowly.',
);
```

For transcription:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart/core.dart' as core;

final transcriptionModel = community.ElevenLabs(
  apiKey: 'your-elevenlabs-key',
).transcriptionModel('scribe_v1');

final result = await core.transcribe(
  model: transcriptionModel,
  audioBytes: yourAudioBytes,
  mediaType: 'audio/mpeg',
);
```

### Use This Directory's Examples

Use the compatibility shell in this directory only when you need broader
provider-specific behavior such as:

- voice ID defaults and richer voice controls
- compatibility audio-capability helpers
- file-path convenience flows and broader audio shell behavior
- realtime, catalog, or admin-style provider-specific APIs

## Examples

### [audio_capabilities.dart](audio_capabilities.dart)
Stable shared speech/transcription plus provider-owned voice catalog,
streaming, convenience, and realtime-boundary appendix.

### Modern Shared Examples

- [Community ElevenLabs Speech Example](../../../packages/llm_dart_community/example/elevenlabs_speech.dart)
- [Community ElevenLabs Transcription Example](../../../packages/llm_dart_community/example/elevenlabs_transcription.dart)

## Setup

```bash
export ELEVENLABS_API_KEY="your-elevenlabs-api-key"

dart run audio_capabilities.dart
```

## Compatibility Boundary

### Provider-Specific Compatibility Surface

```dart
import 'package:llm_dart/providers/elevenlabs/elevenlabs.dart'
    as elevenlabs_compat;

final audioProvider = elevenlabs_compat.createElevenLabsProvider(
  apiKey: 'your-key',
  voiceId: 'JBFqnCBsd6RMkjVDRZzb',
  stability: 0.7,
  similarityBoost: 0.9,
);

final voices = await audioProvider.getVoices();
```

This still works, but it should be treated as a transitional shell above the
package-owned modern ElevenLabs models rather than the target architecture for
shared-capability app code.

The important distinction is:

- use `ElevenLabs(...).speechModel(...)` and `transcriptionModel(...)` for
  stable app-facing media flows
- use `providers/elevenlabs/elevenlabs.dart` only when you really need
  provider-owned voice catalogs, realtime/session behavior, or broader audio
  shell methods

## What Is Not Being Forced Into The Shared Surface

- voice catalogs, cloning, and studio-style controls
- realtime or session-oriented audio APIs
- file-path convenience helpers that go beyond the shared byte-oriented
  `TranscriptionModel`
- provider admin or account management endpoints

## Next Steps

- [Community Provider Workspace Guide](../../../packages/llm_dart_community/README.md) - Modern Ollama and ElevenLabs shared-capability surfaces
- [Core Features](../../02_core_features/) - Shared audio capability examples
- [Advanced Features](../../03_advanced_features/) - Cross-provider multimodal work and provider-owned realtime appendix
- [Migration Guide](../../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md) - Current migration recommendations
