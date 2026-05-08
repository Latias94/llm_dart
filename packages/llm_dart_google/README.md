# llm_dart_google

Google provider implementations for `llm_dart`.

This package owns the provider-native Google/Gemini model surfaces, typed
Google options, message mapping helpers, Google-specific replay/runtime
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

- `Google(...).chatModel(...)`, `embeddingModel(...)`, `imageModel(...)`, and
  `speechModel(...)`
- Google-owned options such as `GoogleGenerateTextOptions`,
  `GoogleImageOptions`, `GoogleEmbedOptions`, and `GoogleSpeechOptions`
- provider-aware UI helpers such as `GoogleMessageMapper`
- provider-owned image editing and variation through
  `GoogleImageModel.edit(...)` and `createVariation(...)`

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/google.dart`
  - includes the `google(...)` factory plus provider-owned Google types

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
  final model = Google(
    apiKey: 'your-google-key',
  ).imageModel('gemini-2.5-flash-image');

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
