# llm_dart_google

Google provider implementations for `llm_dart`.

This package owns the provider-native Google/Gemini model surfaces, typed
Google options, Google-specific replay/runtime
behavior, and additive provider-owned image-editing helpers.

Use this package when you want direct access to the focused Google package
boundary instead of the broader root facade.

It can be consumed without a dependency on the root `llm_dart` package. Add
`llm_dart_ai` only when you want the shared generation, image, speech, or
embedding helper calls.

## Installation

```yaml
dependencies:
  llm_dart_google: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

That includes:

- `google(...).chatModel(...)`, `embeddingModel(...)`, `imageModel(...)`, and
  `speechModel(...)`
- Google-owned options such as `GoogleGenerateTextOptions`,
  `GoogleImageOptions`, `GoogleEmbedOptions`, and `GoogleSpeechOptions`
- provider-owned replay helpers such as `GoogleCustomPart`,
  `GoogleCustomPartSummary`, `GoogleToolCallReplay`,
  `GoogleToolResponseReplay`, and `GoogleFunctionResponseReplay`
- provider-owned image editing and variation through
  `GoogleImageModel.edit(...)` and `createVariation(...)`

## Recommended Layering

1. Create concrete models with `google(...).*Model(...)`.
2. Use `llm_dart_ai` helpers such as `generateTextCall(...)`, `embed(...)`,
   `generateImage(...)`, and `generateSpeech(...)` for shared app flows.
3. Put Gemini/Google-specific controls in `GoogleGenerateTextOptions`,
   `GoogleEmbedOptions`, `GoogleImageOptions`, or `GoogleSpeechOptions`.
4. Keep UI projection on shared runtime/chat helpers. Inspect Google
   `ProviderMetadata` in app UI code when richer rendering needs it.
5. Use `GoogleCustomPart` / `GoogleCustomPartSummary` on provider
   prompt/content parts or stream events for Google replay payloads.
6. Keep streamed native TTS helper flows on the root compatibility appendix
   until they graduate into a focused provider-owned utility.

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/google.dart`
  - includes the `google(...)` factory plus provider-owned Google types

## Basic Chat Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  final model = google(apiKey: 'your-google-key').chatModel(
    'gemini-2.0-flash',
  );

  final result = await ai.generateTextCall(
    model: model,
    messages: [
      ai.UserModelMessage.text('Summarize Gemini in one paragraph.'),
    ],
  );

  print(result.text);
}
```

## Provider-Owned Options Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  final model = google(apiKey: 'your-google-key').chatModel(
    'gemini-2.5-pro',
    settings: const GoogleChatModelSettings(
      safetySettings: [
        GoogleSafetySetting(
          category: GoogleHarmCategory.harassment,
          threshold: GoogleHarmBlockThreshold.blockOnlyHigh,
        ),
      ],
    ),
  );

  final result = await ai.generateTextCall(
    model: model,
    messages: [
      ai.UserModelMessage.text('Explain why provider options stay typed.'),
    ],
    callOptions: const ai.CallOptions(
      providerOptions: GoogleGenerateTextOptions(
        thinkingLevel: GoogleThinkingLevel.low,
        includeThoughts: true,
      ),
    ),
  );

  print(result.reasoningText);
  print(result.text);
}
```

## Embedding Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  final model = google(apiKey: 'your-google-key')
      .embeddingModel('text-embedding-004');

  final result = await ai.embedMany(
    model: model,
    values: const ['Dart packages', 'Gemini embeddings'],
    dimensions: 512,
    callOptions: const ai.CallOptions(
      providerOptions: GoogleEmbedOptions(
        taskType: 'SEMANTIC_SIMILARITY',
      ),
    ),
  );

  print(result.embeddings.length);
}
```

## Image Editing

Prompt-based image generation uses the shared `generateImage(...)` helper.
Gemini image editing and variation are additive provider-owned helpers because
their file inputs and request shapes are not a shared image-generation
contract.

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  final model =
      google(apiKey: 'your-google-key').imageModel('gemini-2.5-flash-image');

  final input = GoogleImageEditInput.bytes(
    await File('input.png').readAsBytes(),
    mediaType: 'image/png',
  );

  final edited = await model.edit(
    GoogleImageEditRequest(
      prompt: 'Make this image look like a polished mobile app hero asset.',
      images: [input],
      callOptions: const ai.CallOptions(
        providerOptions: GoogleImageOptions(
          aspectRatio: GoogleImageAspectRatio.landscape16x9,
        ),
      ),
    ),
  );

  final variation = await model.createVariation(
    GoogleImageVariationRequest(images: [input]),
  );

  print(edited.images.first.bytes?.length);
  print(variation.images.first.bytes?.length);
}
```

For the larger repository architecture and migration story, start with the root
package README.
