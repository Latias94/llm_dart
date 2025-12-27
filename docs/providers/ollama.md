# Ollama (Local) Guide

This guide documents how to use Ollama via `llm_dart_ollama`.

Ollama is a **local** provider (self-hosted models). The recommended
provider-agnostic surface is `llm_dart_ai` task APIs, while Ollama-specific
runtime knobs are accessed via:

- `providerOptions['ollama']`
- `providerMetadata['ollama']`

## Packages

- Provider: `llm_dart_ollama`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`

## Base URL

Default base URL:

- `http://localhost:11434/`

Endpoints used by LLM Dart:

- Chat: `/api/chat`
- Embeddings: `/api/embeddings`
- Generate completion: `/api/generate`
- List models: `/api/tags`

Official docs:

- Ollama API: https://github.com/ollama/ollama/blob/main/docs/api.md

## Authentication

Ollama is typically local and does not require an API key. If your deployment
requires headers, configure them via `transportOptions` (or a reverse proxy).

## Quick start (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

Future<void> main() async {
  registerOllama();

  final model = await LLMBuilder()
      .provider(ollamaProviderId)
      .baseUrl('http://localhost:11434/')
      .model('llama3.1')
      .build();

  final result = await generateText(
    model: model,
    messages: [ChatMessage.user('Hello from Ollama!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## Streaming (JSONL)

Ollama streaming is JSONL (one JSON object per line). LLM Dart parses the JSONL
stream and emits standard `LLMStreamPart` items.

## Provider options (local runtime knobs)

Ollama exposes local runtime knobs via `providerOptions['ollama']` (best-effort):

- `numCtx`: `int`
- `numGpu`: `int`
- `numThread`: `int`
- `numa`: `bool`
- `numBatch`: `int`
- `keepAlive`: `String`
- `raw`: `bool`
- `reasoning`: `bool`
- `jsonSchema`: `StructuredOutputFormat` (structured output / JSON)

Reference:

- `docs/provider_options_reference.md`
- `docs/provider_escape_hatches.md`

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For Ollama, the namespace is:

- `providerMetadata['ollama']`

The provider surfaces best-effort metadata such as:

- `model`, `createdAt`, `doneReason`
- `usage` (prompt/completion/total tokens when available)
- performance timings (`totalDuration`, `evalDuration`, etc.)
- `context` (when returned by Ollama)

## Conformance tests

Ollama provider tests:

- `test/providers/ollama/ollama_config_test.dart`
- `test/providers/ollama/ollama_factory_test.dart`
- `test/providers/ollama/ollama_provider_test.dart`
- `test/providers/ollama/ollama_stream_parts_test.dart`
- `test/providers/ollama/ollama_thinking_test.dart`

