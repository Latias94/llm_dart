# llm_dart_ai

Provider-agnostic task APIs for `llm_dart`, inspired by Vercel AI SDK.

This package is the recommended “standard surface” for most applications:

- `generateText`
- `streamText` (AI SDK-style convenience wrapper around `streamChatParts`)
- `streamChatParts` (Vercel-style stream parts; recommended streaming API)
- `generateObject`
- `embed`
- `generateImage`
- `generateSpeech`, `streamSpeech`
- `transcribe`, `translateAudio`
- Tool loop orchestration (`runToolLoop`, `streamToolLoopParts`, `runToolLoopUntilBlocked`)

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

  // Best-effort observability metadata (provider-dependent):
  final headers = result.responseMetadata?.headers;
  final responseBody = result.responseMetadata?.body;
  final requestBody = result.requestMetadata?.body;
  final responseMessages = result.responseMessages;
}
```

### Streaming text

```dart
final result = streamText(model: model, promptIr: prompt);

result.fullStream.listen((part) {
  if (part is LLMTextDeltaPart) {
    stdout.write(part.delta);
  }
});

final text = await result.text;
print('\n\nFinal: $text');
```

### Image generation

```dart
final result = await generateImage(
  model: model,
  prompt: const GenerateImagePrompt.text('A cat astronaut'),
  n: 1,
);

final firstUrl = result.image.url;
print(firstUrl);
```

### Per-call provider tools

Provider-native tools (server-side) can be enabled per call via `providerTools`:

```dart
final result = await generateText(
  model: model,
  messages: [ChatMessage.user('Find sources about Vercel AI SDK tools.')],
  providerTools: const [ProviderTool(id: 'openai.web_search')],
);
```

For OpenAI/xAI, prefer typed catalogs from the provider packages (e.g.
`OpenAIProviderTools.webSearchFull(...)`, `XAIProviderTools.webSearch(...)`).

## Notes

- Provider-only features should be configured via `providerOptions` / `providerTools` and read via `providerMetadata`.
- Concrete tool implementations (web fetch/search, file access, etc.) are intentionally kept out of this package.
