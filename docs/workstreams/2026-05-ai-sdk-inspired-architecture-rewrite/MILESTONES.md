# Milestones

## M1 - Direction Freeze

Goals:

- freeze the purpose of this rewrite
- confirm that the existing package graph remains the base
- define which semantic boundaries change first

Acceptance criteria:

- README, gap audit, target architecture, first-slice plan, TODO, and milestones
  exist
- non-goals explicitly prevent package-count parity with `repo-ref/ai`
- prior completed workstreams are treated as inputs, not reopened debates

Current status:

- scaffold created

## M2 - User Prompt Layer

Goals:

- introduce user-facing prompt data in `llm_dart_ai`
- normalize user prompts into provider-facing `PromptMessage`
- keep provider-facing prompt contracts stable and implementation-oriented

Acceptance criteria:

- common runtime helpers accept the new user prompt shape
- provider codecs still consume normalized provider prompts
- direct provider prompt entrypoints are marked advanced or transitional
- prompt normalization is covered by tests

Current status:

- in progress; user-facing `ModelMessage` data, provider-prompt
  normalization, runtime helper `messages:` inputs, and prompt normalization
  tests have landed

## M3 - Runtime Prompt Validation

Goals:

- centralize user-prompt validation before provider calls
- catch missing tool results and invalid prompt transitions in AI runtime

Acceptance criteria:

- missing client-executed tool results fail before provider codecs run
- provider-executed tool calls are handled explicitly
- tool approval and denial semantics have tests
- provider codecs do not duplicate user-level validation

Current status:

- pending

## M4 - Metadata/Options Boundary

Goals:

- remove ordinary request-side `ProviderMetadata` usage
- keep output metadata as observation/replay data
- convert replay metadata through explicit provider-owned options

Acceptance criteria:

- prompt input customization uses provider options
- provider replay behavior remains tested
- request codecs do not read metadata as general request configuration
- guard tooling catches regressions

Current status:

- pending

## M5 - Provider Utility Consolidation

Goals:

- consolidate duplicated serialization/projection helpers
- decide whether to publish `llm_dart_provider_utils`

Acceptance criteria:

- duplicated AI/provider JSON helper code is removed
- repeated provider helper code has one documented owner
- no utility package is published without a stable public contract

Current status:

- pending

## M6 - Root Legacy Exit

Goals:

- classify root legacy exports
- delete, relocate, or freeze compatibility surfaces
- keep modern model-first APIs as the default public guidance

Acceptance criteria:

- every legacy export has a migration decision
- non-migration examples avoid `legacy.dart`
- root remains a facade under guard tooling

Current status:

- pending

## M7 - Release Readiness

Goals:

- turn the architecture rewrite into a releasable breaking line

Acceptance criteria:

- guards pass
- focused package tests pass
- root compatibility tests reflect the final legacy decision
- migration docs and breaking changelog are ready
- publish dry-runs pass for affected packages

Current status:

- pending
