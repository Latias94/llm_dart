# llm_dart_google_vertex

Google Vertex AI provider package for `llm_dart`.

This package currently targets **Vertex "express mode"** (API key authentication), aligned with Vercel AI SDK `@ai-sdk/google-vertex` express mode.

## Install

```bash
dart pub add llm_dart_google_vertex llm_dart_builder llm_dart_ai
```

## Usage (Builder)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_google_vertex/llm_dart_google_vertex.dart';

Future<void> main() async {
  registerGoogleVertex();

  final model = await LLMBuilder()
      .provider(vertexProviderId) // 'vertex'
      .apiKey(Platform.environment['VERTEX_API_KEY'] ?? 'VERTEX_API_KEY')
      .model('gemini-2.5-flash')
      .build();

  final result = await generateText(
    model: model,
    prompt: 'Hello from Vertex!',
  );

  print(result.text);
}
```

## Notes

- AI SDK v6 parity keys:
  - Canonical: `vertex`
  - Alias: `vertex.chat`
  - Legacy input alias (deprecated): `google-vertex` (still accepted)
- Non-express (OAuth / service account) authentication is not implemented yet.

See also:

- `docs/providers/google_vertex.md`
