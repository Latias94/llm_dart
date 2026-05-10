# Model Registry Design

## Problem

The modern API has focused provider facades, but apps still need to choose
models dynamically. A chat application may store model references in user
settings, route requests by tenant, or switch between cloud and local providers.

The legacy builder handled this by owning too much. The modern replacement
should only resolve a model reference into a typed model contract.

## Design

`ModelRegistry` belongs in `llm_dart_provider` because it only depends on model
contracts:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`

It does not import concrete providers, transport, AI runtime orchestration, or
Flutter.

The registry stores factories by provider ID:

```dart
final registry = ModelRegistry(
  languageModels: {
    'openai': openai(apiKey: openAiKey).chatModel,
    'anthropic': anthropic(apiKey: anthropicKey).chatModel,
    'ollama': ollama().chatModel,
  },
  embeddingModels: {
    'openai': openai(apiKey: openAiKey).embeddingModel,
    'ollama': ollama().embeddingModel,
  },
);
```

Each lookup accepts `provider:modelId`:

```dart
final model = registry.languageModel('openai:gpt-4.1-mini');
```

The separator is the first colon. Additional colons stay in the model ID so
fine-tuned or provider-native IDs remain valid.

## Provider IDs

Provider IDs use the same conservative lowercase shape as provider metadata and
references:

```text
openai
anthropic
google
ollama
elevenlabs
openrouter
deep-seek
```

Invalid IDs fail when the registry is constructed. Invalid references fail when
they are resolved.

## Error Behavior

The registry should fail loudly and specifically:

- invalid reference: `ArgumentError`
- invalid provider ID in registry configuration: `ArgumentError`
- valid provider ID but unsupported model kind: `UnsupportedError`

Errors include available provider IDs for that model kind so apps can surface
useful diagnostics.

## Deliberate Limits

`ModelRegistry` does not:

- configure providers
- own API keys
- own retry, proxy, telemetry, or diagnostics
- choose fallback models automatically
- normalize provider-specific model IDs
- hide provider-specific settings

Those responsibilities stay with provider facades, transport, and app policy.

## Follow-Up

After the registry is available, examples can show three clear paths:

- direct provider usage for simple apps
- registry usage for runtime provider selection
- explicit legacy imports for migration
