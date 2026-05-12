# TODO

## Setup

- [x] Create the AI SDK-inspired architecture rewrite workstream
- [x] Record the initial gap audit
- [x] Define target semantic ownership
- [x] Define first implementation slices
- [ ] Link follow-up implementation PRs or commits as they land

## Decision Freeze

- [ ] Confirm the user-facing prompt type name
- [ ] Confirm whether direct `PromptMessage` runtime helpers remain public as
  advanced provider-prompt APIs
- [ ] Confirm the replay bridge shape for OpenAI, Google, and Anthropic
- [x] Confirm whether provider-utils starts as package-private helpers or a new
  public package
- [x] Confirm the root legacy outcome: delete, relocate, or freeze

## User Prompt Layer

- [x] Add user-facing prompt/message/content types in `llm_dart_ai`
- [x] Add text shorthand constructors or helpers for common prompts
- [x] Add file/image normalization support
- [x] Add provider options preservation for messages and parts
- [x] Add normalization to provider-facing `PromptMessage`
- [x] Update `generateText`, `streamText`, runners, and structured output
  helpers to accept the user prompt layer
- [ ] Keep explicit advanced entrypoints for already-normalized provider prompts
  if needed

## Prompt Validation

- [x] Add missing tool-result validation
- [x] Add provider-executed tool-call handling rules
- [x] Add tool approval response handling rules
- [x] Add invalid role transition errors
- [x] Add tests proving provider codecs receive normalized prompts

## Metadata/Options Boundary

- [x] Remove ordinary user prompt `providerMetadata` inputs
- [x] Move provider replay continuation into typed provider prompt options or
  provider-owned replay helpers
- [x] Update OpenAI Responses replay
- [x] Update Google function/tool replay
- [x] Update Anthropic native tool/code execution replay
- [x] Add guard coverage against request-side metadata extraction outside
  approved replay helpers

## Serialization And Utilities

- [x] Remove duplicated `SerializationJsonSupport` from `llm_dart_ai`
- [x] Reuse provider-owned serialization helpers where appropriate
- [x] Keep UI-only serialization in `llm_dart_ai`
- [x] Audit repeated provider codec helpers
- [x] Decide whether repeated helpers justify `llm_dart_provider_utils`
- [x] Document the helper boundary before publishing any new utility package

## Root Legacy Exit

- [x] Inventory `legacy.dart` exports
- [x] Assign each export a delete, relocate, or freeze decision
- [x] Update migration docs for each removed or moved API
- [x] Expand legacy import guards where needed
- [x] Remove non-migration example usage of compatibility APIs

## Validation

- [x] Run workspace dependency guards
- [x] Run root boundary guards
- [x] Run core compatibility shell guard
- [x] Run test legacy-import guard
- [x] Run focused `llm_dart_provider` tests
- [x] Run focused `llm_dart_ai` tests
- [x] Run affected provider package tests
- [x] Run chat and Flutter tests if UI projection or transport protocols change
- [x] Run package analysis for affected packages
- [x] Run `git diff --check`
- [x] Run publish dry-runs for affected packages before release handoff
