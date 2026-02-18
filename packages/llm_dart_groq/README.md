# llm_dart_groq

Groq provider package for `llm_dart` (OpenAI-compatible).

## Install

```bash
dart pub add llm_dart_groq llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_groq/llm_dart_groq.dart';

void main() {
  registerGroq();
}
```

## Quick start (builder + task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';

Future<void> main() async {
  registerGroq();

  final model = await LLMBuilder()
      .provider(groqProviderId)
      .apiKey('GROQ_API_KEY')
      .model('llama-3.3-70b-versatile')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Groq!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Quick start (ProviderV3 factory)

```dart
import 'package:llm_dart_groq/groq.dart';
import 'package:llm_dart_core/models/chat_models.dart';

Future<void> main() async {
  final groq = createGroq(apiKey: 'GROQ_API_KEY');

  final model = groq('llama-3.3-70b-versatile');
  final result = await model.chat([ChatMessage.user('Hello!')]);

  print(result.text);
}
```

## Notes

- The recommended “standard surface” is `package:llm_dart_ai` task APIs; provider methods are the low-level capability interface.
- Groq uses an OpenAI-compatible API surface; protocol parsing is shared via `llm_dart_openai_compatible`.
