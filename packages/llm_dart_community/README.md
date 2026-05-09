# llm_dart_community

Modern shared-capability entrypoints for Ollama and ElevenLabs.

Use this package when you want a small direct dependency for local Ollama
chat/embeddings or ElevenLabs speech/transcription without depending on the
root `llm_dart` package.

## Supported Surfaces

Use `llm_dart_community` when you want the modern shared-capability APIs for:

- short factories `ollama(...)` and `elevenLabs(...)`
- `ollama(...).chatModel(...)`
- `ollama(...).embeddingModel(...)`
- `ollama(...).catalog().listModels()`
- `elevenLabs(...).speechModel(...)`
- `elevenLabs(...).transcriptionModel(...)`
- `elevenLabs(...).voices().listVoices()`

## Intentional Limits

This alpha package focuses on the shared model APIs. Some broader provider APIs
remain outside this package:

- Ollama `/api/generate` completion
- guaranteed forced tool-choice behavior for every Ollama model
- ElevenLabs realtime, cloning, and admin-style APIs
- ElevenLabs file-path convenience beyond byte-oriented transcription requests

## Capability Profiles

The modern community models also expose model-centric capability discovery:

- `describeOllamaChatModel(...)`
- `describeOllamaEmbeddingModel(...)`
- `describeElevenLabsSpeechModel(...)`
- `describeElevenLabsTranscriptionModel(...)`

The corresponding model instances implement `CapabilityDescribedModel` through
their `capabilityProfile` getter.

This is useful for app and Flutter UI gating, but community-model answers stay
descriptive rather than authoritative. In particular, Ollama model capability
details such as image input or reasoning output may be marked as inferred when
the local model family is not standardized enough for a stronger guarantee.

For the current surfaces, the practical rule is:

- treat ElevenLabs speech and transcription capability answers as the stronger
  hosted-API baseline for this package
- treat the shared Ollama baseline as stable only for the currently modeled
  common subset
- treat Ollama family-shaped extras such as image input or reasoning output as
  potentially `inferred`

More concretely:

- Ollama chat
  - known baseline: streaming, text input, structured output, `api.route=chat`
  - inferred hints: image input for vision-like model families, reasoning
    output for thinking-like model families
- Ollama embeddings
  - known baseline: batch embeddings, `api.route=embed`
- ElevenLabs speech
  - known baseline: output-format support, voice selection,
    `api.route=text_to_speech`
- ElevenLabs transcription
  - known baseline: language hints, timestamps,
    `api.route=speech_to_text`
- ElevenLabs voices
  - provider-owned catalog: voice IDs, labels, tiers, and preview URLs

If app UX depends on certainty, inspect `CapabilityDescriptor.confidence`
before treating a community-model feature as hard support.

## Runnable Examples

This package includes minimal runnable examples for each current modern
surface:

- `example/ollama_chat.dart`
- `example/ollama_embeddings.dart`
- `example/ollama_model_catalog.dart`
- `example/elevenlabs_speech.dart`
- `example/elevenlabs_transcription.dart`
- `example/elevenlabs_voice_catalog.dart`

Run them from this package directory:

```bash
dart run example/ollama_chat.dart
dart run example/ollama_embeddings.dart
dart run example/ollama_model_catalog.dart
dart run example/elevenlabs_speech.dart
dart run example/elevenlabs_transcription.dart
dart run example/elevenlabs_voice_catalog.dart
```

## Relationship To The Root Package

If you need broader legacy or compatibility-era provider APIs, use the root
compatibility entrypoints instead of treating this package as a drop-in
replacement for the old root shells.
