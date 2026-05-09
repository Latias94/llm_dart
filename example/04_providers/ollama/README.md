# Ollama Provider Features

Ollama now has modern shared-capability surfaces in this workspace through
`package:llm_dart_community/llm_dart_community.dart`:

- `ollama(...).chatModel(...)`
- `ollama(...).embeddingModel(...)`

This directory now focuses on provider-owned local runtime behavior on top of
the modern community surface.

That means:

- chat and embedding entrypoints stay on `community.ollama(...).*Model(...)`
- local model catalog listing now also has a focused provider-owned helper on
  `community.ollama(...).catalog().listModels()`
- Ollama-specific runtime controls stay on
  `community.OllamaGenerateTextOptions`
- only truly residual surfaces such as `/api/generate` remain on the
  compatibility shell

## When To Use Which Path

### Prefer The Modern Community Surface

Use `llm_dart_community` when you only need shared-capability application code
for chat or embeddings:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart/core.dart' as core;

final model = community.ollama(
  baseUrl: 'http://localhost:11434',
).chatModel('llama3.2');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Summarize why local models are useful.'),
  ],
);
```

For embeddings:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart/core.dart' as core;

final embeddingModel = community.ollama(
  baseUrl: 'http://localhost:11434',
).embeddingModel('nomic-embed-text');

final batch = await core.embedMany(
  model: embeddingModel,
  values: const ['local models', 'edge deployment', 'embedding search'],
);
```

For installed local model listing:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;

final catalog = community.ollama(
  baseUrl: 'http://localhost:11434',
).catalog();

final models = await catalog.listModels();
print(models.map((model) => model.name).take(5).toList());
```

### Use This Directory's Examples

Use the examples in this directory when you need Ollama-specific local
deployment and tuning behavior such as:

- `numGpu`, `numThread`, `numCtx`, `numBatch`, and `numa`
- `keepAlive` and local model memory tuning
- reasoning-specific local flags and broader runtime control on the shared
  chat contract
- structured output and tool calling combined with local runtime tuning

## Examples

### [advanced_features.dart](advanced_features.dart)
Modern local deployment and tuning example with explicit Ollama runtime
controls through `OllamaGenerateTextOptions`.

### [thinking_example.dart](thinking_example.dart)
Modern reasoning and local thinking example on the shared streaming/text event
surface.

### Modern Shared Examples

- [Community Ollama Chat Example](../../../packages/llm_dart_community/example/ollama_chat.dart)
- [Community Ollama Embeddings Example](../../../packages/llm_dart_community/example/ollama_embeddings.dart)

## Setup

```bash
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull llama3.2
ollama serve

dart run advanced_features.dart
dart run thinking_example.dart
```

## Compatibility Boundary

### Provider-Specific Compatibility Surface

```dart
import 'package:llm_dart/providers/ollama/ollama.dart' as ollama_compat;

final provider = ollama_compat.createOllamaProvider(
  baseUrl: 'http://localhost:11434',
  model: 'llama3.2',
  numGpu: 1,
  numThread: 8,
  keepAlive: '10m',
);

// Use this shell only for residual `/api/generate` completion flows.
```

This still works, but it should be read as a transitional shell above the
package-owned modern Ollama models rather than the target architecture for
shared-capability app code.

The important distinction is:

- use `ollama(...).chatModel(...)` and `embeddingModel(...)` for stable
  app-facing code
- use `ollama(...).catalog().listModels()` for installed-model picker or local
  diagnostics UI
- use `providers/ollama/ollama.dart` only when you need `/api/generate` or
  broader compatibility surfaces that are still outside the shared community
  package

## What Is Not Being Forced Into The Shared Surface

- installed model listing stays provider-owned rather than becoming a shared
  cross-provider abstraction
- `/api/generate` completion is still compatibility-only
- broader local runtime controls can stay provider-owned even when the chat
  model itself is stable

## Next Steps

- [Community Provider Workspace Guide](../../../packages/llm_dart_community/README.md) - Modern Ollama and ElevenLabs shared-capability surfaces
- [Core Features](../../02_core_features/) - Shared chat contract examples
- [Advanced Features](../../03_advanced_features/) - Custom provider patterns
- [Migration Guide](../../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md) - Current migration recommendations
