# Provider Capability Discovery Design

## Goal

Define how `llm_dart` should expose model capability discovery and
provider-native feature surfacing after the architecture-heavy refactor phase.

The desired outcome is:

- app code can ask what a concrete model can do
- Flutter chat apps can gate UI affordances without hard-coding provider names
- provider-native features stay discoverable without polluting shared core
- the legacy root capability registry remains compatibility infrastructure, not
  the modern source of truth

## Current State

### Modern Package-Owned Model APIs

The modern packages already expose capability-specific factories:

- `OpenAI.chatModel(...)`
- `OpenAI.embeddingModel(...)`
- `OpenAI.imageModel(...)`
- `OpenAI.speechModel(...)`
- `OpenAI.transcriptionModel(...)`
- `Google.chatModel(...)`
- `Google.embeddingModel(...)`
- `Google.imageModel(...)`
- `Google.speechModel(...)`
- `Anthropic.chatModel(...)`

The shared core also already has capability-specific interfaces and helpers:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`
- `generateText(...)`
- `streamText(...)`
- `embed(...)`
- `embedMany(...)`
- `generateImage(...)`
- `generateSpeech(...)`
- `transcribe(...)`

This is the correct modern direction.

### Provider-Owned Options Are Already Typed

The modern provider packages already use typed provider-owned configuration:

- model defaults implement `ProviderModelOptions`
- invocation options implement `ProviderInvocationOptions`
- call-level provider options are passed through `CallOptions.providerOptions`

Examples:

- `OpenAIChatModelSettings`
- `OpenAIGenerateTextOptions`
- `GoogleChatModelSettings`
- `GoogleGenerateTextOptions`
- `AnthropicChatModelSettings`
- `AnthropicGenerateTextOptions`

This is better for Dart than the untyped namespaced map style used by the
reference TypeScript implementation because it gives app authors IDE help and
compile-time validation.

### Legacy Root Capability Discovery Still Exists

The root compatibility layer still has:

- `LLMCapability`
- `ProviderCapabilities`
- `CapabilityUtils`
- `ProviderRegistry`

That surface is useful for legacy provider selection, but it is provider-level
and enum-driven. It is not precise enough for the modern model APIs because:

- real capabilities are often model-specific, not provider-wide
- native features have provider-specific semantics
- a single provider package may expose several independent capability models
- app-facing UI decisions need more nuance than `LLMCapability.vision`

So the legacy registry should not become the modern capability discovery source
of truth.

## Reference Signals From `repo-ref/ai`

The useful reference signals are:

1. provider model objects are the real unit of capability behavior
2. provider-specific options stay under provider-owned namespaces
3. unsupported shared settings produce warnings or provider-owned guardrails
4. model-family helper tables are practical for model-specific behavior
5. non-text helpers stay capability-specific instead of being hidden behind one
   giant provider object

The current local reference also has an OpenAI model capability helper for:

- reasoning-model detection
- default system-message mode
- service-tier support
- non-reasoning parameter compatibility

`llm_dart_openai` already mirrors this with
`OpenAIModelCapabilities`.

The reference should **not** be copied literally in two areas:

- do not replace typed Dart provider options with untyped namespaced maps
- do not add a large published provider-utils package only for discovery

## Design Decision

Modern capability discovery should be **model-centric**, **additive**, and
**descriptive**.

It should not be a new provider execution layer.

### Model-Centric

Capability answers should be attached to or derived from a concrete model
instance or a concrete `(providerId, modelId, capability kind)` tuple.

Provider-level capability sets are too coarse.

### Additive

The first implementation should be additive:

- no breaking changes to `LanguageModel`
- no removal of root `LLMCapability`
- no new required provider methods
- no change to current provider factories

### Descriptive

Discovery should describe:

- what the library believes the model supports
- where that belief came from
- whether the answer is known, inferred, unknown, or user-overridden

It should not guarantee that a remote provider will never reject a request.

## Capability Layers

Capability discovery should be split into four layers.

### 1. Shared Capability Kind

This is the coarse shared model category:

- language
- embedding
- image
- speech
- transcription

This maps directly to the existing model interfaces.

### 2. Shared Feature Flags

These are cross-provider features that are stable enough for app logic.

For `LanguageModel`, useful shared flags are:

- streaming
- function tools
- tool choice
- structured output
- JSON response format
- reasoning output
- text input
- image input
- file input
- audio input
- source output
- file output
- approval requests

For non-text models, useful shared flags are narrower:

- batch embeddings
- configurable embedding dimensions
- multiple image output
- image editing
- speech output format
- speech voice selection
- transcription timestamps
- transcription language hints

These flags should remain small. They are for app behavior, not for mirroring
every provider knob.

### 3. Provider Feature Descriptors

Provider-native features should be discoverable through provider-owned
descriptors.

Examples:

- OpenAI Responses routing
- OpenAI built-in tools
- OpenAI `serviceTier`
- OpenAI `reasoningEffort`
- OpenAI stored response continuation
- Google native tools
- Google safety settings
- Google server-side tool invocation circulation
- Anthropic extended thinking
- Anthropic MCP servers
- Anthropic deferred tools

These descriptors should stay namespaced by provider and should not imply a
shared semantic contract.

### 4. Runtime Warnings And Metadata

Even with discovery, actual calls can still produce:

- warnings for unsupported or ignored settings
- provider metadata for returned provider-specific detail
- errors when a provider rejects a request

Discovery should reduce surprises, not replace provider-side validation.

## Proposed Core Types

The first future implementation slice should add a small focused descriptor set
to `llm_dart_core`.

This should be additive and self-contained.

```dart
enum ModelCapabilityKind {
  language,
  embedding,
  image,
  speech,
  transcription,
}

