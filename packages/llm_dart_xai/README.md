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
