# Google Vertex AI (Gemini) Guide

This guide documents how to use Google Vertex AI (Gemini) via
`llm_dart_google_vertex`.

This package targets **Vertex express mode** (API key authentication), aligned
with Vercel AI SDK `@ai-sdk/google-vertex` express mode.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. Vertex-only knobs
live behind:

- `providerOptions['google-vertex']`
- `providerMetadata['google-vertex']`

## Packages

- Provider: `llm_dart_google_vertex`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_google` (internal dependency)

## Base URL

Default base URL (AI SDK parity):

- `https://aiplatform.googleapis.com/v1/publishers/google/`

## Authentication (express mode)

Vertex express mode uses API key header auth:

- `x-goog-api-key: <VERTEX_API_KEY>`

## Quick start (recommended: task APIs)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_google_vertex/llm_dart_google_vertex.dart';

Future<void> main() async {
  registerGoogleVertex();

  final model = await LLMBuilder()
      .provider(googleVertexProviderId) // 'google-vertex'
      .apiKey(Platform.environment['VERTEX_API_KEY'] ?? 'VERTEX_API_KEY')
      .model('gemini-2.5-flash')
      .build();

  final result = await generateText(
    model: model,
    messages: const [ChatMessage.user('Hello from Vertex!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## providerMetadata

Vertex metadata follows Vercel AI SDK conventions:

- `providerMetadata['google-vertex']`

Compatibility alias:

- `providerMetadata['google-vertex.chat']` (mirrors `google-vertex`; avoid depending on it)

## Streaming (LLMStreamPart)

Vertex streaming is SSE. Prefer consuming stream output via `LLMStreamPart`:

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

Future<void> printStream(Stream<LLMStreamPart> parts) async {
  await for (final part in parts) {
    switch (part) {
      case LLMStreamStartPart(:final warnings):
        if (warnings.isNotEmpty) stderr.writeln('warnings: $warnings');
      case LLMResponseMetadataPart(:final model):
        stderr.writeln('meta: model=$model');
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMSourceUrlPart(:final url, :final title):
        stderr.writeln('\nsource: ${title ?? '(no title)'} $url');
      case LLMFinishPart(:final finishReason, :final usage):
        stderr.writeln('\nfinish: $finishReason usage=$usage');
      case LLMErrorPart(:final error):
        stderr.writeln('error: $error');
      default:
        break;
    }
  }
}
```

## References

- Provider tools catalog: `docs/provider_tools_catalog.md`
- Provider options reference: `docs/provider_options_reference.md`
- Escape hatches: `docs/provider_escape_hatches.md`
