# Community Provider Capability Confidence Guidance

## Goal

Record how the newer model-centric capability profile system should be
interpreted for `llm_dart_community` now that selective community-provider
adoption has landed.

This note does **not** reopen the closed architecture phase.

It narrows one app-facing documentation gap:

> when a Flutter or app-facing integration reads a capability profile from an
> Ollama or ElevenLabs model, which answers are strong enough to drive UI
> affordances directly, and which answers should be treated as family-level
> hints only?

## What Landed

The modern community package now has:

- provider-owned describers:
  - `describeOllamaChatModel(...)`
  - `describeOllamaEmbeddingModel(...)`
  - `describeElevenLabsSpeechModel(...)`
  - `describeElevenLabsTranscriptionModel(...)`
- direct `capabilityProfile` exposure on:
  - `OllamaLanguageModel`
  - `OllamaEmbeddingModel`
  - `ElevenLabsSpeechModel`
  - `ElevenLabsTranscriptionModel`
- app-facing examples that now include a community-provider capability preset

That means `llm_dart_community` is no longer outside the capability-discovery
story.

It is now part of the same additive model-centric pattern as the major hosted
provider packages.

## Why Confidence Differs Across Community Providers

The confidence model matters more for community providers than for the hosted
OpenAI, Google, and Anthropic paths.

### ElevenLabs

The current modern ElevenLabs surfaces are narrower and map onto hosted APIs
with more stable request semantics:

- speech generation
- byte-oriented transcription

That makes the current shared capability answers comparatively strong.

### Ollama

The modern Ollama path is different:

- the local model catalog is user-chosen
- model IDs often encode family hints rather than a stable hosted contract
- vision and reasoning behavior varies by pulled model family
- tool behavior is intentionally narrower than the richer hosted-provider
  tool-selection contracts

So the library should stay honest:

- keep the shared Ollama baseline small and known where possible
- mark family-shaped extras as `inferred` rather than pretending they are
  guaranteed

## Current Confidence Posture

### Ollama Chat

Treat these as the current **known** baseline:

- `language.streaming`
- `language.input.text`
- `language.output.structured`
- provider route `api.route = chat`
- provider feature `ollama.toolSelection` only as a description of the current
  automatic-only posture, not as evidence of richer tool-choice support

Treat these as current **inferred** family hints:

- `language.tool.function`
- `language.input.image` for vision-like model families
- `language.output.reasoning` for thinking/reasoning-like model families
- provider features such as `ollama.imageInputs` and `ollama.thinking`

Treat these as intentionally **not exposed** on the current shared surface:

- `language.tool.choice`
- `language.input.file`
- stronger route-level guarantees for every local Ollama model family

### Ollama Embeddings

Treat these as **known**:

- `embedding.batch`
- provider route `api.route = embed`

Treat this as intentionally **not exposed**:

- `embedding.dimensions`

### ElevenLabs Speech

Treat these as **known**:

- `speech.output.format`
- `speech.voice.selection`
- provider route `api.route = text_to_speech`
- the documented speech-option descriptor surface

### ElevenLabs Transcription

Treat these as **known**:

- `transcription.languageHints`
- `transcription.timestamps`
- provider route `api.route = speech_to_text`
- diarization and speaker-range descriptors

## App And Flutter Guidance

### 1. Use Shared Features For Affordance Gating

Shared feature IDs are still the right first pass for:

- enabling or disabling attach-image buttons
- showing reasoning panels
- showing source panels
- selecting fallback models

### 2. Check Confidence Before Treating A Community Answer As Hard Support

For community providers, app code should inspect the descriptor confidence when
the UI wants to communicate certainty.

Example:

```dart
import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

final profile = describeOllamaChatModel('llama3.2-vision');
final imageInput = profile.sharedFeature(
  ModelCapabilityFeatureIds.languageImageInput,
);

final canShowImageButton = imageInput != null;
final shouldShowInferenceBadge =
    imageInput?.confidence == CapabilityConfidence.inferred;
```

That is the right shape for community-provider UX:

- show the affordance when the library has a credible hint
- optionally show an "inferred" badge or softer copy
- keep final validation in the real request path

### 3. Do Not Turn Inferred Community Hints Into Backend Assumptions

The transport or backend should not assume that an inferred community feature
is guaranteed simply because the UI turned a control on.

Provider codecs and actual requests still own:

- final validation
- warnings
- request rejection

### 4. Prefer App-Owned Allow-Lists For Product-Critical Flows

If one product flow depends on a community-model feature being correct every
time, app code should keep a local allow-list or runtime validation step
instead of relying only on model-family inference.

That is especially true for:

- local multimodal upload flows
- reasoning-panel expectations
- any workflow where missing support would break UX rather than only degrade it

## Why This Does Not Reopen Architecture

This landed work is additive and app-facing:

- it does not widen shared model contracts
- it does not add another package
- it does not move provider-native value into shared core
- it does not reopen the shared event model

It is exactly the kind of post-closure follow-up that the phase closure note
explicitly allowed:

- selective community-provider capability profile adoption only when it adds
  real user value

## Reopen Conditions

Revisit this confidence posture only if one of these becomes true:

1. Ollama gains a more stable typed catalog path that can replace family-name
   inference with stronger evidence.
2. Repeated app feedback shows that the current inferred hints are too noisy to
   be useful.
3. More community providers join the package and the confidence policy needs a
   shared helper or a clearer package-local taxonomy.
4. A product-facing Flutter pattern needs a stable confidence-to-badge helper
   above the current example-level guidance.

Until then, the correct default is:

- keep community capability discovery additive
- keep confidence explicit
- keep inferred answers descriptive rather than authoritative
