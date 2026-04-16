# Deprecated Preset Helper Aliases

## Goal

Document the already-deprecated preset helper aliases that still exist on the
compatibility surface, grouped by provider family, with an honest replacement
path for each group.

## Why These Aliases Are First-Wave Candidates

These helpers are leaf ergonomics, not foundational migration rails.

They all do some version of:

- pick a preset model ID
- prefill a few provider defaults
- return the older root-package provider type

That makes them much easier to remove than:

- `legacy.dart`
- `ai()`
- `LLMBuilder`
- root provider constructors such as `createGoogleProvider(...)`

The deprecation/removal sequence should therefore stay:

1. remove narrow preset aliases first
2. keep broad compatibility trunks longer
3. only remove a broader trunk after migration notes and examples are good

## Replacement Rules

Across families, the replacement rule is:

- prefer the stable `AI.<provider>(...).<model>()` surfaces for app-facing code
- keep provider-specific behavior on provider-owned typed options/settings
- fall back to the non-deprecated root provider constructor only when the user
  still needs the old root-package provider surface
- do not pretend that every preset helper has a full shared modern equivalent

## Provider Families

### OpenAI-family compatibility aliases

Defined in `lib/providers/openai/openai.dart`.

Deprecated helpers:

- `createOpenRouterProvider(...)`
- `createGroqProvider(...)`
- `createDeepSeekProvider(...)`
- `createAzureOpenAIProvider(...)`
- `createCopilotProvider(...)`
- `createTogetherProvider(...)`

Stable-first replacement:

- `AI.openRouter(...).chatModel(...)`
- `AI.groq(...).chatModel(...)`
- `AI.deepSeek(...).chatModel(...)`
- `AI.openai(...).chatModel(...)` when the deployment is still fundamentally
  an OpenAI-compatible endpoint

Compatibility fallback:

- `createOpenAIProvider(..., baseUrl: ..., model: ...)`

Notes:

- These helpers are compatibility aliases over the OpenAI-compatible transport,
  not distinct long-term provider contracts.
- `legacy.dart` already hides the compatibility aliases for DeepSeek and Groq,
  because those providers have their own dedicated non-deprecated roots.
- Removal here should happen before any broader decision about the OpenAI
  compatibility host itself.

### Google preset aliases

Defined in `lib/providers/google/google.dart`.

Deprecated helpers:

- `createGoogleChatProvider(...)`
- `createGoogleReasoningProvider(...)`
- `createGoogleVisionProvider(...)`

Stable-first replacement:

- `AI.google(...).chatModel(...)`

Compatibility fallback:

- `createGoogleProvider(...)`

Notes:

- The non-deprecated Google roots for image generation and embeddings
  (`createGoogleImageGenerationProvider(...)`,
  `createGoogleEmbeddingProvider(...)`) are not part of this deprecation group.
- "Reasoning" and "vision" here are preset choices, not a stable separate API
  family.

### Anthropic preset aliases

Defined in `lib/providers/anthropic/anthropic.dart`.

Deprecated helpers:

- `createAnthropicChatProvider(...)`
- `createAnthropicReasoningProvider(...)`

Stable-first replacement:

- `AI.anthropic(...).chatModel(...)`

Compatibility fallback:

- `createAnthropicProvider(...)`

Notes:

- The helper names mostly encode preset model intent, not a separate wire
  contract.
- This family is a straightforward leaf-removal candidate once release timing
  is chosen.

### Groq preset aliases

Defined in `lib/providers/groq/groq.dart`.

Deprecated helpers:

- `createGroqChatProvider(...)`
- `createGroqFastProvider(...)`
- `createGroqVisionProvider(...)`
- `createGroqCodeProvider(...)`

Stable-first replacement:

- `AI.groq(...).chatModel(...)`

Compatibility fallback:

- `createGroqProvider(...)`

Notes:

- "Fast", "vision", and "code" are preset-model conveniences, not stable
  product layers.
- This is one of the clearest groups where the leaf aliases should disappear
  before the root constructor does.

