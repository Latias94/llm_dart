# llm_dart_ai

Provider-agnostic task APIs for `llm_dart`, inspired by Vercel AI SDK.

This package is the recommended “standard surface” for most applications:

- `generateText`, `streamText`
- `streamChatParts` (Vercel-style stream parts)
- `generateObject`
- `embed`
- `generateImage`
- `generateSpeech`, `streamSpeech`
- `transcribe`, `translateAudio`
- Tool loop orchestration (`runToolLoop`, `streamToolLoop`, `runToolLoopUntilBlocked`)

## Install

```bash
dart pub add llm_dart_ai llm_dart_builder
```

You will also need at least one provider package, e.g.:

```bash
dart pub add llm_dart_openai
```

## Quick start

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  registerOpenAI();

  final model = await LLMBuilder()
      .provider('openai')
      .apiKey('OPENAI_API_KEY')
      .model('gpt-4o')
      .build();

  final prompt = Prompt(messages: [
    PromptMessage.user('Hello!'),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
}
```

## Notes

- Provider-only features should be configured via `providerOptions` / `providerTools` and read via `providerMetadata`.
- Concrete tool implementations (web fetch/search, file access, etc.) are intentionally kept out of this package.
