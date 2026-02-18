# llm_dart_deepseek

DeepSeek provider package for `llm_dart`.

## Install

```bash
dart pub add llm_dart_deepseek llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

void main() {
  registerDeepSeek();
}
```

## Quick start (builder + task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

Future<void> main() async {
  registerDeepSeek();

  final model = await LLMBuilder()
      .provider(deepseekProviderId)
      .apiKey('DEEPSEEK_API_KEY')
      .model('deepseek-chat')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from DeepSeek!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Quick start (ProviderV3 factory)

```dart
import 'package:llm_dart_deepseek/deepseek.dart';
import 'package:llm_dart_core/models/chat_models.dart';

Future<void> main() async {
  final deepseek = createDeepSeek(
    apiKey: 'DEEPSEEK_API_KEY',
  );

  final model = deepseek('deepseek-chat');
  final result = await model.chat([ChatMessage.user('Hello!')]);

  print(result.text);
}
```

## Notes

- The recommended “standard surface” is `package:llm_dart_ai` task APIs; provider methods are the low-level capability interface.
- DeepSeek uses an OpenAI-compatible API surface; protocol parsing is shared via `llm_dart_openai_compatible`.
