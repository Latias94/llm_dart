# Ollama Residual Completion And Model Listing Policy

## Goal

Freeze the direction for the two main Ollama surfaces that still remain fully
root-owned after chat and embedding delegation:

- `/api/generate`-style completion
- model listing

The question is not whether these features are useful.

The question is whether they should become package-owned modern community
surfaces now, or remain explicit compatibility/provider-owned APIs.

## Current State

After the recent thinning rounds, root `OllamaProvider` now behaves like this:

- chat uses the package-owned modern `LanguageModel` path when the legacy shape
  is bridge-safe
- embeddings use the package-owned modern `EmbeddingModel` path directly
- completion still goes through root `OllamaCompletion`
- model listing still goes through root `OllamaModels`

This creates an important boundary question:

> Are completion and model listing missing pieces of the modern community
> package, or are they intentionally outside the shared modern surface?

## Shared-Core Reality In This Repository

The current shared modern core already freezes these model interfaces:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`

What it does **not** freeze is equally important:

- there is no shared `CompletionModel`
- there is no shared model-catalog or model-management surface

By contrast, `CompletionCapability` and `ModelListingCapability` still live in
the root compatibility-era capability layer.

That means Ollama completion and Ollama model listing are not "unfinished
shared modern migrations" by default.

They are root-era capabilities that now need an explicit policy decision.

## Reference Signal From `repo-ref/ai`

The useful architectural signal from `repo-ref/ai` is:

- primary provider entrypoints focus on modern model factories
- the stable shared model families stay narrow
- provider-specific management or catalog APIs are not promoted automatically
  into the shared provider contract

That does **not** mean the reference forbids provider-specific helpers.

It means those helpers need to justify themselves as provider-owned modern
surfaces instead of being treated as mandatory parts of the shared model layer.

## Analysis: Ollama `/api/generate`

### What It Actually Represents

The Ollama `/api/generate` path is closer to a raw prompt-completion endpoint
than to the shared chat-centric `LanguageModel` abstraction:

- it takes a single prompt string rather than replayable multi-message prompt
  state
- it leans on provider-specific controls such as `raw`, `keep_alive`, and
  `think`
- it does not create new shared capability leverage for Flutter chat or
  cross-provider application code

### Why It Should Not Become A Shared Modern Core Surface

If we try to modernize this path by adding a new shared completion abstraction,
we would widen the shared core for a capability that is:

- legacy-shaped in this repository
- low leverage compared to chat
- not required by the current Flutter/chat-first architectural direction

That would be the wrong trade.

### Frozen Decision

Treat Ollama `/api/generate` completion as a compatibility-owned root surface
for now.

Do **not** add a shared `CompletionModel` or otherwise widen
`llm_dart_core` for this path.

If a real product use case later needs a modern replacement, the correct next
step would be a **provider-owned** typed helper inside `llm_dart_community`,
not a new shared-core abstraction.

## Analysis: Ollama Model Listing

### What It Actually Represents

Model listing is a provider-native catalog and management concern:

- it is not part of text-generation semantics
- it is not needed by the shared runner or Flutter chat runtime
- it depends on provider-specific payload shape and model metadata detail

### Why It Should Not Become A Shared Modern Core Surface

Adding shared model-catalog abstractions would have weak leverage and high risk:

- the common shape across providers is shallow
- the payload detail is provider-specific
- the feature is closer to admin/catalog behavior than to the core generation
  contracts

### Frozen Decision

Treat Ollama model listing as provider-owned or compatibility-only for now.

Do **not** expand the shared modern core or `llm_dart_community` default model
surface just to carry model catalog APIs.

If a real need appears later, add a narrow provider-owned typed catalog helper
instead of widening shared core contracts.

## Practical Outcome For The Refactor

This means the truthful next architecture line for Ollama is:

- `chat` and `embed` continue moving toward package-owned modern models
- `complete` stays an explicit compatibility-era root path
- `models` stays provider-owned or compatibility-only unless a concrete typed
  helper becomes worthwhile

That line keeps the refactor honest:

- high-value shared capability mainlines become modern first
- low-leverage provider-native residual surfaces do not distort the shared API

## Possible Future Provider-Owned Helpers

These are acceptable only if a concrete need appears:

- an `OllamaCompletionHelper`-style typed wrapper for `/api/generate`
- an `OllamaCatalog`-style typed helper for `/api/tags`

If such helpers are ever added, they should:

- live in `llm_dart_community`
- depend only on `llm_dart_transport` and shared lower layers
- use typed request/response models
- avoid reintroducing root compatibility message or capability types

## Immediate Execution Guidance

For the next migration rounds:

- do not create a shared completion abstraction
- do not create a shared model-listing abstraction
- do not count root `complete` or `models` as "missing migration work" for the
  shared modern package
- keep thinning only the shared-capability mainlines unless a concrete
  provider-owned helper is justified
