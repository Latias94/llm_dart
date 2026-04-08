# 105. Community Provider Decoupling Blocker Inventory

## Why This Exists

The repository has now crossed two important thresholds:

- `llm_dart_community` is a real package-owned modern surface
- public guidance now teaches that package as the modern shared-capability home
  for Ollama and ElevenLabs

That means the next meaningful question is no longer whether the community
package is real.

The next question is: what exactly still prevents more implementation weight
from moving away from the root package without inverting dependency direction or
reintroducing the old coupling?

## Current State

What is already true:

- `llm_dart_community` depends only on `llm_dart_core` and
  `llm_dart_transport`
- modern Ollama chat and embeddings already live there
- modern ElevenLabs speech and direct-audio transcription already live there
- root provider entrypoints already delegate shared-capability mainlines toward
  the community package where possible

What is still not true:

- the root Ollama and ElevenLabs shells are not yet thin enough to be treated
  as trivial wrappers
- the builder/factory/config compatibility path is still root-owned
- several residual provider-shaped APIs still live in root provider modules

## Blocker Categories

### 1. Root Compatibility Interfaces Still Define The Shell Shape

The root provider shells still implement root compatibility interfaces such as:

- `ChatCapability`
- `CompletionCapability`
- `EmbeddingCapability`
- `AudioCapability`
- `ModelListingCapability`

That keeps them tied to root compatibility request and response shapes such as:

- `ChatMessage`
- `Tool`
- `TTSRequest`
- `STTRequest`
- `CompletionRequest`

Evidence:

- `lib/providers/ollama/provider.dart`
- `lib/providers/elevenlabs/provider.dart`

This is the biggest reason we cannot just move those provider classes into
`llm_dart_community`.

### 2. Root Compatibility Bridge Helpers Still Sit On The Critical Path

The root Ollama shell still depends on root-only bridge helpers such as:

- `LegacyChatCapabilityAdapter`
- `executeCompatChat(...)`
- `executeCompatChatStream(...)`
- `LegacyExtensionKeys`

The root ElevenLabs shell still depends on root compatibility error handling:

- `isCompatibilityError(...)`

These helpers are still part of the root compatibility story, not of the modern
community package.

### 3. Legacy Config Shaping And Factory Routing Are Still Root-Owned

The current factory path still flows through root compatibility types:

- `LLMConfig`
- `BaseProviderFactory`
- `LocalProviderFactory`
- `ProviderDefaults`

The actual adaptation still reads legacy config extensions through root-owned
compatibility accessors:

- `legacyJsonSchema`
- `getExtension(...)`
- `legacyTransportClient`
- `legacyCustomDio`

Evidence:

- `lib/providers/factories/ollama_factory.dart`
- `lib/providers/factories/elevenlabs_factory.dart`
- `lib/src/compatibility/providers/community_provider_config_adapters.dart`

This means the builder-era migration path is still structurally attached to the
root package even though the modern models are not.

### 4. Residual Provider-Shaped APIs Still Live In Root Provider Modules

The remaining provider-shaped surfaces still live under the root provider
directories:

Ollama residual modules:

- `lib/providers/ollama/chat.dart`
- `lib/providers/ollama/completion.dart`
- `lib/providers/ollama/models.dart`

ElevenLabs residual modules:

- `lib/providers/elevenlabs/audio.dart`
- `lib/providers/elevenlabs/models.dart`

These are not missing shared-capability migrations.
They are the provider-specific or compatibility-era residual shells that still
serve the old root interfaces.

## What Should Not Happen

The repository should still avoid these moves:

1. Do not move root `OllamaProvider` or `ElevenLabsProvider` wholesale into
   `llm_dart_community`.
2. Do not make `llm_dart_community` depend on root compatibility types just to
   host broader shells.
3. Do not widen the shared modern core to absorb model listing, legacy
   completion, voice catalog, realtime, or admin APIs.
4. Do not treat root builder compatibility as proof that the modern package
   boundary is wrong.

## Recommended Refactor Sequence

### Step 1. Freeze The Root Shells As Explicit Compatibility Adapters

Treat the current root Ollama and ElevenLabs shells as:

- migration-era adapters above package-owned modern models
- homes for compatibility interfaces and residual provider-specific APIs
- not the long-term primary implementation location for shared-capability code

### Step 2. Extract Shell-Only Helpers Toward Root Compatibility Modules

Move shell-only bridging and config-adaptation logic farther away from provider
implementation directories and closer to the root compatibility layer.

That means the long-term target is not:

- `lib/providers/ollama/provider.dart` owning both modern delegation and legacy
  shell shaping forever

It is:

- provider-owned modern models in `llm_dart_community`
- root-owned compatibility adapters in the root compatibility layer

### Step 3. Keep Residual APIs Explicitly Residual

Do not try to "finish" community-provider migration by absorbing every provider
HTTP endpoint into the modern package.

Residual APIs should either:

- stay in root compatibility shells
- become narrowly-scoped provider-owned typed helpers later if a concrete
  product need appears

### Step 4. Re-Evaluate Only Narrow Modern Additions

After the shell/config/factory coupling is thinner, only then re-evaluate
whether any additional provider-owned modern helper belongs in
`llm_dart_community`.

That decision should be driven by actual shared-capability or product use, not
by package symmetry alone.

## Exit Criteria

The community-provider decoupling step should be considered structurally healthy
when:

- `llm_dart_community` remains root-free
- root builder/factory compatibility no longer dictates modern package design
- root provider shells are clearly shell-shaped rather than mixed ownership
- residual provider APIs stay explicit instead of silently widening the shared
  modern surface

At that point, additional code moves can happen safely without confusing the
architecture again.
