# Milestones

## Milestone 1 - Freeze Decisions

Acceptance criteria:

- target method names are accepted for all model contracts
- provider options versus provider metadata policy is accepted
- prompt part options direction is accepted
- legacy exit policy is accepted
- migration examples are drafted before code changes begin

Exit gate:

- workstream docs are reviewed and updated

## Milestone 2 - Non-Text Contract Hardening

Acceptance criteria:

- `EmbeddingModel.embed` is renamed to `doEmbed`
- `ImageModel.generate` is renamed to `doGenerate`
- `SpeechModel.generateSpeech` is renamed to `doGenerate`
- `TranscriptionModel.transcribe` is renamed to `doGenerate`
- `llm_dart_ai` helpers call the new provider methods
- provider implementations and tests are updated
- guard tooling rejects old contract method names

Validation:

- `dart tool/check_workspace_dependency_guards.dart`
- `dart test packages/llm_dart_provider/test`
- `dart test packages/llm_dart_ai/test`
- focused provider package tests for touched providers

## Milestone 3 - Prompt Input Options

Acceptance criteria:

- prompt parts have an input-side provider options mechanism
- provider-owned part options exist for Anthropic cache control
- Anthropic request codec reads cache control from provider options
- metadata-driven input cache control is deprecated or removed according to
  the breaking policy
- serialization tests cover the new input option shape

Validation:

- provider package tests for Anthropic prompt encoding
- provider serialization tests
- migration examples compile

## Milestone 4 - Metadata Cleanup

Acceptance criteria:

- provider codecs no longer read user-supplied `ProviderMetadata` as request
  customization
- output content, stream events, and UI projection still preserve
  `ProviderMetadata`
- replay behavior is explicit and provider-owned where needed
- docs explain `ProviderOptions`, `ProviderMetadata`, and `ProviderReference`
  with before/after examples

Validation:

- provider metadata tests
- AI runtime replay tests
- chat UI projection tests

## Milestone 5 - Legacy Containment Or Removal

Acceptance criteria:

- root legacy surface has a chosen exit option
- examples avoid legacy imports except migration examples
- guards prevent new root implementation growth
- changelog and migration docs document removed or moved surfaces

Validation:

- root boundary guard
- example API guard
- consumer smoke for modern focused imports

## Milestone 6 - Release Readiness

Acceptance criteria:

- workspace guards pass
- package-local analysis passes
- focused package tests pass
- Flutter tests pass if chat/runtime contracts changed
- clean consumer smoke passes
- publish dry-run passes for affected packages

Suggested validation command:

```powershell
dart tool/release_readiness.dart --report=docs/workstreams/2026-05-provider-contract-and-prompt-boundary-refactor/release-readiness-report.txt
```

## Milestone 7 - User Prompt Normalization Closure

Acceptance criteria:

- `ModelMessage` is the documented user-facing prompt layer
- normalization from `ModelMessage` to provider-facing `PromptMessage` exists
- normalization validates missing tool results and invalid prompt transitions
- migration docs reflect the split between user-facing and provider-facing
  prompt contracts

Validation:

- `dart test packages/llm_dart_ai/test/prompt_normalization_test.dart`
- `dart test packages/llm_dart_ai/test/prompt_validation_test.dart`
- `dart analyze packages/llm_dart_ai`
