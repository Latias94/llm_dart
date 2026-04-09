# 136. OpenAI Public Compatibility API Policy

## Question

After the OpenAI shell relocation, module relocation, and provider-barrel
narrowing, which remaining root OpenAI public APIs should still stay visible as
intentional compatibility surfaces, and which helper constructors should now be
treated as deprecated convenience aliases?

## What Was Reviewed

- `lib/providers/openai/config.dart`
- `lib/providers/openai/builder.dart`
- `lib/providers/openai/openai.dart`
- `lib/src/facade/ai.dart`
- `packages/llm_dart_openai/lib/src/openai.dart`
- `packages/llm_dart_openai/lib/src/openai_family_profile.dart`
- `docs/workstreams/2026-03-architecture-refactor/33-legacy-factory-entrypoint-deprecations.md`
- `docs/workstreams/2026-03-architecture-refactor/130-openai-residual-api-classification.md`

## Decision

### Keep public, compatibility-only, and not newly deprecated yet

- `OpenAIConfig`
- `OpenAIBuilder`
- `createOpenAIProvider(...)`
- `buildOpenAIResponses()`
- `OpenAIProvider.responses`
- `OpenAIResponsesCapability`
- `OpenAIBuiltInTools`

### Deprecate now as preset helpers over the same compatibility surface

- `createAzureOpenAIProvider(...)`
- `createCopilotProvider(...)`
- `createTogetherProvider(...)`

## Why `OpenAIConfig` And `OpenAIBuilder` Still Stay Public

They are not part of the stable target architecture, but they are still
honest public compatibility types.

The root package still hosts residual OpenAI APIs that the stable model-first
surface does not replace directly:

- raw Responses lifecycle helpers
- file management
- moderation
- assistants
- legacy completion
- compatibility-era image and audio entry paths

As long as that residual root provider surface still exists, callers may still
need:

- a typed root config object
- a typed root builder DSL
- a base root compatibility constructor

So keeping these public is more honest than pretending the legacy root surface
is already gone.

## Why The Three Preset Helpers No Longer Earn Special Status

These three helpers do not define unique architecture boundaries.

They only pre-fill:

- `baseUrl`
- `model`
- or endpoint-style URL shaping

before returning the same old `OpenAIProvider` compatibility surface.

That makes them structurally different from:

- `createOpenAIProvider(...)`, which is the single honest base constructor for
  the root compatibility host
- `buildOpenAIResponses()`, which still exposes a real OpenAI-specific residual
  surface that the stable `AI` facade does not replace directly

## Why This Is Especially Important For Azure

There is still no dedicated modern Azure profile in `llm_dart_openai`.

That means `createAzureOpenAIProvider(...)` should not be read as a long-term
commitment to a dedicated Azure architecture boundary in the root package.

Today it is only a convenience helper over the same compatibility-era
OpenAI-style client/config path.

So deprecating it is the right signal:

- it may still be usable for migration code
- but it should not be taught as a stable architectural entrypoint

## Migration Guidance

### If callers only need migrated text-generation behavior

Prefer:

- `AI.openai(...).chatModel(...)`

with explicit `baseUrl` when the target service is simply OpenAI-compatible.

### If callers still need the old root OpenAI provider surface

Prefer:

- `createOpenAIProvider(...)`

with explicit `baseUrl` and `model`

instead of preserving more preset aliases.

### If callers still need raw OpenAI Responses lifecycle helpers

Keep using:

- `buildOpenAIResponses()`
- `provider.responses`

until there is a real replacement for that residual surface.

## Practical Result

This policy keeps the remaining root OpenAI public API honest:

- the truly needed compatibility types stay public
- the preset aliases that only hide `baseUrl` and `model` start warning callers
- the stable modern OpenAI story stays centered on the provider package and the
  `AI` facade instead of re-expanding the root compatibility layer
