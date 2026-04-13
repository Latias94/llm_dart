# Provider UI Extension Contract

## Problem Statement

The shared UI model is now intentionally rich enough to represent:

- text
- reasoning
- files
- sources
- tool lifecycle
- provider-owned custom parts
- transient data parts

That means the remaining UI problem is no longer “which new shared event type do
we need?”.

The remaining UI problem is:

> how should applications compose the stable shared mapper with provider-owned
> custom parsing and richer provider metadata helpers?

## Current Observed Pattern

The current codebase already exposes a useful provider-owned pattern:

- OpenAI
  - `OpenAICustomPart`
  - `OpenAICustomPartSummary`
  - `OpenAIMessageMapper`
- Google
  - `GoogleCustomPart`
  - `GoogleCustomPartSummary`
  - `GoogleMessageMapper`

This is a healthy shape because it keeps:

- shared message and part models in the shared layer
- provider-specific JSON knowledge in the provider package
- optional richer mapping outside the shared Flutter/runtime layer

Anthropic does not currently need symmetry-only UI helpers. That is acceptable.

## Decision

The intended pattern for richer provider UI support should be:

1. keep `ChatUiMessage`, `ChatUiPart`, and `ChatMessageMapper` shared and
   provider-neutral
2. keep provider-specific parsing and summary helpers inside provider packages
3. allow provider packages to expose an optional provider-owned message mapper
   when common shared parts also carry meaningful provider metadata
4. keep app-specific composition in the application layer or a later additive
   helper layer

## Recommended Helper Layers

### Layer 1 - Shared Stable Rendering Baseline

This layer should remain the default baseline:

- `ChatUiMessage`
- `ChatUiPart`
- `ChatUiStreamChunk`
- `ChatMessageMapper`

This is what all apps should be able to rely on without knowing anything about
provider-specific replay payloads.

### Layer 2 - Provider-Owned Custom Part Parsing

Provider packages may expose parsing helpers like:

- `ProviderCustomPart.tryParsePromptPart(...)`
- `ProviderCustomPart.tryParseContentPart(...)`
- `ProviderCustomPart.tryParseUiPart(...)`
- `ProviderCustomPart.tryParseEvent(...)`

This is the correct place for provider-specific JSON interpretation.

### Layer 3 - Provider-Owned Render Summaries

Provider packages may expose summary helpers like:

- `ProviderCustomPartSummary.fromPart(...)`
- `ProviderCustomPartSummary.tryParseUiPart(...)`
- `ProviderCustomPartSummary.parseUiParts(...)`

This gives Flutter or server-side UI code a lightweight render path without
forcing the shared layer to understand provider-specific payloads.

### Layer 4 - Optional Provider-Owned Message Mapper

A provider package may also expose a provider-specific message mapper when:

- common shared parts carry meaningful provider metadata
- the UI frequently needs provider-specific inspection across many part kinds

This is why `GoogleMessageMapper` makes sense today.

## Event Completeness Implication

This contract also means the next UI phase should not widen the shared event
model by default.

Provider-specific rich rendering should continue to rely on existing carriers:

- `CustomUiPart`
- `ProviderMetadata`
- `DataUiPart`
- existing `TextStreamEvent` variants for shared lifecycle semantics

If a provider-specific payload is representable through those carriers, the
shared model should usually stay unchanged.

## Additive Registry Policy

If applications later prove that repeated composition is noisy, an additive
registry helper may be justified.

That registry should:

- live above the shared core model
- stay app-oriented instead of provider-owned global state
- dispatch through stable shared identifiers such as `CustomUiPart.kind` and
  namespaced `ProviderMetadata`
- avoid knowing provider-specific wire JSON schemas directly

Until at least two concrete application integrations show the same repeated
composition pain, that registry should remain deferred.

## Non-Goals

This contract should explicitly avoid:

- provider-specific widgets inside `llm_dart_flutter`
- provider-specific JSON parsing inside `llm_dart_core`
- forcing every provider to expose the same mapper/helper trio for symmetry
