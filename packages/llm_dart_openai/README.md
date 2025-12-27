# llm_dart_openai

OpenAI provider package for `llm_dart`.

## Install

```bash
dart pub add llm_dart_openai llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

void main() {
  registerOpenAI();
}
```

## Quick start (builder + task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  registerOpenAI();

  final model = await LLMBuilder()
      .provider(openaiProviderId)
      .apiKey('OPENAI_API_KEY')
      .model('gpt-4.1-mini')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from OpenAI!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Notes

- The recommended “standard surface” is `package:llm_dart_ai` task APIs; provider methods are the low-level capability interface.
- Supports the OpenAI Responses API and provider-native built-in tools (web search, file search, computer use) via `providerTools` (preferred) or `providerOptions['openai']`.

See also:

- `../../docs/provider_tools_catalog.md`
