# Dependency Direction And Export Graph Audit

## Goal

Audit the current workspace package graph and root-package export graph after
the recent entrypoint cleanup, then identify which remaining structural gaps
still block the repository from matching its own frozen architecture decisions.

This note compares the current state against:

- the frozen dependency-direction policy in this workstream
- the medium-grained package strategy already chosen for `llm_dart`
- the useful structural lessons from `repo-ref/ai`

## Reference Snapshot From `repo-ref/ai`

The reference monorepo does not matter because of package-count parity. It
matters because dependency ownership stays legible:

- the main `ai` package depends on provider-spec and provider-utils layers
- provider packages such as `@ai-sdk/openai`, `@ai-sdk/anthropic`, and
  `@ai-sdk/google` depend on the lower provider packages, not on the main `ai`
  package
- provider packages expose provider-owned surfaces instead of re-exporting the
  whole main app-facing entrypoint again

That keeps the direction one-way and keeps entrypoints honest about ownership.

## Current Observed Workspace Graph

Current `pubspec.yaml` relationships:

- root `llm_dart`
  - depends on `llm_dart_anthropic`
  - depends on `llm_dart_chat`
  - depends on `llm_dart_core`
  - depends on `llm_dart_google`
  - depends on `llm_dart_openai`
  - depends on `llm_dart_transport`
  - still directly depends on `dio`
  - still directly depends on `logging`
- `llm_dart_core`
  - no longer depends on `llm_dart_transport`
  - now owns the shared request-cancellation primitives
- `llm_dart_transport`
  - depends on `llm_dart_core`
  - depends on `dio`
  - depends on `logging`
- `llm_dart_chat`
  - depends on `llm_dart_core`
  - depends on `llm_dart_transport`
- `llm_dart_openai`
  - depends on `llm_dart_core`
  - depends on `llm_dart_transport`
- `llm_dart_anthropic`
  - depends on `llm_dart_core`
  - depends on `llm_dart_transport`
- `llm_dart_google`
  - depends on `llm_dart_core`
  - depends on `llm_dart_transport`
- `llm_dart_community`
  - depends on `llm_dart_core`
  - depends on `llm_dart_transport`
  - currently exposes only an empty barrel

## Current Root Export Graph

The modern root entrypoint story is now clearer:

- `llm_dart.dart -> ai.dart`
- `legacy.dart` is the explicit compatibility shell
- `chat.dart` is the focused pure Dart chat runtime shell

But the broader export graph is still wide:

- `ai.dart`
  - exports `anthropic.dart`
  - exports `google.dart`
  - exports `openai.dart`
  - exports `core.dart`
  - exports `transport.dart`
  - exports `AI`
- `openai.dart`
  - exports `core.dart`
  - exports `transport.dart`
  - exports `package:llm_dart_openai/llm_dart_openai.dart`
  - exports `AI`
- `google.dart`
  - exports `core.dart`
  - exports `transport.dart`
  - exports `package:llm_dart_google/llm_dart_google.dart`
  - exports `AI`
- `anthropic.dart`
  - exports `core.dart`
  - exports `transport.dart`
  - exports `package:llm_dart_anthropic/llm_dart_anthropic.dart`
  - exports `AI`
- `chat.dart`
  - exports `core.dart`
  - exports `transport.dart`
  - exports `package:llm_dart_chat/llm_dart_chat.dart`
  - exports `AI`
- `legacy.dart`
  - exports broad root-local compatibility code including builders, legacy
    models, local provider implementations, and compatibility utilities

## Findings

### 1. The Workspace Previously Had A Real `core <-> transport` Package Cycle

This was the clearest structural violation at audit time.

Evidence:

- `packages/llm_dart_transport/pubspec.yaml` depends on `llm_dart_core`
- `packages/llm_dart_core/lib/src/common/call_options.dart` needed a shared
  cancellation token for the common call surface
- `packages/llm_dart_core/lib/llm_dart_core.dart` had been re-exporting
  transport-owned cancellation types

This directly contradicted the frozen one-way dependency decision.

The cycle existed mostly because request cancellation lived in a
transport-owned surface while `CallOptions` also needs it as a common model API.

### Status

This gap is now fixed:

- shared `TransportCancellation` and `TransportCancelledException` now live in
  `llm_dart_core`
