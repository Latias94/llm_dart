# llm_dart_ollama

Ollama provider package for `llm_dart` (local models).

## Install

```bash
dart pub add llm_dart_ollama llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

void main() {
  registerOllama();
}
```

