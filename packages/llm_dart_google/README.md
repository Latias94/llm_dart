# llm_dart_google

Google (Gemini) provider package for `llm_dart`.

## Install

```bash
dart pub add llm_dart_google llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_google/llm_dart_google.dart';

void main() {
  registerGoogle();
}
```

## Quick start (builder + task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  registerGoogle();

  final model = await LLMBuilder()
      .provider(googleProviderId)
      .apiKey('GEMINI_API_KEY')
      .model('gemini-2.0-flash')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Gemini!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Notes

- The recommended “standard surface” is `package:llm_dart_ai` task APIs; provider methods are the low-level capability interface.
- Gemini grounding/web search is a provider-native tool and should be configured via `providerTools` (preferred) or `providerOptions['google']`.

## API stability

- Recommended entrypoint (Tier 2): `package:llm_dart_google/llm_dart_google.dart` (or `package:llm_dart_google/google.dart`).
- Opt-in advanced modules (Tier 3): `package:llm_dart_google/client.dart`, `package:llm_dart_google/dio_strategy.dart`, `package:llm_dart_google/provider_tools.dart`, `package:llm_dart_google/web_search_tool_options.dart`.

See also:

- `../../docs/provider_tools_catalog.md`
