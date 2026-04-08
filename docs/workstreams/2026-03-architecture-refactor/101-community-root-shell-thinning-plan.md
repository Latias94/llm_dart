# Community Root Shell Thinning Plan

## Goal

Define the next execution-focused step after the first real
`llm_dart_community` modern surfaces landed.

The package graph is now in the right direction:

- `llm_dart_community` depends only on `llm_dart_core` and
  `llm_dart_transport`
- the new Ollama and ElevenLabs model surfaces already live in the community
  package

The next blocker is no longer dependency direction.

The next blocker is that the root package still owns too much legacy community
provider behavior.

## Current Status

One meaningful first thinning step has now landed for Ollama:

- the root `OllamaProvider` chat path now delegates replay-safe requests into
  the package-owned `llm_dart_community` chat model
- the root `OllamaProvider` embedding path now delegates directly into the
  package-owned `llm_dart_community` embedding model
- the root shell still keeps a conservative fallback for legacy-only edge cases
  such as named messages and duplicate system-prompt shaping

That means the next question is no longer whether root Ollama can start
delegating at all.

The next question is how far that delegation should go, and how the same
thinning pattern should now be applied to ElevenLabs.

## What Still Lives In The Root Shells

### Ollama

The root layer still owns these compatibility-shaped pieces:

- `OllamaProvider` implementing `ChatCapability`,
  `CompletionCapability`, `EmbeddingCapability`, and
  `ModelListingCapability`
- `OllamaChat`, `OllamaCompletion`, `OllamaEmbeddings`, and
  `OllamaModels`
- legacy request/response shaping around root `ChatMessage`, root `Tool`,
  root chat responses, and root model-listing surfaces

### ElevenLabs

The root layer still owns these compatibility-shaped pieces:

- `ElevenLabsProvider` implementing `AudioCapability` plus a placeholder
  `ChatCapability`
- `ElevenLabsAudio` and the remaining legacy audio request/response models
- compatibility-only voice and audio helpers that still assume the old root
  capability surface

## Why This Matters

If these root shells stay thick, the project will keep reporting that
`llm_dart_community` exists while the real architectural center still sits in
the compatibility layer.

That creates two risks:

- future fixes keep landing in the legacy shell instead of the package-owned
  modern layer
- new product code keeps depending on root compatibility abstractions even when
  a modern model API already exists

This is exactly the kind of false progress the refactor should avoid.

## Recommended Thinning Strategy

### 1. Treat Root Community Providers As Legacy Adapters Only

The root package should continue to expose old provider entrypoints during the
migration window, but those entrypoints should become explicit compatibility
adapters.

That means:

- keep root builder/factory routes only for migration compatibility
- stop letting root provider modules remain the primary implementation home
- prefer delegation into package-owned modern models whenever a shared modern
  surface already exists

### 2. Delegate Shared Modern Capabilities First

The first delegation targets should be the capabilities that already have
truthful shared model surfaces:

- Ollama chat
- Ollama embeddings
- ElevenLabs speech
- ElevenLabs transcription

These are already the capabilities with package-owned modern models.

The root shell should stop re-owning their mainline request codecs over time.

### 3. Keep Non-Shared Or Not-Yet-Frozen Capabilities Explicit

Some capabilities should not be forced into the same migration step:

- Ollama model listing
- Ollama completion-only legacy paths if they still differ materially from the
  shared `LanguageModel`
- ElevenLabs voice catalogs, cloning, realtime audio, or admin-style APIs

For these, the project should choose one of two explicit outcomes:

- keep them as legacy-only shells for now
- or add provider-owned modern helpers later without widening shared core
  contracts

The wrong outcome would be to silently leave them in root forever while
pretending the provider is already migrated.

## Recommended Slice Order

1. Thin the root Ollama shell so chat and embeddings delegate toward
   `llm_dart_community`, while model listing and any remaining completion-only
   paths are evaluated separately.
2. Thin the root ElevenLabs shell so shared audio generation/transcription
   delegate toward `llm_dart_community`, while voice/realtime/admin features
   remain explicitly provider-owned outside the shared audio contract.
3. Mark the root community entrypoints more clearly as compatibility-oriented in
   migration docs and deprecation wording.
4. Only after that, decide whether any remaining Ollama or ElevenLabs features
   deserve provider-owned modern APIs or should remain compatibility-only until
   removal.

## Non-Goals

- do not move root `ChatCapability` or `AudioCapability` into the community
  package
- do not make `llm_dart_community` depend on root compatibility types
- do not pretend every legacy provider method deserves a new shared-core
  abstraction

## Acceptance Signals

This thinning step should be considered successful when:

- the package-owned modern model paths are the default implementation home for
  shared-capability behavior
- root community providers are clearly migration adapters rather than parallel
  primary implementations
- the remaining root-owned features are intentionally legacy-only or explicitly
  scheduled for a provider-owned modern API
