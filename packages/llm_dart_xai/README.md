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

## Quick start (builder + task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

Future<void> main() async {
  registerXAI();

  final model = await LLMBuilder()
      .provider(xaiProviderId)
      .apiKey('XAI_API_KEY')
      .model('grok-3')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from xAI!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Quick start (ProviderV3 factory)

```dart
import 'package:llm_dart_xai/xai.dart';
import 'package:llm_dart_core/models/chat_models.dart';

Future<void> main() async {
  final xai = createXai(apiKey: 'XAI_API_KEY');

  final chat = xai('grok-3');
  final result = await chat.chat([ChatMessage.user('Hello!')]);
  print(result.text);

  // Provider-native entrypoints (upstream parity):
  final image = xai.imageModel('grok-2-image');
  final video = xai.videoModel('grok-imagine-video');
  final responses = xai.responses('grok-4-fast');
}
```

## API stability

- Recommended entrypoint (Tier 2): `package:llm_dart_xai/llm_dart_xai.dart` (or `package:llm_dart_xai/xai.dart`).
- Opt-in advanced module (Tier 3): `package:llm_dart_xai/responses.dart` for the provider-native `/responses` adapter (`xai.responses`).
- Low-level OpenAI-compatible transport is Tier 3 opt-in via `package:llm_dart_xai/client.dart` and `package:llm_dart_xai/dio_strategy.dart`.
