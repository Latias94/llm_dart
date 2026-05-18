# Goal

## Canonical Goal Text

Complete a core-to-provider SDK alignment pass for `llm_dart` that validates
the entire architecture against the durable lessons of `repo-ref/ai` without
copying its TypeScript-specific implementation. The pass must prove that core
provider contracts, AI runtime orchestration, transport primitives, provider
adapter internals, provider-native options, metadata/replay semantics,
capability profiles, registry lookup, root facade behavior, and compatibility
barrels form one coherent layered system.

The outcome should be a final breaking-line roadmap with concrete migration
rules, provider parity evidence, guards, and validation gates.

## Completion Definition

This goal is complete only when:

- core model contracts have been audited against the reference provider v4
  shape and Dart-specific decisions are recorded
- AI runtime event, tool-loop, output, and UI projection semantics have been
  audited against the reference runtime shape
- provider-by-provider parity is documented for shared options, typed provider
  options, provider metadata, capability profiles, stream events, and native
  helper clients
- repeated provider helper duplication has a documented local/internal/public
  ownership decision
- provider object registry and dynamic model lookup posture are settled
- root `llm_dart` and `llm_dart_core` have explicit freeze, migration, or
  removal outcomes
- guards reject regressions in package direction, compatibility ownership,
  metadata/input separation, and provider/runtime stream semantics
- package-local tests, workspace guards, consumer smoke, and release readiness
  gates prove the final shape
