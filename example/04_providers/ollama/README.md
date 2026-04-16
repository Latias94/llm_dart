# Ollama Provider Features

Ollama now has modern shared-capability surfaces in this workspace through
`package:llm_dart_community/llm_dart_community.dart`:

- `Ollama(...).chatModel(...)`
- `Ollama(...).embeddingModel(...)`

This directory intentionally stays compatibility-oriented because it focuses on
provider-specific local runtime behavior that is broader than the shared modern
surface.

## When To Use Which Path

### Prefer The Modern Community Surface

Use `llm_dart_community` when you only need shared-capability application code
for chat or embeddings:

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart/core.dart' as core;

final model = community.Ollama(
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

final embeddingModel = community.Ollama(
  baseUrl: 'http://localhost:11434',
).embeddingModel('nomic-embed-text');

final batch = await core.embedMany(
  model: embeddingModel,
  values: const ['local models', 'edge deployment', 'embedding search'],
);
```

### Use This Directory's Examples

Use the compatibility shell in this directory when you need broader local
deployment and tuning behavior such as:

- `numGpu`, `numThread`, `numCtx`, `numBatch`, and `numa`
- `keepAlive` and local model memory tuning
- reasoning-specific local flags and broader runtime control
- residual compatibility-only flows such as `/api/generate`

## Examples

### [advanced_features.dart](advanced_features.dart)
Compatibility-oriented local deployment and tuning example with explicit local
runtime controls.

### [thinking_example.dart](thinking_example.dart)
Compatibility-oriented reasoning and local thinking example.

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

final models = await provider.models();
```

This still works, but it should be read as a transitional shell above the
package-owned modern Ollama models rather than the target architecture for
shared-capability app code.

The important distinction is:

- use `Ollama(...).chatModel(...)` and `embeddingModel(...)` for stable
  app-facing code
- use `providers/ollama/ollama.dart` only when you need local runtime tuning,
  `/api/generate`, model listing, or broader compatibility surfaces

## What Is Not Being Forced Into The Shared Surface

- model listing is still provider-owned or compatibility-only
- `/api/generate` completion is still compatibility-only
- broader local runtime and lifecycle controls should stay provider-owned unless
  a concrete typed modern helper is justified later

## Next Steps

- [Community Provider Workspace Guide](../../../packages/llm_dart_community/README.md) - Modern Ollama and ElevenLabs shared-capability surfaces
- [Core Features](../../02_core_features/) - Shared chat contract examples
- [Advanced Features](../../03_advanced_features/) - Custom provider patterns
- [Migration Guide](../../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md) - Current migration recommendations
