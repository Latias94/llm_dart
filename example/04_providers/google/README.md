# Google Provider Features

Google is already on the stable provider-model architecture for:

- embeddings through `google(...).embeddingModel(...)`
- image generation through `google(...).imageModel(...)`
- one-shot speech generation through `google(...).speechModel(...)`

For new code, prefer those stable model factories plus shared helpers from
`package:llm_dart/core.dart`.

## Example Status

### Stable or Mostly Stable

- [embeddings.dart](embeddings.dart)
- [image_generation.dart](image_generation.dart)

### Stable-First With Compatibility Appendix

- [google_tts_example.dart](google_tts_example.dart)

`google_tts_example.dart` now uses the stable `speechModel(...)` path for
single-speaker, multi-speaker, and prompt-shaped one-shot speech generation.
It keeps only streamed PCM output and voice discovery on the older
compatibility appendix.

## Setup

```bash
export GOOGLE_API_KEY="your-google-api-key"

dart run embeddings.dart
dart run image_generation.dart
dart run google_tts_example.dart
```

## Stable Usage Examples

### Embeddings

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.google(apiKey: 'your-google-api-key')
    .embeddingModel('text-embedding-004');

final result = await core.embedMany(
  model: model,
  values: [
    'Machine learning algorithms learn from data.',
    'Vector embeddings capture semantic meaning.',
  ],
  dimensions: 512,
  callOptions: const core.CallOptions(
    providerOptions: google.GoogleEmbedOptions(
      taskType: 'SEMANTIC_SIMILARITY',
    ),
  ),
);

print(result.embeddings.length);
print(result.embeddings.first.length);
```

### Image Generation

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.google(apiKey: 'your-google-api-key')
    .imageModel('gemini-2.5-flash-image');

final result = await core.generateImage(
  model: model,
  prompt: 'A futuristic robot in a modern kitchen.',
  callOptions: const core.CallOptions(
    providerOptions: google.GoogleImageOptions(
      aspectRatio: google.GoogleImageAspectRatio.landscape16x9,
    ),
  ),
);

print(result.images.first.bytes?.length);
```

### Provider-Owned Image Editing and Variation

```dart
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.google(apiKey: 'your-google-api-key')
    .imageModel('gemini-2.5-flash-image');
final input = google.GoogleImageEditInput.bytes(
  await File('input.png').readAsBytes(),
  mediaType: 'image/png',
);

final edited = await model.edit(
  google.GoogleImageEditRequest(
    prompt: 'Make this image look like a polished mobile app hero asset.',
    images: [input],
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleImageOptions(
        aspectRatio: google.GoogleImageAspectRatio.landscape16x9,
      ),
    ),
  ),
);

final variation = await model.createVariation(
  google.GoogleImageVariationRequest(images: [input]),
);

print(edited.images.first.bytes?.length);
print(variation.images.first.bytes?.length);
```

### One-Shot Speech Generation

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.google(apiKey: 'your-google-api-key')
    .speechModel('gemini-2.5-flash-preview-tts');

final result = await core.generateSpeech(
  model: model,
  text: 'Say cheerfully: Have a wonderful day!',
  voice: 'Kore',
  callOptions: const core.CallOptions(
    providerOptions: google.GoogleSpeechOptions(
      temperature: 0.4,
      maxOutputTokens: 256,
    ),
  ),
);

print(result.mediaType);
print(result.audioBytes.length);
```

## Provider Notes

### Embeddings

- `text-embedding-004` is the main stable embedding path.
- Provider-specific task routing stays on `GoogleEmbedOptions`.
- Dimensionality belongs to the shared `embed(...)` or `embedMany(...)` call
  because it is part of the request contract, not just Google-only metadata.

### Image Generation

- Gemini image models and Imagen models now share the stable `ImageModel`
  contract.
- Provider-specific knobs such as aspect ratio and person generation stay on
  `GoogleImageOptions`.
- Gemini image models currently support only `count=1`; Imagen supports larger
  batches.
- Google image editing and variation now also exist as provider-owned additive
  helpers on `GoogleImageModel.edit(...)` and `createVariation(...)` rather
  than as shared image-contract widening.

### Speech

- Stable `speechModel(...)` covers one-shot audio generation, including
  provider-owned multi-speaker routing through `GoogleSpeechOptions`.
- Provider-specific multi-speaker and sampling controls stay on
  `GoogleSpeechOptions`.
- The native TTS compatibility surface still exists for streamed audio and
  helper workflows around PCM chunk handling.

## Boundary Notes

- Google native streaming TTS remains compatibility oriented. The stable speech
  surface already covers one-shot generation, but not the full streaming helper
  workflow in `google_tts_example.dart`. If this area is revisited later, it
  should land as a provider-owned additive utility in `llm_dart_google`, not as
  shared `SpeechModel` widening.
- Google image editing and variation should stay provider-owned even though
  they already have modern helpers. They are a good example of additive
  provider package value without widening the shared `generateImage(...)`
  contract.
- Keep Google-specific controls in Google-owned options. Do not widen shared
  `GenerateTextOptions`, `GenerateImage`, or `GenerateSpeech` contracts just to
  fit provider-specific flags.

## Next Steps

- [Core Features](../../02_core_features/) - Shared text, stream, and tool flows
- [Advanced Features](../../03_advanced_features/) - Cross-provider reasoning and UI patterns
- [Use Cases](../../05_use_cases/) - Flutter-facing application examples
