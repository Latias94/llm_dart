# llm_dart_anthropic

Anthropic Claude provider package for `llm_dart`.

## Guide

- Anthropic guide (in this repo): [docs/providers/anthropic.md](../../docs/providers/anthropic.md)

## Install

```bash
dart pub add llm_dart_anthropic llm_dart_builder llm_dart_ai
```

## Register provider (subpackage users)

```dart
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

void main() {
  registerAnthropic();
}
```

## Quick start (builder + task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

Future<void> main() async {
  registerAnthropic();

  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey('ANTHROPIC_API_KEY')
      .model('claude-sonnet-4-20250514')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Anthropic!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Notes

- The recommended “standard surface” is `package:llm_dart_ai` task APIs; provider methods are the low-level capability interface.
- Anthropic web search / web fetch are provider-native tools and should be configured via `providerTools` (preferred) or `providerOptions['anthropic']`.

See also:

- `../../docs/provider_tools_catalog.md`