- `llm_dart_transport` re-exports those types instead of owning them
- `llm_dart_core` no longer depends on `llm_dart_transport`

### 2. The Root Package Still Acts As Both Modern Facade And Legacy Host

The root package still contains a large amount of local implementation code:

- `lib/builder`: 13 files
- `lib/core`: 21 files
- `lib/models`: 29 files
- `lib/providers`: 96 files
- `lib/src/compatibility`: 20 files

That means the root package is no longer only a facade. It is still the
implementation host for:

- builder-era compatibility
- local legacy provider classes
- community-provider implementations that have not moved into package ownership
- a large amount of compatibility request shaping and utility code

This is acceptable as a migration phase, but it is the main reason the root
package still needs direct runtime dependencies and local provider internals.

### 3. `llm_dart_community` Exists, But It Is Not Carrying Real Weight Yet

The workspace already created `llm_dart_community`, but today it is still only
an empty barrel.

At the same time, root-local provider directories still own:

- Ollama
- ElevenLabs
- other compatibility-era provider code that has not been re-homed

That means the package graph says the community landing zone exists, but the
actual implementation weight still lives in the root package.

### 4. Provider-Focused Root Shells Still Re-Export Too Much

The current modern default root boundary is good, but provider-focused shells
are still wider than their names imply.

For example, `openai.dart`, `google.dart`, and `anthropic.dart` currently
re-export:

- provider-owned package APIs
- shared `core.dart`
- shared `transport.dart`
- the root `AI` facade

That is convenient, but it weakens ownership signaling:

- importing a provider shell does not mean provider-owned types only
- the same `AI` factory path appears from multiple unrelated entrypoints
- narrower entrypoint naming no longer guarantees narrower surface area

This is not as severe as the package cycle, but it is the next export-graph
ambiguity worth tightening after the root-versus-`ai.dart` boundary.

### 5. Root Runtime Dependencies Are Still Transitional, Not Architectural

The root package still depends directly on:

- `dio`
- `logging`

Those dependencies are no longer justified by the modern root surface itself.
They remain because root-local compatibility and provider-hosting code still
uses them.

That means the current root dependency list is still a migration artifact, not
the intended steady-state design.

## Recommended Direction

### 1. Keep The `core -> transport` Edge Removed During Further Migration

This was the first required structural correction, and it is now implemented.

The follow-up rule is:

- keep the medium-grained workspace strategy
- do not reintroduce any new `llm_dart_core -> llm_dart_transport` dependency
- keep shared request-lifecycle primitives in a core-owned placement when they
  are part of common model APIs
- keep `llm_dart_transport -> llm_dart_core`, not the other way around

### 2. Make `llm_dart_community` A Real Migration Target

The next package-hosting move should be concrete, not symbolic:

- move Ollama into `llm_dart_community`
- move ElevenLabs into `llm_dart_community`
- let the root package re-export or compatibility-route them from there instead
  of continuing to own their implementation forever

This reduces both root weight and root dependency pressure.

### 3. Audit Whether Provider Root Shells Should Become Narrower

After the default modern root boundary is already stable, evaluate whether:

- `openai.dart`
- `google.dart`
- `anthropic.dart`

should stop re-exporting unrelated modern shells such as `AI`, `core.dart`, and
`transport.dart`.

The likely long-term rule is:

- `chat.dart` may remain the convenience exception because it is app-facing
- provider shells should increasingly look provider-owned, not root-owned

### 4. Keep Root Dependency Slimming Tied To Real Code Moves

Do not remove root dependencies cosmetically first.

Instead:

- move remaining local provider and compatibility implementation weight out
- then remove `dio` and `logging` from the root package when they are no longer
  needed by root-local code

That keeps the dependency graph truthful.

## Non-Goals

This audit does not recommend:

- copying the full `repo-ref/ai` package count
- creating a new public micro-package for every shared primitive
- removing `legacy.dart`
- forcing every focused entrypoint to collapse back into `llm_dart.dart`

## Status

The root modern entrypoint story is now much healthier than before, and the
package graph is back on the intended one-way path. The remaining large
migration tails are now:

- the still-empty `llm_dart_community` landing zone
- the still-heavy root compatibility and provider host role
- the still-overwide provider-focused root shells

Those should be treated as the next structural cleanup frontier.
