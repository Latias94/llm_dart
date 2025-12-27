# llm_dart_builder

Fluent builder APIs for configuring `llm_dart` providers.

This package provides:

- `LLMBuilder` (the recommended way to build provider instances)
- Provider option helpers (`providerOptions`, `providerConfig`, etc.)

## Install

```bash
dart pub add llm_dart_builder
```

Most apps also use:

```bash
dart pub add llm_dart_ai
```

## Example

```dart
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  registerOpenAI();

  final model = await LLMBuilder()
      .provider('openai')
      .apiKey('OPENAI_API_KEY')
      .model('gpt-4o')
      .build();

  // Use `model` with `llm_dart_ai` task APIs.
}
```

