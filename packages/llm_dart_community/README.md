# llm_dart_community

Modern shared-capability entrypoints for the current community-provider set in
`llm_dart`.

## What This Package Owns

This package currently owns the modern shared-capability surfaces for:

- Ollama chat and embeddings
- ElevenLabs speech and transcription

These providers remain grouped intentionally in one workspace package.

It depends only on:

- `llm_dart_core`
- `llm_dart_transport`

That keeps the modern community-provider path independent from the root
compatibility layer.

## Why They Stay Together

The repository does not currently need the same package granularity as
`repo-ref/ai`.

Keeping these providers together is the deliberate current tradeoff:

- smaller maintenance surface
- clearer migration path out of the root compatibility host
- enough isolation to keep modern provider code out of root `llm_dart`

This package should only be split further if real release, ownership, or
surface-growth pressure appears.

## Current Scope

Use this package when application code only needs a shared-capability model
surface with provider-owned typed settings or the current narrow provider-owned
helper additions.

Current intentional limits still include:

- Ollama `/api/generate` completion stays outside the shared modern surface
- stronger shared `ToolChoice` forcing for Ollama still degrades to
  provider-side automatic tool selection with warnings
- ElevenLabs realtime flows, cloning, and admin-style APIs stay outside the
  shared modern surface
- ElevenLabs file-path convenience beyond the byte-oriented
  `TranscriptionModel` stays outside this package

## When To Use This Package

Use `llm_dart_community` when you want the modern shared-capability APIs for:

- `Ollama(...).chatModel(...)`
- `Ollama(...).embeddingModel(...)`
- `Ollama(...).catalog().listModels()`
- `ElevenLabs(...).speechModel(...)`
- `ElevenLabs(...).transcriptionModel(...)`
- `ElevenLabs(...).voices().listVoices()`

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

### Current Confidence Posture

For the current modern community surfaces, the practical rule is:

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
