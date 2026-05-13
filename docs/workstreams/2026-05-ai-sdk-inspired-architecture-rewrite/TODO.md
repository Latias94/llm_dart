# TODO

## Setup

- [x] Create the AI SDK-inspired architecture rewrite workstream
- [x] Record the initial gap audit
- [x] Define target semantic ownership
- [x] Define first implementation slices
- [x] Link follow-up implementation PRs or commits as they land
  - `5a58bea5 fix: validate normalized model prompts`
  - `0897abb3 refactor: align chat input with model messages`

## Decision Freeze

- [x] Confirm the user-facing prompt type name
  - `ModelMessage` is the user-facing prompt type, matching the reference AI
    SDK model-message layer.
- [x] Confirm whether direct `PromptMessage` runtime helpers remain public as
  advanced provider-prompt APIs
  - Keep `prompt:` / `PromptMessage` as low-level provider-facing entrypoints
    for direct provider integration and replay, while `messages:` /
    `ModelMessage` stays the common app-facing path.
- [x] Confirm the replay bridge shape for OpenAI, Google, and Anthropic
  - Shared replay stays on typed `ProviderReplayPromptPartOptions` and
    provider-owned replay helpers; OpenAI and Google carry replay metadata
    through their own codecs, and Anthropic keeps provider-owned custom replay
    parts for its native continuation shapes.
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
- [x] Keep explicit advanced entrypoints for already-normalized provider prompts
  if needed
  - The low-level `prompt:` path remains public for advanced/provider-owned use
    cases.

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
