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

## API stability

- Recommended entrypoint (Tier 2): `package:llm_dart_anthropic/llm_dart_anthropic.dart` (or `package:llm_dart_anthropic/anthropic.dart`).
- Opt-in advanced modules (Tier 3): endpoint wrappers like `package:llm_dart_anthropic/files.dart` and `package:llm_dart_anthropic/models.dart`.
- Low-level transport types are provided by `llm_dart_anthropic_compatible` and are Tier 3 opt-in (e.g. `package:llm_dart_anthropic_compatible/client.dart`, `package:llm_dart_anthropic_compatible/dio_strategy.dart`).

See also:

- `../../docs/provider_tools_catalog.md`
