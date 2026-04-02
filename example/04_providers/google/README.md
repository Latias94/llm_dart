# Google Provider Features

Google is already on the stable provider-model architecture for:

- embeddings through `AI.google(...).embeddingModel(...)`
- image generation through `AI.google(...).imageModel(...)`
- one-shot speech generation through `AI.google(...).speechModel(...)`

For new code, prefer those stable model factories plus shared helpers from
`package:llm_dart/core.dart`.

## Example Status

### Stable or Mostly Stable

- [embeddings.dart](embeddings.dart)
- [image_generation.dart](image_generation.dart)

### Compatibility-Oriented

- [google_tts_example.dart](google_tts_example.dart)

The compatibility TTS example still matters because it covers Google-specific
streaming and raw PCM handling that are not yet fully frozen on the stable
surface.

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
import 'package:llm_dart/ai.dart' as llm;

final model = llm.AI.google(apiKey: 'your-google-api-key')
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
import 'package:llm_dart/ai.dart' as llm;

final model = llm.AI.google(apiKey: 'your-google-api-key')
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

### One-Shot Speech Generation

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/ai.dart' as llm;

final model = llm.AI.google(apiKey: 'your-google-api-key')
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

### Speech

- Stable `speechModel(...)` covers one-shot audio generation.
- Provider-specific multi-speaker and sampling controls stay on
  `GoogleSpeechOptions`.
- The native TTS compatibility surface still exists for streamed audio and
  helper workflows around PCM chunk handling.

## Boundary Notes

- Image editing and image-variation workflows are still compatibility oriented.
  The stable `ImageModel` surface is intentionally limited to prompt-based
  generation until typed edit inputs are frozen.
- Google native streaming TTS remains compatibility oriented. The stable speech
  surface already covers one-shot generation, but not the full streaming helper
  workflow in `google_tts_example.dart`.
- Keep Google-specific controls in Google-owned options. Do not widen shared
  `GenerateTextOptions`, `GenerateImage`, or `GenerateSpeech` contracts just to
  fit provider-specific flags.

## Next Steps

- [Core Features](../../02_core_features/) - Shared text, stream, and tool flows
- [Advanced Features](../../03_advanced_features/) - Cross-provider reasoning and UI patterns
- [Use Cases](../../05_use_cases/) - Flutter-facing application examples
