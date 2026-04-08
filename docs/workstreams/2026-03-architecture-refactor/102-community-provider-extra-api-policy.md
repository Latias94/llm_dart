# Community Provider Extra API Policy

## Goal

Freeze how provider-specific community-provider APIs should be handled after the
first package-owned modern Ollama and ElevenLabs surfaces landed.

The question is not whether provider-specific features should exist.

The question is where they should live without collapsing the new package
boundary back into a broad compatibility shell.

## Reference Signal From `repo-ref/ai`

The local `repo-ref/ai` structure gives a useful boundary signal:

- provider packages primarily expose model factories and typed model options
- shared-capability surfaces stay narrow around language, embedding, image,
  speech, transcription, and similar generation tasks
- provider-specific admin, catalog, or account APIs are not pushed into the
  shared provider contract by default

The reference therefore does **not** treat "everything the HTTP API can do" as
the right scope for a provider package's modern public surface.

That ownership rule is more important than copying the reference package count.

## Local Precedent Inside This Repository

This repository already has the right precedent for provider-owned extras:

- `AnthropicFiles` exists as a provider-owned helper because downloadable
  execution files are a real provider-native product primitive
- `GoogleMessageMapper` exists as a provider-owned UI helper because it
  interprets Google-owned replay metadata without widening shared chat/runtime
  contracts

Those examples show the right rule:

- use shared model interfaces for genuinely shared generation capabilities
- use provider-owned helpers only for concrete provider-native workflows
- do not widen `llm_dart_core` just to avoid having provider-specific entry
  points

## Frozen Policy

### 1. Shared-Capability Mainlines Belong In `llm_dart_community`

These are now the correct package-owned modern surfaces:

- `Ollama.chatModel(...)`
- `Ollama.embeddingModel(...)`
- `ElevenLabs.speechModel(...)`
- `ElevenLabs.transcriptionModel(...)`

These remain the default home for shared-capability request shaping and result
decode logic.

### 2. Broad Legacy Provider APIs Stay In Root During The Migration Window

The existing root provider wrappers still own broader compatibility-era APIs:

- `OllamaProvider`
- `ElevenLabsProvider`
- legacy capability interfaces
- legacy request/response compatibility models
- builder/factory migration paths

This is acceptable during migration as long as the root shell is explicit about
being a compatibility adapter rather than the long-term implementation home.

### 3. Provider-Specific Extras Must Not Automatically Become Shared Modern APIs

The following kinds of APIs should **not** be pushed into shared modern model
contracts:

- voice catalogs
- realtime session setup
- account or subscription info
- admin or model-management endpoints
- file-path convenience APIs that require platform-specific I/O assumptions
- provider-specific completion or generation endpoints that do not map
  truthfully onto the shared model abstractions

Adding these to the shared layer would recreate the same over-coupled shape the
refactor is trying to remove.

## Current Placement Matrix

### ElevenLabs

| Feature | Current Placement | Frozen Direction |
| --- | --- | --- |
| Text-to-speech | package-owned shared `SpeechModel` | keep in `llm_dart_community` |
| Audio-byte transcription | package-owned shared `TranscriptionModel` | keep in `llm_dart_community` |
| File-path transcription | root legacy audio shell | keep legacy for now; only consider a future provider-owned helper if a real product need appears |
| Voice catalog | root legacy audio shell | keep provider-owned and out of shared audio contracts |
| Supported-language helper | root legacy audio shell | keep provider-owned or compatibility-only |
| Realtime audio | root legacy audio shell | keep provider-owned and out of shared audio contracts |
| Models and user info | root legacy helper | keep provider-owned or compatibility-only; do not widen shared core |

### Ollama

| Feature | Current Placement | Frozen Direction |
| --- | --- | --- |
| Chat | package-owned shared `LanguageModel` | keep in `llm_dart_community` |
| Embeddings | package-owned shared `EmbeddingModel` | keep in `llm_dart_community` |
| `/api/generate` completion shell | root legacy completion shell | keep compatibility-only until a real need justifies a provider-owned modern helper |
| Model listing | root legacy model-listing shell | keep provider-owned or compatibility-only; do not widen shared core yet |

## When A Provider-Owned Modern Helper *Is* Justified

A provider-specific helper should be added only when all of the following are
true:

1. The feature does not truthfully fit an existing shared model interface.
2. The feature represents a real provider-native workflow that applications
   will use directly.
3. The helper can stay inside the provider package without adding root or core
   back-dependencies.
4. The helper can expose typed request/response models or a narrow typed
   surface instead of another broad `Map<String, dynamic>` API.
5. The root legacy shell can later delegate to it or document it as the
   preferred replacement.

If these conditions are not met, the feature should stay legacy-only for now.

## Immediate Execution Guidance

For the next migration rounds:

- keep thinning shared-capability mainlines first
- keep provider-specific extras explicit and out of shared contracts
- do not add new shared-core abstractions for catalog, realtime, admin, or
  file-path convenience APIs
- only add a new provider-owned modern helper after a concrete product use case
  makes the helper worth owning long-term

This keeps the architecture aligned with the useful part of the reference:
modern provider packages stay narrow and honest, while compatibility shells keep
legacy breadth until there is a justified typed replacement.
