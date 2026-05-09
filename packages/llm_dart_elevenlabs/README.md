# llm_dart_elevenlabs

Provider-native ElevenLabs speech, transcription, voice catalog, options, and
capability descriptors for `llm_dart`.

Use this package when you want a small direct dependency for ElevenLabs audio
generation, audio transcription, or voice listing without depending on the root
`llm_dart` package.

## Supported Surfaces

- short factory `elevenLabs(...)`
- `elevenLabs(...).speechModel(...)`
- `elevenLabs(...).transcriptionModel(...)`
- `elevenLabs(...).voices().listVoices()`
- `ElevenLabsSpeechOptions`
- `ElevenLabsTranscriptionOptions`
- `describeElevenLabsSpeechModel(...)`
- `describeElevenLabsTranscriptionModel(...)`

## Installation

```yaml
dependencies:
  llm_dart_elevenlabs: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

Omit `llm_dart_ai` if your application only constructs provider models or calls
provider-owned voice catalog APIs directly.

## Basic Speech Example

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';

Future<void> main() async {
  final model = elevenLabs(
    apiKey: Platform.environment['ELEVENLABS_API_KEY']!,
  ).speechModel('eleven_multilingual_v2');

  final result = await ai.generateSpeech(
    model: model,
    text: 'Hello from llm_dart.',
  );

  print('Generated ${result.audioBytes.length} bytes');
}
```

## Capability Profiles

ElevenLabs speech and transcription models expose model-centric capability
discovery through `CapabilityDescribedModel.capabilityProfile`. The package also
owns the provider-specific voice catalog surface for voice IDs, labels, tiers,
and preview URLs.

## Runnable Examples

Run these from this package directory:

```bash
dart run example/elevenlabs_speech.dart
dart run example/elevenlabs_transcription.dart
dart run example/elevenlabs_voice_catalog.dart
```

## Relationship To The Root Package

The root `llm_dart` package keeps compatibility-era ElevenLabs entrypoints for
older code. New focused provider code should prefer this package.
