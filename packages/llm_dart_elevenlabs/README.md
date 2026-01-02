# llm_dart_elevenlabs

ElevenLabs provider package for `llm_dart` (TTS/STT/voices).

## Install

```bash
dart pub add llm_dart_elevenlabs llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_elevenlabs/elevenlabs.dart';

void main() {
  registerElevenLabs();
}
```

## API stability

- Recommended entrypoint (Tier 2): `package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart` (or `package:llm_dart_elevenlabs/elevenlabs.dart`).
- Opt-in advanced modules (Tier 3): `package:llm_dart_elevenlabs/client.dart`, `package:llm_dart_elevenlabs/dio_strategy.dart`.

