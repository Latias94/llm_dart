# ElevenLabs Provider Features

ElevenLabs now has modern shared-capability surfaces in this workspace through
`package:llm_dart_community/llm_dart_community.dart`:

- `ElevenLabs(...).speechModel(...)`
- `ElevenLabs(...).transcriptionModel(...)`

This directory intentionally stays compatibility-oriented because it focuses on
voice and audio features that are broader than the shared modern speech and
transcription surfaces.

## When To Use Which Path

### Prefer The Modern Community Surface

Use `llm_dart_community` when you need shared-capability speech generation or
direct-audio transcription:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

final speechModel = community.ElevenLabs(
  apiKey: 'your-elevenlabs-key',
).speechModel('eleven_multilingual_v2');

final result = await core.generateSpeech(
  model: speechModel,
  text: 'Speak clearly and slowly.',
);
```

### Use This Directory's Examples

Use the compatibility shell in this directory when you need broader
provider-specific behavior such as:

- voice ID defaults and richer voice controls
- compatibility audio-capability helpers
- file-path convenience flows and broader audio shell behavior
- realtime, catalog, or admin-style provider-specific APIs

## Examples

### [audio_capabilities.dart](audio_capabilities.dart)
Compatibility-oriented voice synthesis and broader audio-shell example.

## Setup

```bash
export ELEVENLABS_API_KEY="your-elevenlabs-api-key"

dart run audio_capabilities.dart
```

## Compatibility Boundary

### Compatibility Surface

```dart
import 'package:llm_dart/legacy.dart';

final audioProvider = await ai().elevenlabs().apiKey('your-key')
    .voiceId('JBFqnCBsd6RMkjVDRZzb')
    .stability(0.7)
    .similarityBoost(0.9)
    .buildAudio();
```

This still works, but it should be treated as a transitional shell above the
package-owned modern ElevenLabs models rather than the target architecture for
shared-capability app code.

## What Is Not Being Forced Into The Shared Surface

- voice catalogs, cloning, and studio-style controls
- realtime or session-oriented audio APIs
- file-path convenience helpers that go beyond the shared byte-oriented
  `TranscriptionModel`
- provider admin or account management endpoints

## Next Steps

- [Community Provider Workspace Guide](../../../packages/llm_dart_community/README.md) - Modern Ollama and ElevenLabs shared-capability surfaces
- [Core Features](../../02_core_features/) - Shared audio capability examples
- [Advanced Features](../../03_advanced_features/) - Cross-provider multimodal work
- [Migration Guide](../../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md) - Current migration recommendations
