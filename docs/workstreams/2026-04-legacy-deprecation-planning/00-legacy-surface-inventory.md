# Legacy Surface Inventory

## Goal

Classify the remaining legacy-facing public surface by actual migration value,
modern replacement clarity, and removal readiness.

This document is intentionally about public posture, not about internal file
count.

## Classification Summary

### 1. Keep As The Explicit Compatibility Host For Now

These surfaces are still the main migration rail for existing root-package
users and should remain available until a more complete migration story exists:

| Surface group | Examples | Current role | Current decision |
| --- | --- | --- | --- |
| Legacy root barrel | `package:llm_dart/legacy.dart` | Single explicit import for compatibility-oriented code | Keep |
| Root compatibility provider constructors | `createOpenAIProvider`, `createGoogleProvider`, `createAnthropicProvider`, `createOllamaProvider`, `createElevenLabsProvider` | Broad migration host for old root provider flows | Keep |
| Compatibility adapters and bootstrap glue | `ensureRootRegistryBootstrap`, legacy config adapters, registry/factory routing | Required by builder-era and legacy root flows | Keep |
| Compatibility provider barrels | `providers/openai/openai.dart`, `providers/google/google.dart`, similar root provider barrels | Public compatibility-owned entrypoints while modern package-owned entrypoints take over new usage | Keep |

Rationale:

- these are the trunk-level migration rails
- they still absorb meaningful compatibility behavior
- deleting them before the migration guide is complete would push users into
  piecemeal breakage instead of a deliberate migration path

### 2. Already Soft-Deprecated Or Ready For A Removal Window

These surfaces already have a truthful modern replacement story and should be
treated as the first removal candidates in the next deliberate breaking window:

| Surface group | Examples | Replacement direction | Current decision |
| --- | --- | --- | --- |
| Legacy builder alias | `ai()` | Stable `AI.<provider>(...)` for new code, or explicit `LLMBuilder()` for compatibility builder code | Soft-deprecated now |
| Preset helper aliases | `createGoogleChatProvider`, `createOpenRouterProvider`, `createOllamaVisionProvider`, `createGroqFastProvider` | Modern `AI.<provider>(...).<model/api>(...)` or explicit root base constructor | Soft-deprecated now |
| Builder web-search helpers | `LLMBuilder.enableWebSearch`, `webSearch`, `quickWebSearch`, `newsSearch`, `searchLocation`, `advancedWebSearch` | Typed provider options or provider-native model settings | Soft-deprecated now |
| Deprecated compatibility escape hatches | `createProvider(..., extensions: ...)`, root cancellation alias guidance | Typed provider options or transport-owned types | Soft-deprecated now |

Rationale:

- these are leaf-level convenience wrappers
- their replacement path is already understandable
- they do not deserve indefinite support just because the broader compatibility
  rail still exists

### 3. Freeze, But Do Not Deprecate Yet

These surfaces are still compatibility-first and should not be the default
recommendation, but they are not yet ready for broad deprecation:

| Surface group | Examples | Why not deprecate yet? | Current decision |
| --- | --- | --- | --- |
| Builder trunk | `LLMBuilder` | Still the broadest migration rail for old fluent root usage even after the `ai()` alias deprecates | Freeze |
| Builder config shells | `HttpConfig`, `ImageConfig`, `ProviderConfig` | Still coupled to the builder migration rail; deprecating them before the builder decision would create half-migrations | Freeze |
| Root generic factory paths | `createProvider(...)`, `providers/factories/*`, root registry helpers | Still used to resolve builder-era provider selection and compatibility routing | Freeze |
| Provider root constructors with broad parameter coverage | `createGoogleProvider`, `createOpenAIProvider`, similar non-preset constructors | Still the simplest bridge for old root users who are not ready to adopt package-owned model APIs directly | Freeze |

Rationale:

- these surfaces are not modern-first
- but they still carry migration weight that smaller aliases do not
- deprecating them before publishing task-oriented migration guidance would be
  a policy mistake
- `AudioConfig` is no longer part of this frozen shell; audio now uses shared
  request fields plus provider-owned typed options instead of an unconsumed
  legacy map builder

### 4. Do Not Deprecate As Part Of This Phase

These surfaces should not be treated as legacy debt just because they are
currently reachable from a broad root package:

| Surface group | Examples | Reason |
| --- | --- | --- |
| Modern root entrypoints | `ai.dart`, `openai.dart`, `google.dart`, `anthropic.dart`, `chat.dart`, `core.dart`, `transport.dart` | These are the intended stable surface |
| Provider-owned typed APIs | package-owned model constructors, typed provider settings, capability profiles | These are the long-term direction |
| Narrow utilities with independent value | `ToolCallAggregator`, transport primitives, capability descriptors | Their usefulness is not inherently tied to legacy builder usage |

The deprecation target here is the compatibility routing story, not every
symbol that happens to be re-exported by a compatibility barrel.

## Inventory Implications

The repository should now treat legacy public surface in three layers:

1. Compatibility trunks that stay until migration guidance is complete.
2. Convenience leaves that can be removed first.
3. Modern stable surfaces that should gain more documentation instead of
   deprecation.

That sequencing matters.

If the repository deprecates the trunk before the leaves, users lose the only
coherent migration rail while a large number of small compatibility aliases
still remain.