enum CapabilityConfidence {
  known,
  inferred,
  unknown,
  userProvided,
}

final class CapabilityDescriptor {
  final String id;
  final CapabilityConfidence confidence;

  const CapabilityDescriptor({
    required this.id,
    this.confidence = CapabilityConfidence.known,
  });
}

final class ProviderFeatureDescriptor {
  final String providerId;
  final String featureId;
  final CapabilityConfidence confidence;
  final Object? detail;

  const ProviderFeatureDescriptor({
    required this.providerId,
    required this.featureId,
    this.confidence = CapabilityConfidence.known,
    this.detail,
  });
}

final class ModelCapabilityProfile {
  final String providerId;
  final String modelId;
  final ModelCapabilityKind kind;
  final Set<CapabilityDescriptor> sharedFeatures;
  final List<ProviderFeatureDescriptor> providerFeatures;

  const ModelCapabilityProfile({
    required this.providerId,
    required this.modelId,
    required this.kind,
    this.sharedFeatures = const {},
    this.providerFeatures = const [],
  });

  bool supports(String featureId) {
    return sharedFeatures.any((feature) => feature.id == featureId);
  }
}
```

The exact API can be adjusted during implementation, but the important shape is:

- one model profile
- shared app-facing feature IDs
- provider-owned feature descriptors
- confidence attached to the answer

## Optional Model Interface

Do not add required members to existing model interfaces.

Instead, add optional marker interfaces:

```dart
abstract interface class CapabilityDescribedModel {
  ModelCapabilityProfile get capabilityProfile;
}
```

Provider models can implement this gradually.

Apps can use:

```dart
final profile = switch (model) {
  CapabilityDescribedModel(:final capabilityProfile) => capabilityProfile,
  _ => null,
};
```

This keeps the migration additive and avoids breaking third-party model
implementations.

## Provider-Owned Static Helpers

Provider packages should also expose static or top-level helpers for apps that
need to evaluate a model before constructing it.

Examples:

```dart
final profile = describeOpenAIChatModel('gpt-5.4');
final googleProfile = describeGoogleChatModel('gemini-3-pro');
```

These helpers should live in provider packages, not in `llm_dart_core`.

They can internally reuse provider-owned model-family heuristics such as
`OpenAIModelCapabilities`.

## Provider-Native Feature Surfacing

Provider-native features should keep using the existing five-channel rule.

### 1. Model Settings

Use for stable model-instance defaults.

Examples:

- `OpenAIChatModelSettings.useResponsesApi`
- `OpenAIChatModelSettings.builtInTools`
- `GoogleChatModelSettings.tools`
- `GoogleChatModelSettings.safetySettings`
- `AnthropicChatModelSettings.tools`
- `AnthropicChatModelSettings.betaFeatures`

### 2. Invocation Options

Use for per-call provider controls.

Examples:

- `OpenAIGenerateTextOptions.reasoningEffort`
- `OpenAIGenerateTextOptions.serviceTier`
- `OpenAIGenerateTextOptions.previousResponseId`
- `GoogleGenerateTextOptions.thinkingBudgetTokens`
- `GoogleGenerateTextOptions.responseModalities`
- `AnthropicGenerateTextOptions.extendedThinking`
- `AnthropicGenerateTextOptions.mcpServers`

### 3. Provider Metadata

Use for provider-owned returned detail that should survive result handling.

Examples:

- response service tier
- safety ratings
- reasoning detail
- provider request identifiers
- cache or storage detail

### 4. Custom Parts And Events

Use for provider-native output blocks that must survive rendering, replay, or
transport.

Examples:

- OpenAI image generation custom output
- OpenAI MCP list-tools output
- Google grounding or thought-signature parts
- Anthropic tool-reference or execution-shaped blocks

### 5. Provider-Native APIs

Use for APIs whose lifecycle does not normalize cleanly.

Examples:

- provider-native file management
- stored responses
- provider-side assistants
- moderation or admin APIs
- Anthropic files

## Flutter App Integration

Flutter chat apps should use capability profiles for UI affordances, not for
hard security guarantees.

Useful app decisions include:

- show or hide image attachment buttons
- show or hide file attachment buttons
- enable tool approval UI only when approval requests may appear
- choose structured-output flows only for capable models
- explain why a selected model cannot support a requested feature
- select a fallback model when a required shared feature is missing

Example policy:

```dart
bool canAttachImages(ModelCapabilityProfile profile) {
  return profile.supports('language.input.image') ||
      profile.supports('image.edit');
}
```

Provider-native UI should remain provider-aware.

For example, a UI that configures OpenAI built-in `file_search` should depend on
`llm_dart_openai`, not pretend that `file_search` is a shared tool feature.

## Relationship To Legacy `LLMCapability`

The legacy enum should be treated as a compatibility adapter.

Recommended mapping direction:

- modern `ModelCapabilityProfile` can be approximated into `LLMCapability`
  for old registries
- legacy `LLMCapability` should not be used to infer precise modern model
  behavior

Do not move `ProviderRegistry` into `llm_dart_core`.

Do not make the root compatibility registry the source of truth for modern
provider packages.

## Implementation Slices

### Slice 1: Documentation And Policy

Status: this document.

Outcome:

- freeze the model-centric direction
- freeze legacy registry placement
- freeze provider-native surfacing rules

### Slice 2: Add Core Descriptor Types

Add a small file such as:

- `packages/llm_dart_core/lib/src/model/model_capability_profile.dart`

Export it from:

- `packages/llm_dart_core/lib/model.dart`
- `packages/llm_dart_core/lib/llm_dart_core.dart`

Do not make existing model interfaces implement anything yet.

Status:

- landed as an additive core surface
- exported from both `llm_dart_core.dart` and the focused `model.dart`
  entrypoint
- covered by dedicated core tests
- still does not require existing model interfaces to implement a new member

### Slice 3: Add Provider Describers

Add provider-owned helpers:

- `describeOpenAIChatModel(...)`
- `describeOpenAIEmbeddingModel(...)`
- `describeOpenAIImageModel(...)`
- `describeGoogleChatModel(...)`
- `describeAnthropicChatModel(...)`

OpenAI should land first because it already has
`OpenAIModelCapabilities`.

Status:

- landed first in `llm_dart_openai`
- includes provider-owned describers for chat, embedding, image, speech, and
  transcription models
- reuses existing OpenAI-family route and model-capability helpers instead of
  inventing a second capability table
- still keeps model classes themselves optional for later direct
  `CapabilityDescribedModel` adoption

### Slice 4: Implement Optional Marker Interfaces

Have modern provider model classes implement `CapabilityDescribedModel`.

This can be additive and non-breaking.

### Slice 5: Add Flutter/App Examples

Add examples that show:

- capability-gated attachment UI
- provider-native option panels
- graceful fallback when a model lacks a shared feature

## Non-Goals

Do not:

- add a large `provider-utils` package
- move provider-native features into shared core
- replace typed provider options with untyped maps
- make network calls part of default capability discovery
- use `LLMCapability` as the modern precision model
- promise that a descriptor prevents every provider-side rejection

## Acceptance Criteria For The Future Implementation

A future implementation is successful if:

1. apps can inspect a model's shared capability profile without importing the
   root compatibility layer
2. provider-native features are visible but namespaced and provider-owned
3. existing model interfaces remain source-compatible
4. Flutter chat examples can gate common UI affordances from shared descriptors
5. provider codecs still own final validation and warnings

## Bottom Line

The next capability layer should not be another compatibility enum.

It should be a small, model-centric description system:

- shared flags for app decisions
- provider-owned feature descriptors for native value
- optional marker interfaces for additive adoption
- legacy capability mapping only as an adapter

That keeps `llm_dart` aligned with the mature parts of `repo-ref/ai` while
remaining Dart-first, Flutter-friendly, and provider-native where it matters.
