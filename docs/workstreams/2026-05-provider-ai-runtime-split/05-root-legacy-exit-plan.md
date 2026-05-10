# Root And Legacy Exit Plan

## Current Root Role

The root package currently acts as:

- modern facade
- focused entrypoint host
- compatibility shell
- legacy builder host
- legacy model host
- legacy provider implementation host
- compatibility utility host

That is acceptable during migration, but it should not be the steady state of a
breaking architecture line.

## Target Root Role

The root package should eventually own only:

- `llm_dart.dart` as the modern default facade
- focused aliases such as `ai.dart`, `chat.dart`, `openai.dart`, `google.dart`,
  `anthropic.dart`, and `transport.dart`
- explicit legacy compatibility re-exports while the migration window remains
- migration documentation

Root should not own:

- new provider implementations
- new shared model contracts
- new transport implementations
- new runtime orchestration
- new provider utility code

## Legacy Strategy Options

### Option A - Keep `legacy.dart` In Root During The Breaking Line

Pros:

- smoother migration
- fewer immediate package moves
- existing users can import one explicit compatibility shell

Cons:

- root package keeps implementation weight longer
- root dependencies shrink more slowly

Decision for the first breaking preview:

- keep `legacy.dart` in root as the explicit compatibility bridge
- keep new stable model/runtime/provider work out of root legacy areas
- revisit `llm_dart_legacy` only after the modern provider/runtime packages and
  migration docs are no longer moving quickly

### Option B - Move Legacy Into `llm_dart_legacy`

Pros:

- root becomes clean faster
- dependency graph becomes more truthful
- compatibility weight is isolated

Cons:

- more package churn
- migration guide must be stronger
- old import paths need deliberate deprecation or forwarding

Recommended after the new provider/runtime packages are already compiling.

### Option C - Delete Legacy APIs Directly

Pros:

- fastest cleanup

Cons:

- highest user disruption
- easiest path to lose migration evidence

Not recommended until migration recipes and release notes are complete.

## Exit Sequence

1. Stop adding new implementation logic to root legacy areas.
2. Move provider-owned modern code into provider packages first.
3. Move provider-facing shared contracts into `llm_dart_provider`.
4. Move generation orchestration and shared chat UI projection into
   `llm_dart_ai`.
5. Update examples to use focused modern imports.
6. Keep `legacy.dart` as an explicit bridge.
7. Remove root dependencies only after root-local implementation code no
   longer needs them.
8. Decide whether `llm_dart_legacy` is needed for the final compatibility
   window.

## Compatibility Rules

- no silent capability loss
- unsupported legacy request shapes must fail clearly or route to the legacy
  implementation while it exists
- provider-native features with modern replacements should point users to the
  provider-owned path
- migration docs must distinguish stable shared APIs, provider-owned APIs, and
  compatibility-only APIs
