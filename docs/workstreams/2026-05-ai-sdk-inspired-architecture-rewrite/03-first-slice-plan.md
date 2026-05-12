# First Slice Plan

## Slice 1 - User Prompt Layer

Goal:

- add a user-facing prompt layer in `llm_dart_ai`
- keep provider-facing `PromptMessage` in `llm_dart_provider`

Suggested work:

- add `ModelMessage` or an equivalent runtime prompt type
- support string shorthand for common user and assistant messages
- support text, file/image, reasoning, tool call, tool result, and custom parts
- preserve typed provider options on user prompt messages and parts
- add `normalizePrompt(...)` that produces provider-facing `PromptMessage`
- keep direct `PromptMessage` entrypoints temporarily only as explicit advanced
  provider-prompt APIs

Validation:

- unit tests for role conversion
- unit tests for empty text filtering
- unit tests for file and image normalization
- unit tests for provider options preservation

## Slice 2 - Prompt Validation

Goal:

- move prompt correctness checks into AI runtime before provider calls

Suggested work:

- detect missing client-executed tool results
- allow provider-executed tool calls to continue without client tool results
- combine consecutive tool messages where the provider prompt contract expects
  it
- reject invalid role transitions with actionable errors
- keep provider codecs focused on provider capability and wire support

Validation:

- tests for missing tool result errors
- tests for approval response handling
- tests for provider-executed tool calls
- tests proving provider codecs receive normalized prompts

## Slice 3 - Metadata/Options Hard Line

Goal:

- stop using `ProviderMetadata` as ordinary prompt input customization

Suggested work:

- remove `providerMetadata` from user prompt constructors
- keep provider-facing metadata only where migration or replay still requires
  a temporary bridge
- introduce explicit replay option classes for providers that need output
  metadata to continue native conversations
- move `GenerateTextRunnerSupport.stepToPromptMessages` to output-to-user
  response-message conversion that maps metadata into provider options

Validation:

- tests proving request configuration uses provider options only
- provider replay tests for OpenAI Responses, Google tool/function replay, and
  Anthropic native tool/code execution replay
- guard pattern rejecting new request-side metadata extraction in provider
  codecs outside approved replay helpers

## Slice 4 - Serialization Consolidation

Goal:

- remove duplicated JSON helper ownership

Suggested work:

- make AI runtime reuse provider-owned serialization helpers where possible
- move runtime-only UI serialization helpers to `llm_dart_ai`
- decide whether repeated provider serialization helpers justify
  `llm_dart_provider_utils`
- if no public package is created, document the package-private helper boundary

Validation:

- serialization round-trip tests for prompt messages, stream events, tool
  output, provider metadata, provider prompt options, and UI messages
- guard or test ensuring duplicated `SerializationJsonSupport` does not return
  in `llm_dart_ai`

## Slice 5 - Root Legacy Exit

Goal:

- prevent compatibility code from shaping new architecture decisions

Suggested work:

- classify every `legacy.dart` export as delete, relocate, or freeze
- write migration replacements for each retained export
- remove legacy usage from non-migration examples
- consider a separate compatibility package only if user demand justifies it

Validation:

- root boundary guard remains green
- legacy import guard expands to examples and package tests
- migration docs cover removed or relocated APIs
