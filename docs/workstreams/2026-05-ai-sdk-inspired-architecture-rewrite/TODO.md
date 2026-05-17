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

## Provider/Registry Rebaseline

- [x] Reopen this workstream for the Provider/Registry fearless refactor line
- [x] Record the provider-object, registry, OpenAI-family, typed-options, and
  core-compatibility rebaseline
- [x] Design the public provider object contracts in `llm_dart_provider`
- [x] Decide whether `ModelRegistry` becomes a compatibility adapter, a
  deprecated alias, or a removed API in the next breaking line
- [x] Add the provider-object registry and focused registry tests
- [x] Implement provider facets on OpenAI, Anthropic, Google, Ollama, and other
  concrete provider facades
- [x] Refactor OpenAI-family option/profile resolution out of one central
  provider-id conditional chain
- [x] Document typed provider option precedence, conflict behavior, and
  wrong-provider rejection rules
- [x] Update root facade guidance and examples for dynamic provider lookup
- [x] Freeze or exit `llm_dart_core` without adding new ownership there
- [x] Add guards that prevent provider packages from importing runtime, root,
  chat, Flutter, or compatibility barrels
- [x] Add focused tests for provider registry errors, provider-specific option
  rejection, and OpenAI-family route/profile behavior
- [x] Update migration docs for provider registry changes and any `ModelRegistry`
  removal or adaptation
- [x] Close OpenAI-family class-level facet reporting by adding
  provider-declared registry facet support
- [x] Move OpenAI-family capability description details behind a profile-owned
  policy seam
- [x] Move OpenAI-family Chat Completions provider-specific request-field
  policy out of the shared codec
- [x] Resolve OpenAI-family Chat Completions request policy from
  `OpenAIFamilyProfile` on the language-model path
- [x] Move Google language model-family request and capability policy behind a
  provider-owned seam
- [x] Split Ollama chat request encoding into options policy, prompt
  projection, binary prompt encoding, and request assembly modules
- [x] Split Anthropic Messages request option encoding into thinking policy,
  beta feature inference, token-count projection, and request assembly modules
- [x] Split OpenAI Responses prompt conversion into user media encoding,
  assistant replay projection, tool message projection, and replay policy
  modules
- [x] Split Google prompt projection into user binary encoding, assistant
  replay projection, tool replay projection, and replay metadata helpers
