# Repo-Ref Gap Rebaseline

## Goal

This note rechecks the current repository against the useful structural signals
from `repo-ref/ai` after the post-closure priority phase finished.

The goal is not to restart the old architecture debate.

The goal is to answer a narrower question:

> which remaining differences versus `repo-ref/ai` are still worth acting on
> now, and which should stay deliberate?

## Reference Signals From `repo-ref/ai`

The useful signals from the Vercel AI SDK are still the same:

- a clear split between app-facing functions, provider specifications, shared
  provider implementation utilities, and provider packages
- provider packages that do not depend back on the app-facing core package
- a productized streamed text orchestration layer above raw provider streams
- framework adapters that stay above the shared runtime rather than inside
  provider packages

Those signals matter because they clarify ownership, not because they define a
package count to mimic.

## Current `llm_dart` Shape

As of 2026-04-15, the current workspace graph is:

- `llm_dart_core`
  - no runtime package dependencies
- `llm_dart_transport`
  - depends on `llm_dart_core`, `dio`, and `logging`
- `llm_dart_chat`
  - depends on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_flutter`
  - depends on `flutter`, `llm_dart_chat`, and `llm_dart_core`
- provider packages
  - depend on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_community`
  - already owns modern Ollama and ElevenLabs shared-capability surfaces
- root `llm_dart`
  - depends on the package workspace as a facade and compatibility host

That means the package graph is already aligned with the most important lesson
from `repo-ref/ai`: dependency direction is one-way.

## What Is Already Well Aligned

### 1. Provider Ownership

Provider packages own provider-native request shaping, stream parsing, custom
parts, and typed provider options.

That is the important structural lesson from `repo-ref/ai`, even though the
Dart repository keeps fewer published packages.

### 2. Runtime Layering

The repository now has a clear runtime stack:

- `llm_dart_core` for shared models and runners
- `llm_dart_transport` for transport and protocol mechanics
- `llm_dart_chat` for session/runtime orchestration
- `llm_dart_flutter` for Flutter adapters

This is a healthy Dart-first equivalent of the reference repository’s
core/runtime/UI separation.

### 3. Event And UI Boundaries

The repository already froze the correct boundary:

- shared model streams stay in `TextStreamEvent`
- transport/session layers may add richer UI protocol chunks
- provider-specific rendering remains provider-owned

That means the remaining gap is not “missing event families.”

### 4. Community Provider Placement

The earlier concern that `llm_dart_community` might remain symbolic is no
longer true.

It already owns modern shared-capability surfaces for:

- Ollama chat and embeddings
- ElevenLabs speech and transcription

So this is no longer a top-priority structural gap.

## Real Remaining Gaps

### 1. `llm_dart_core` Is Still The Main Internal Concentration Point

`llm_dart_core` currently exports:

- model specifications
- common call and result primitives
- output and runner logic
- shared UI messages and mappers
- serialization codecs

That is not yet a broken package boundary, but it is the main remaining place
where several concerns still meet.

### Decision

Do not split this into new published packages yet.

Instead, the next phase should first:

- define internal sublayers
- document which exports belong to which sublayer
- record the threshold for a future package split

### Trigger For A Future Split

A future `provider` or `provider-utils` style split is only justified if at
least one of these becomes true:

- external provider packages outside this repository need a narrow stable spec
  package
- multiple packages need the same provider-implementation helpers but should
  not depend on the whole shared core
- `llm_dart_core` change pressure starts repeatedly coupling unrelated areas
  such as UI, serialization, and runners

### 2. Streamed Run Productization Is Still Narrower Than The Reference

`StreamTextRunner` already exists, which is good.

But it is still intentionally narrow:

- tool continuation only covers the shared common function-tool subset
- there is no shared pre-step mutation hook yet
- there is no shared retry or model-switching policy
- higher-level UI stream processing remains outside the runner

### Decision

This is the next highest-value structural gap to revisit.

Not because the repository lacks a runner, but because this is now the main
remaining place where `repo-ref/ai` is more productized above raw provider
streams.

### Constraint

The next phase should still avoid:

- pulling provider-executed continuation into shared core
- widening shared prompt/request models for approval-heavy providers
- turning `llm_dart_core` into a full agent runtime prematurely

### 3. The Root Package Is Still Transitional

The root package is now much healthier, but it still plays two roles:

- default modern facade
- compatibility host

This is acceptable, but it means future refactors should stay careful about
where new implementation weight lands.

### Decision

Keep slimming the root package only when a concrete feature or compatibility
move justifies it.

Do not chase “empty facade purity” before the remaining compatibility surface
has a real deprecation path.

## Differences That Should Stay Deliberate

The following differences versus `repo-ref/ai` should remain intentional:

- no package-count parity
- no separate published `provider-utils` package yet
- no shared renderer registry without repeated app pressure
- no shared React-style message-store mutation surface
- no full `ui-message-stream` parity in the shared event model

## Bottom Line

The current repository is already structurally aligned with the most important
`repo-ref/ai` lessons:

- one-way dependency direction
- provider-owned behavior
- runtime/UI separation
- deliberate shared versus provider-specific boundaries

The next worthwhile work is no longer broad architecture cleanup.

It is:

1. streamed runner maturity
2. `llm_dart_core` internal boundary hardening
3. continued root compatibility slimming

Everything else should remain explicitly deferred unless real product pressure
appears.
