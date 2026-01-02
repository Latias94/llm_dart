# llm_dart_xai

xAI (Grok) provider package for `llm_dart` (OpenAI-compatible).

## Install

```bash
dart pub add llm_dart_xai llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_xai/llm_dart_xai.dart';

void main() {
  registerXAI();
}
```

## API stability

- Recommended entrypoint (Tier 2): `package:llm_dart_xai/llm_dart_xai.dart` (or `package:llm_dart_xai/xai.dart`).
- Opt-in advanced module (Tier 3): `package:llm_dart_xai/responses.dart` for the provider-native `/responses` adapter (`xai.responses`).
- Low-level OpenAI-compatible transport is Tier 3 opt-in via `llm_dart_openai_compatible` (e.g. `package:llm_dart_openai_compatible/client.dart`).
