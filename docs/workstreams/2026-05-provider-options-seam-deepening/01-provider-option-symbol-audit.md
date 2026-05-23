# POS-010 Provider Option Symbol Audit

Audit date: 2026-05-23.

## Scope

This audit inventories the current public symbol surface in
`packages/llm_dart_provider/lib/src/common/provider_options.dart` and
classifies each symbol by ownership.

## Findings

### Bag Transport

Current symbols:

- `ProviderOptionsBag`
- `ProviderInvocationOptionsBundle`
- `providerInvocationOptions(...)`
- `providerOptionsBagFromInvocationOptions(...)`
- `typedProviderOptionsFromInvocationOptions(...)`
- `providerOptionsNamespaceFromInvocationOptions(...)`

Ownership:

- transport and bundle glue
- stable public provider contract today
- shallow implementation hotspot because JSON bag handling and typed bundle
  projection are mixed into the same module

### Typed Invocation

Current symbols:

- `ProviderModelOptions`
- `ProviderInvocationOptions`
- `ProviderInvocationOptionsBagProjection`
- `resolveProviderModelOptions(...)`
- `resolveProviderInvocationOptions(...)`

Ownership:

- typed invocation contract and typed resolution helpers
- public provider contract today
- should remain public, but can live in a smaller internal module than the bag
  transport helpers

### Prompt-Part Replay

Current symbols:

- `ProviderPromptPartOptions`
- `ProviderReplayPromptPartOptions`
- `ProviderReplayPromptPartOptionsJsonCodec`
- `providerReplayMetadataFromOptions(...)`
- `ProviderPromptPartOptionsJsonCodec`
- `resolveProviderPromptPartOptions(...)`

Ownership:

- prompt-part input-side options and replay-specific input wrapper
- provider-owned replay metadata projection
- separate seam from bag transport and tool options

### Tool Options

Current symbols:

- `ProviderToolOptions`
- `ProviderToolOptionsJsonCodec`
- `resolveProviderToolOptions(...)`

Ownership:

- tool-definition input-side options
- separate seam from prompt-part replay and invocation bundle helpers

### Internal JSON Support

Current symbols:

- `_providerNamespaceKeyPattern`
- `_expectedProviderOptionMessage(...)`
- `_validateProviderOptionsBagMap(...)`
- `_validateProviderNamespaceKey(...)`
- `_deepMergeProviderJsonMaps(...)`
- `_freezeProviderJsonValue(...)`
- `_freezeProviderJsonMap(...)`
- `_deepProviderJsonEquals(...)`
- `_deepProviderJsonHash(...)`

Ownership:

- internal JSON validation and deep support for bag transport
- should stay hidden behind the bag transport module

## Recommended Split Order

1. Bag transport and JSON helpers
2. Typed invocation helpers
3. Prompt-part replay helpers
4. Tool option helpers

## Deletion Test

Deleting the current module would not remove complexity. The complexity would
reappear across provider call sites, prompt serialization, tool handling, and
replay code. That means the module is earning its keep, but the implementation
is still shallow enough to justify a deeper split.