### DeepSeek preset aliases

Defined in `lib/providers/deepseek/deepseek.dart`.

Deprecated helpers:

- `createDeepSeekChatProvider(...)`
- `createDeepSeekReasoningProvider(...)`

Stable-first replacement:

- `AI.deepSeek(...).chatModel(...)`

Compatibility fallback:

- `createDeepSeekProvider(...)`

Notes:

- This family matches the Groq/Anthropic posture: model presets are the leaf
  removal target, not the provider root.

### Ollama preset aliases

Defined in `lib/providers/ollama/ollama.dart`.

Deprecated helpers:

- `createOllamaChatProvider(...)`
- `createOllamaVisionProvider(...)`
- `createOllamaCodeProvider(...)`
- `createOllamaEmbeddingProvider(...)`
- `createOllamaCompletionProvider(...)`
- `createOllamaReasoningProvider(...)`

Stable-first replacement:

- `Ollama(...).chatModel(...)` from `package:llm_dart_community/...` for
  modern chat flows
- `Ollama(...).embeddingModel(...)` from `package:llm_dart_community/...` for
  embeddings

Compatibility fallback:

- `createOllamaProvider(...)`

Important limits:

- There is no shared modern `CompletionModel` path today, so
  `createOllamaCompletionProvider(...)` does not have a full stable shared
  replacement.
- "Vision" and "reasoning" can sometimes migrate to the modern chat surface
  when they are just model/prompt choices, but that is not guaranteed to be a
  full semantic replacement.
- The migration note must stay honest here; some users should remain on the
  provider-owned compatibility surface for now.

### xAI preset aliases

Defined in `lib/providers/xai/xai.dart`.

Deprecated helpers:

- `createXAISearchProvider(...)`
- `createXAILiveSearchProvider(...)`
- `createGrokVisionProvider(...)`

Stable-first replacement:

- `AI.xai(...).chatModel(...)`
- `XAIGenerateTextOptions(search: ...)` for native search behavior

Compatibility fallback:

- `createXAIProvider(...)`

Notes:

- Search is provider-owned runtime behavior, not a repository-wide shared
  boolean.
- The xAI preset helpers should migrate to the stable chat facade plus typed
  search options, not to a fake generic "search provider" abstraction.

### Phind preset aliases

Defined in `lib/providers/phind/phind.dart`.

Deprecated helpers:

- `createPhindCodeProvider(...)`
- `createPhindExplainerProvider(...)`

Stable-first replacement:

- No dedicated modern stable facade exists beyond the provider-owned surface.

Compatibility fallback:

- `createPhindProvider(...)`

Notes:

- This is still a good leaf-removal group because the preset helpers are not
  meaningfully more stable than the provider root itself.
- The migration note should point users to the provider root, not invent a
  shared abstraction that does not exist.

### ElevenLabs preset aliases

Defined in `lib/providers/elevenlabs/elevenlabs.dart`.

Deprecated helpers:

- `createElevenLabsTTSProvider(...)`
- `createElevenLabsSTTProvider(...)`
- `createElevenLabsCustomVoiceProvider(...)`
- `createElevenLabsStreamingProvider(...)`

Stable-first replacement:

- `ElevenLabs(...).speechModel(...)` from `package:llm_dart_community/...`
- `ElevenLabs(...).transcriptionModel(...)` from
  `package:llm_dart_community/...`

Compatibility fallback:

- `createElevenLabsProvider(...)`

Important limits:

- Realtime/streaming behavior does not yet have a shared stable modern
  replacement.
- Voice catalogs, custom voices, and transport-specific streaming details stay
  provider-owned even when the basic speech/STT flows can move to the modern
  community package.

## Practical Removal Posture

This document closes the "what are the deprecated preset aliases and what is
their honest replacement?" blocker.

It does not mean they should be removed immediately.

What it does mean:

- they should stay deprecated
- docs/examples should stop teaching them
- changelog entries can link to this document family-by-family
- they are valid first deliberate breaking-window candidates
