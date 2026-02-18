# Google Provider Examples

This directory contains usage examples for the Google (Gemini) provider.

## 📁 File Structure

- `embeddings.dart` - text embeddings
- `image_generation.dart` - image generation (Gemini + Imagen)
- `google_tts_example.dart` - native text-to-speech (TTS)

## 🔑 API Key

Recommended environment variable (Vercel AI SDK parity):

```bash
export GOOGLE_GENERATIVE_AI_API_KEY="your-google-api-key"
```

For backwards compatibility, some examples also accept `GOOGLE_API_KEY`.

## ✅ Recommended Usage (ProviderV3)

This repo provides an AI SDK-style callable provider factory:

- `createGoogleGenerativeAI(...)` / `google(...)` returns a `ProviderV3`
- Calling it with a model id returns a model instance (e.g. `google('gemini-2.5-flash')`)

```dart
import 'package:llm_dart_google/google.dart';

final google = createGoogleGenerativeAI(apiKey: null); // reads GOOGLE_GENERATIVE_AI_API_KEY
final model = google('gemini-2.5-flash');
```

## 🔢 Embeddings

Supported models (examples):

- `text-embedding-004`
- `text-embedding-003`

### Basic Usage

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_google/google.dart';

final google = createGoogleGenerativeAI(apiKey: null);
final model = google.embeddingModel('text-embedding-004');

final result = await embedMany(
  model: model,
  values: ['Hello', 'World'],
);

print(result.embeddings.first.length);
```

### Google-Specific Parameters (per-call)

These map to the Google Embeddings API request fields (escape hatch via `LLMCallOptions.body`):

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';

final google = createGoogleGenerativeAI(apiKey: null);
final model = google.embeddingModel('text-embedding-004');

await embedMany(
  model: model,
  values: ['doc A', 'doc B'],
  callOptions: const LLMCallOptions(
    body: {
      'taskType': 'SEMANTIC_SIMILARITY',
      'outputDimensionality': 512,
    },
  ),
);
```

## 🎨 Image Generation

Supported models (examples):

- `gemini-2.0-flash-preview-image-generation`
- `imagen-3.0-generate-002`

### Gemini Image Generation

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_google/google.dart';

final google = createGoogleGenerativeAI(apiKey: null);
final imageModel = google.imageModel('gemini-2.0-flash-preview-image-generation');

final result = await generateImage(
  model: imageModel,
  prompt: const GenerateImageTextPrompt('A futuristic robot in a modern kitchen'),
);

final bytes = result.images.first.data;
if (bytes != null) {
  await File('generated.png').writeAsBytes(bytes);
}
```

### Imagen 3 Image Generation

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_google/google.dart';

final google = createGoogleGenerativeAI(apiKey: null);
final imageModel = google.imageModel('imagen-3.0-generate-002');

final result = await generateImage(
  model: imageModel,
  prompt: const GenerateImageTextPrompt('A serene mountain landscape at sunset'),
  n: 2,
  aspectRatio: '1:1',
);
```

## 🎤 Text-to-Speech (TTS)

TTS models (examples):

- `gemini-2.5-flash-preview-tts`
- `gemini-2.5-pro-preview-tts`

### Basic Usage

```dart
import 'dart:io';

import 'package:llm_dart_google/google.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

final google = createGoogleGenerativeAI(apiKey: null);

// Use the callable provider to get a GoogleProvider instance.
final ttsProvider = google('gemini-2.5-flash-preview-tts');

final response = await ttsProvider.textToSpeech(
  const TTSRequest(
    text: 'Say cheerfully: Have a wonderful day!',
    voice: 'Kore',
    model: 'gemini-2.5-flash-preview-tts',
  ),
);

await File('output.pcm').writeAsBytes(response.audioData);
```

Important: the dedicated example `google_tts_example.dart` shows how to convert
PCM into a playable WAV file by adding a WAV header.

## 🧰 Legacy Notes

The older registry/builder helpers (e.g. `createGoogleProvider(...)`) are still
available for compatibility, but the recommended path is ProviderV3.

