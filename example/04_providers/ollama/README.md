# Ollama Provider Features

Ollama is intentionally still documented as a compatibility-oriented provider
surface in this repository.

Reason:

- the local runtime configuration surface is broader than the current frozen
  `AI.*(...).chatModel(...)` facade
- model-local controls such as GPU threads, memory tuning, and local reasoning
  flags have not been redesigned into a stable provider-owned model API yet

## Examples

### [advanced_features.dart](advanced_features.dart)
Compatibility-oriented local deployment and tuning example.

### [thinking_example.dart](thinking_example.dart)
Compatibility-oriented reasoning and thinking example.

## Setup

```bash
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull llama3.2
ollama serve

dart run advanced_features.dart
dart run thinking_example.dart
```

## Current Boundary

### Compatibility Surface Today

```dart
final provider = await ai().ollama()
    .baseUrl('http://localhost:11434')
    .model('llama3.2')
    .numGpu(1)
    .numThread(8)
    .build();
```

This still works, but it should be read as a transitional surface rather than
the long-term public architecture.

### Planned Stable Direction

When Ollama gets a stable facade, it should follow the same design rules as the
other migrated providers:

- provider-owned model construction
- shared `LanguageModel` app-facing contract
- provider-owned typed local runtime settings instead of raw builder coupling

## Why Ollama Is Different

- local deployment is a real product boundary, not just another remote profile
- runtime tuning is model-session configuration, not simple per-call options
- privacy and offline concerns often require more explicit lifecycle controls

That means forcing Ollama into the current stable facade too early would create
the wrong abstraction.

## Next Steps

- [Core Features](../../02_core_features/) - Shared chat contract examples
- [Advanced Features](../../03_advanced_features/) - Custom provider patterns
