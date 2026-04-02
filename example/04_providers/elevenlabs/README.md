# ElevenLabs Provider Features

ElevenLabs is currently documented as a compatibility-oriented provider surface.

Reason:

- the repository does not yet expose a stable `AI.elevenlabs(...)` facade
- ElevenLabs-specific voice controls are still tied to the older audio builder
  surface
- we do not want to freeze the wrong speech abstraction before the provider
  boundary is settled

## Examples

### [audio_capabilities.dart](audio_capabilities.dart)
Compatibility-oriented voice synthesis and audio processing example.

## Setup

```bash
export ELEVENLABS_API_KEY="your-elevenlabs-api-key"

dart run audio_capabilities.dart
```

## Current Boundary

### Compatibility Surface Today

```dart
final audioProvider = await ai().elevenlabs().apiKey('your-key')
    .voiceId('JBFqnCBsd6RMkjVDRZzb')
    .stability(0.7)
    .similarityBoost(0.9)
    .buildAudio();
```

This still works, but it should be treated as transitional.

### Stable Direction Later

If ElevenLabs gets a frozen stable surface, it should look like the other
migrated providers:

- provider-owned model construction
- shared app-facing speech contract where it actually fits
- provider-owned typed voice controls instead of cross-provider leakage

## Practical Guidance

- If you need a stable speech facade today, OpenAI and Google already have
  package-owned `speechModel(...)` entrypoints.
- If you need ElevenLabs-specific voice cloning or studio controls today, use
  the compatibility example and keep the integration isolated.

## Next Steps

- [Core Features](../../02_core_features/) - Shared audio capability examples
- [Advanced Features](../../03_advanced_features/) - Cross-provider multimodal work
