# Prompt Surface And Result Facade Freeze

## Why This Slice Exists

The previous slices in this workstream already removed the obvious legacy
couplings:

- root legacy implementation ownership is gone
- request-side `ProviderMetadata` no longer acts as ordinary prompt input
- replay metadata now flows through explicit typed replay paths

The remaining architectural risk is no longer the package graph. It is the
public story around the app-facing prompt surface and the structured-result
surface:

- docs and examples can still describe provider-facing prompts as if they were
  the default app path
- the structured-output API surface still has two overlapping result facades
- the long-term relationship between `generateTextCall` / `streamTextCall` and
  `generateObject` / `streamObject` is not yet frozen
- `CallOptions.providerOptions` still needs a final policy for typed
  discoverability and the raw escape hatch

This slice freezes those decisions so the library can move toward a stable
modern surface without losing provider-native flexibility.

## Goal

Freeze the app-facing prompt and structured-result surface for `llm_dart_ai`
while preserving provider-specific power.

The target outcome:

- `messages:` with `ModelMessage` is the default app-facing prompt path
- `prompt:` with `PromptMessage` remains an advanced provider-contract path
- prompt normalization and validation stay owned by `llm_dart_ai`
- provider codecs receive normalized provider prompts only
- `generateTextCall` / `streamTextCall` become the long-term combined text and
  structured-output result layer
- `generateObject` / `streamObject` remain thin convenience wrappers or
  migration helpers over `OutputSpec`
- `CallOptions.providerOptions` keeps typed provider discoverability with a
  documented raw escape hatch
- partial-output and element-stream behavior remain intact for structured
  streaming

## Provider Options Raw Escape Hatch Policy

The shared provider foundation should not add a generic untyped request map.
That would recreate the same ambiguity that request-side `ProviderMetadata`
created.

The raw escape hatch policy is:

- typed provider options are always the primary path
- provider packages may add provider-owned raw fields only when a provider API
  feature is too new or too narrow to model immediately
- raw fields must live on the concrete provider option type, not on
  `CallOptions` and not on `ProviderMetadata`
- raw fields must be scoped to one provider and one request family
- provider codecs own merge order, conflict detection, and validation for raw
  fields
- typed fields should win over raw values unless the provider-owned option
  documents a different precedence rule and emits warnings where needed
- raw fields must not be used for replay metadata; replay stays on
  `ProviderReplayPromptPartOptions` or provider-owned typed replay helpers

This keeps fast provider feature adoption possible without turning the shared
runtime surface into an untyped provider request builder.

## Reference Lessons From `repo-ref/ai`

The useful reference lessons are architectural, not literal API matches:

- model messages are the user-facing prompt layer
- provider-facing messages are a lower-level contract layer
- user helpers sit above provider specifications
- structured generation is a convenience layer built on top of text
  generation, not a separate ownership island
- provider options remain the input-side customization path, while metadata is
  output-side observation and replay data
- provider-native features stay provider-owned instead of being flattened into
  weak shared abstractions

## What To Preserve

The freeze must keep the Dart-specific strengths already in the library:

- unified model-first runtime helpers across providers
- typed provider model settings and invocation options
- provider-owned prompt part options for provider-specific input controls
- capability profiles for model-centric feature discovery
- provider-native helper clients for files, moderation, images, speech,
  transcription, voices, catalogs, and provider product APIs
- framework-neutral chat runtime and Flutter adapters that do not depend on
  concrete provider packages
- partial structured output, element streaming, and final result facades

## Success Criteria

This slice is complete only when:

- README and migration docs present `ModelMessage` as the default prompt
  surface
- `PromptMessage` is documented as advanced or provider-contract use
- `generateTextCall` / `streamTextCall` are the documented primary combined
  result path
- `generateObject` / `streamObject` are described as wrappers or migration
  helpers, not a separate long-term branch
- examples avoid provider-facing prompt construction in common app code
- provider codecs continue to reject unnormalized request data
- docs describe the provider-options raw escape hatch without blurring it with
  output metadata
