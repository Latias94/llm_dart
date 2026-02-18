# Google Vertex AI (Gemini) Guide

This guide documents how to use Google Vertex AI (Gemini) via
`llm_dart_google_vertex`.

This package targets **Vertex express mode** (API key authentication), aligned
with Vercel AI SDK `@ai-sdk/google-vertex` express mode.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. Vertex-only knobs
live behind:

- `providerOptions['vertex']`
- `providerMetadata['vertex']`

Legacy input aliases (supported for migration):

- `providerOptions['google-vertex']` (deprecated)
- `providerOptions['google']` (AI SDK <=5 style; deprecated for Vertex)

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

## File URLs (`supportedFileUrlsOnly`)

By default, URL-based parts like `ImageUrlPart` / `FileUrlPart` are compiled to
Google `fileData.fileUri` and the URL is passed through (after trimming).

If you want stricter AI SDK-style validation, enable:

```dart
providerOptions: const {
  'vertex': {
    'supportedFileUrlsOnly': true,
  },
},
```

When enabled, http(s) file URLs are restricted to:

- Google Generative Language Files API:
  `https://generativelanguage.googleapis.com/v1beta/files/...`
- YouTube URLs:
  `https://www.youtube.com/watch?v=...` and `https://youtu.be/...`

`gs://...` URIs and `files/...` resource names are still allowed.

This mode is intentionally conservative; disable it if you rely on arbitrary
public URLs and prefer inline uploads instead.

## Quick start (recommended: task APIs)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_google_vertex/llm_dart_google_vertex.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

Future<void> main() async {
  registerGoogleVertex();

  final model = await LLMBuilder()
      .provider(vertexProviderId) // 'vertex'
      .apiKey(Platform.environment['VERTEX_API_KEY'] ?? 'VERTEX_API_KEY')
      .model('gemini-2.5-flash')
      .build();

  final result = await generateText(
    model: model,
    messages: const [ChatMessage.user('Hello from Vertex!')],
  );

  print(result.text);

  final vertex = readProviderMetadata<Map<String, dynamic>>(
    result.providerMetadata,
    vertexProviderId,
  );
  print(vertex);
}
```

## providerMetadata

Vertex metadata follows Vercel AI SDK conventions:

- `providerMetadata['vertex']` (canonical)
- `providerMetadata['vertex.chat']` (alias; mirrors `vertex`)

Recommended access pattern (canonical + alias-safe):

```dart
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

final vertex = readProviderMetadata<Map<String, dynamic>>(
  result.providerMetadata,
  vertexProviderId,
);

final model = vertex?['model'] ?? vertex?['modelVersion'];
final finishReason = vertex?['finishReason'] ?? vertex?['stopReason'];
final usage = vertex?['usage'];
```

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
      case LLMResponseMetadataPart(:final modelId):
        stderr.writeln('meta: modelId=$modelId');
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
