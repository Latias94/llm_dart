# Community Provider Migration Boundary

## Goal

Define how `llm_dart_community` should start carrying real provider weight
without breaking the frozen dependency direction or reintroducing root-package
coupling through a back door.

This note focuses on the first two community providers already identified in the
workstream:

- Ollama
- ElevenLabs

## Problem

The repository already created `llm_dart_community`, but the package is still
an empty barrel while the actual Ollama and ElevenLabs implementations continue
to live under the root package.

At first glance, the obvious next move seems to be:

- move `lib/providers/ollama/**` into `packages/llm_dart_community`
- move `lib/providers/elevenlabs/**` into `packages/llm_dart_community`
- re-export them from the root package

But the current provider code is not yet isolated enough for that move.

## Current Coupling Reality

### Ollama currently depends on root compatibility surfaces

The Ollama implementation imports root-local modules such as:

- `../../core/capability.dart`
- `../../core/config.dart`
- `../../core/llm_error.dart`
- `../../core/cancellation.dart`
- `../../models/chat_models.dart`
- `../../models/tool_models.dart`
- `../../builder/llm_builder.dart`
- `../../src/config/legacy_config_extensions.dart`
- `../../utils/http_response_handler.dart`

That means the current Ollama code is still rooted in the legacy compatibility
surface, not only in lower-layer package APIs.

### ElevenLabs currently depends on root compatibility surfaces

The ElevenLabs implementation imports root-local modules such as:

- `../../core/capability.dart`
- `../../core/config.dart`
- `../../core/llm_error.dart`
- `../../core/cancellation.dart`
- `../../models/chat_models.dart`
- `../../models/tool_models.dart`
- `../../models/audio_models.dart`
- `../../builder/llm_builder.dart`
- `../../src/config/legacy_config_keys.dart`
- `../../src/config/legacy_config_extensions.dart`

It is in the same situation: package move is blocked by root-local
compatibility ownership.

## Why A Naive Move Would Be Wrong

If these provider directories were moved as-is, one of two bad things would
happen:

### Option 1. `llm_dart_community` Depends On Root `llm_dart`

That would invert the intended package direction:

- lower provider package depending on the root facade

This is architecturally unacceptable.

### Option 2. `llm_dart_community` Reimplements Broad Compatibility Types

That would duplicate:

- old capability interfaces
- legacy config shaping
- builder hooks
- root-local utility behavior

This would reduce clarity, not improve it.

## Decision

`llm_dart_community` must become a real package in a staged way, not through a
wholesale file move.

### 1. `llm_dart_community` Must Not Depend On Root Compatibility Code

The community package may depend on:

- `llm_dart_core`
- `llm_dart_transport`

It must not depend on:

- root `llm_dart`
- root compatibility builders
- root legacy capability interfaces as an implementation dependency

### 2. Root `legacy.dart` Still Owns Compatibility-Era Community Provider APIs

As long as Ollama and ElevenLabs remain compatibility-oriented providers, the
root package should continue owning:

- `ai().ollama(...)`
- `ai().elevenlabs(...)`
- builder-specific provider configuration hooks
- legacy provider factories
- broad compatibility exports through `legacy.dart`

That keeps compatibility expectations in one place.

### 3. The First Community Move Should Target Provider-Owned Pieces, Not Builder DSL

The first code moved into `llm_dart_community` should be provider-owned logic
that can truthfully depend only on lower layers, such as future package-owned:

- config/codec/client modules that no longer read root compatibility types
- provider-specific typed option surfaces
- future modern model factories if Ollama or ElevenLabs gain stable migrated
  APIs

Builder DSL and root compatibility routing should stay in the root package until
they can be removed or replaced cleanly.

### 4. Community Migration Needs Dependency Cleanup Before File Relocation

The blocking imports show what must be addressed first:

- root-local config and extension shaping
- root-local capability and legacy message models
- root-local response/error helpers and builder hooks

One transport-ish helper has already moved in the right direction:

- the shared Dio cancellation adapter now lives in `llm_dart_transport`

The remaining blocking utility work is therefore narrower than it was when this
boundary was first frozen:

- `HttpResponseHandler` as a root error-mapping wrapper
- compatibility config shaping around `legacy_config_extensions` and
  builder-era root config adaptation
- builder-era compatibility hooks such as `LLMBuilder` and legacy config keys

The shared configurable Dio setup path has also now moved in the right
direction:

- `llm_dart_transport` now owns reusable configurable Dio setup through
  transport-side config and factory helpers
- root `HttpConfigUtils` is now only a compatibility mapper from `LLMConfig`
  into that transport-owned layer
- provider `dio_strategy.dart` files and provider clients now also use
  transport-owned provider-Dio abstractions directly instead of depending on a
  root-local Dio utility implementation
- Ollama and ElevenLabs now also use provider-owned local defaults instead of
  importing root `provider_defaults.dart`
- the shared `Utf8StreamDecoder` now also lives in `llm_dart_transport`, with
  the old root utility path reduced to a compatibility re-export
- shared log sanitization and JSON-object response decoding primitives now also
  live in `llm_dart_transport`, so the root `HttpResponseHandler` is narrower
  than before even though it still owns legacy `LLMError` mapping
- Ollama and ElevenLabs configs now also own provider-side `dioOverrides`
  data directly instead of mixing in root `LegacyDioClientOverrides`

Until those are either extracted, replaced, or intentionally left behind in the
root compatibility shell, the package move remains premature.

## Recommended Migration Order

### Phase A. Freeze The Boundary

- treat Ollama and ElevenLabs as compatibility-oriented providers in docs and
  public guidance
- explicitly forbid `llm_dart_community -> llm_dart` dependency direction

### Phase B. Prepare Provider-Owned Lower-Layer Building Blocks

- move or replace any shared helper that truly belongs in `core` or `transport`
- keep builder hooks and legacy factories in the root package
- avoid moving broad compatibility interfaces into `llm_dart_community`

### Phase C. Land The First Real Community-Owned Public Surface

Use one of these as the first real package-owned slice:

- a modern Ollama model API
- a modern ElevenLabs speech API
- a provider-owned config/client/codec module set that no longer imports root
  compatibility types

Only after one of those exists should `llm_dart_community` stop being an empty
barrel.

## Non-Goals

This note does not recommend:

- moving the current Ollama and ElevenLabs directories into
  `llm_dart_community` unchanged
- making `llm_dart_community` depend on the root package
- copying all root compatibility builders into the community package
- pretending Ollama or ElevenLabs already have a stable `AI.*` facade when they
  do not

## Status

The correct next step is not a blind file move.

The correct next step is:

- keep `llm_dart_community` aligned with one-way dependency rules
- use it as the future home for provider-owned community surfaces
- keep current compatibility-era Ollama and ElevenLabs behavior rooted in
  `legacy.dart` until their provider code is actually decoupled from the root
  compatibility layer
