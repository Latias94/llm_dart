# Modern Unified Interface

## Why This Workstream Exists

The provider and AI runtime split created healthier package ownership, but the
public API still needs one product-level pass before it is ready to be treated
as the recommended modern surface.

The library should keep the strengths that made the previous unified builder
useful:

- one way to write app-level generation code across providers
- a simple migration path for users who choose providers dynamically
- a single place for common request concerns such as headers, timeout,
  cancellation, provider options, transport, and diagnostics

At the same time, the modern surface should not return to the v0.10-style large
builder that coupled provider configuration, request execution, capability
detection, and legacy compatibility in one object.

## Goal

Make the modern API feel unified at the model and task layer while preserving
provider-owned product value.

The preferred direction is:

- provider packages expose focused facades such as `openai(...).chatModel(...)`
  and `google(...).embeddingModel(...)`
- `llm_dart_provider` owns provider-agnostic model contracts and lightweight
  selection primitives
- `llm_dart_ai` owns high-level task functions and orchestration
- provider-specific settings and per-call options stay typed instead of being
  flattened into loosely typed maps
- legacy builders remain available only through explicit compatibility imports

## Scope

This workstream should:

- define the recommended modern unified interface
- document gaps between the current API and that target
- add a provider-agnostic `ModelRegistry` for dynamic model selection
- align request options with the current `CallOptions`, `TransportClient`, and
  typed provider option design
- audit stream events, structured output, and serialization boundaries for
  modern app usage
- update examples and docs to teach the modern surface first

## Non-Goals

This workstream should not:

- make the root package a new monolithic implementation host
- reintroduce v0.10 `LLMBuilder` as the recommended API
- force provider-native files, moderation, voices, catalogs, or lifecycle
  helpers into common model interfaces
- require every provider package to support every model kind
- hide provider-specific settings behind untyped JSON maps

## Success Criteria

The workstream is complete only when:

- users can choose a model dynamically through a provider-agnostic registry
- recommended examples show model-first APIs before compatibility builders
- common request concerns are consistently available across modern model calls
- provider-specific options remain typed and discoverable
- unsupported providers or model kinds fail with clear errors
- stream and structured output gaps are either closed or tracked with migration
  notes
- legacy imports are explicitly framed as migration compatibility

## Documents

- [TODO.md](TODO.md)
  - Executable checklist for the workstream.
- [01-interface-gap-audit.md](01-interface-gap-audit.md)
  - Current gaps between the modern API and the desired unified surface.
- [02-model-registry-design.md](02-model-registry-design.md)
  - Design notes for provider-agnostic dynamic model selection.
- [03-stream-event-and-custom-part-audit.md](03-stream-event-and-custom-part-audit.md)
  - Release audit for stream events, UI chunks, and provider-native custom
    parts.
