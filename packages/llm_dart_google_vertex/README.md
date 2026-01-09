# llm_dart_google_vertex

Google Vertex AI provider package for `llm_dart`.

This package currently targets **Vertex "express mode"** (API key authentication), aligned with Vercel AI SDK `@ai-sdk/google-vertex` express mode.

## Install

```bash
dart pub add llm_dart_google_vertex llm_dart_builder llm_dart_ai
```

## Usage (Builder)

```dart
import 'package:llm_dart/llm_dart.dart';

final provider = await ai()
  .provider('google-vertex')
  .apiKey('YOUR_VERTEX_API_KEY')
  .model('gemini-2.5-flash')
  .build();
```

## Notes

- Provider metadata keys follow Vercel AI SDK: `vertex` and `vertex.chat`.
- Non-express (OAuth / service account) authentication is not implemented yet.

