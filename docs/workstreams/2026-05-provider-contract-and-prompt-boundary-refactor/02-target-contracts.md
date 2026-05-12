# Target Contracts

## Contract Naming Rule

Provider model contracts should use implementation-facing method names.

User-facing names belong to `llm_dart_ai` helpers. Provider-facing names belong
to `llm_dart_provider` contracts and concrete provider model implementations.

## Target Model Method Names

| Model contract | Current provider method | Target provider method | User-facing helper |
| --- | --- | --- | --- |
| `LanguageModel` | `doGenerate` | keep `doGenerate` | `generateText` |
| `LanguageModel` | `doStream` | keep `doStream` | `streamText` |
| `EmbeddingModel` | `embed` | `doEmbed` | `embed`, `embedMany` |
| `ImageModel` | `generate` | `doGenerate` | `generateImage` |
| `SpeechModel` | `generateSpeech` | `doGenerate` | `generateSpeech` |
| `TranscriptionModel` | `transcribe` | `doGenerate` | `transcribe` |

This intentionally matches the stable naming principle in `repo-ref/ai` without
copying TypeScript versioning or package count.

## Request And Result Naming

The existing request/result type names can remain unless a rename removes real
ambiguity:

- `EmbedRequest`
- `EmbedResult`
- `ImageGenerationRequest`
- `ImageGenerationResult`
- `SpeechGenerationRequest`
- `SpeechGenerationResult`
- `TranscriptionRequest`
- `TranscriptionResult`

The method names carry the provider/user boundary. The request and result names
can stay domain-specific and Dart-readable.

## Runtime Helper Updates

`llm_dart_ai` should keep the user-facing helpers:

- `embed(...)`
- `embedMany(...)`
- `generateImage(...)`
- `generateSpeech(...)`
- `transcribe(...)`

Each helper should construct the provider request and call the implementation
method:

- `model.doEmbed(...)`
- `model.doGenerate(...)`

## Provider Package Updates

Each provider package must update concrete implementations and tests:

- OpenAI:
  - embedding
  - image
  - speech
  - transcription
- Google:
  - embedding
  - image
  - speech
- Ollama:
  - embedding
- ElevenLabs:
  - speech
  - transcription

Anthropic currently only needs language-model contract checks unless new
non-text models are added.

## Guard Updates

The workspace guard should reject old implementation names in `packages/**/lib`:

- `Future<EmbedResult> embed(`
- `Future<ImageGenerationResult> generate(`
- `Future<SpeechGenerationResult> generateSpeech(`
- `Future<TranscriptionResult> transcribe(`

The guard should allow user-facing helpers inside `llm_dart_ai` by matching
contract signatures rather than all method names blindly.

## Migration Examples

Old direct provider call:

```dart
final result = await model.embed(
  EmbedRequest(values: ['hello']),
);
```

New direct provider-contract call for adapter authors:

```dart
final result = await model.doEmbed(
  EmbedRequest(values: ['hello']),
);
```

Preferred app code:

```dart
final result = await embedMany(
  model: model,
  values: ['hello'],
);
```

Old image direct call:

```dart
final result = await model.generate(
  ImageGenerationRequest(prompt: 'A mountain at sunrise'),
);
```

Preferred app code:

```dart
final result = await generateImage(
  model: model,
  prompt: 'A mountain at sunrise',
);
```
