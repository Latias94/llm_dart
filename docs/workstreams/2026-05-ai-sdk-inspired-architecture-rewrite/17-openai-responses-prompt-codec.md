# OpenAI Responses Prompt Codec

## Decision

Split OpenAI Responses prompt input conversion into deeper provider-owned
modules while keeping `OpenAIResponsesPromptCodec` as the request prompt entry.

This is a package-internal refactor. Public OpenAI options, replay metadata
shape, OpenAI Responses request body output, and wire behaviour remain
unchanged.

## Reference Shape

`repo-ref/ai` keeps two useful ownership layers:

- `convertToLanguageModelPrompt` normalizes app-facing prompt messages into a
  provider-facing prompt, preserving provider options and validating tool
  result ordering.
- `convertToOpenAIResponsesInput` then owns the OpenAI Responses wire input
  projection, including media parts, item references, reasoning replay,
  compaction items, and tool outputs.

The Dart package already has a provider-facing prompt contract, so this slice
does not copy the TypeScript layer count. Instead it deepens the OpenAI
Responses provider projection itself.

## Problem

`openai_responses_request_prompt_codec.dart` had a compact public interface but
too much implementation knowledge behind it:

- system message mode and plain message-role dispatch
- user text/image/file input encoding
- OpenAI file reference, URL, and data URL handling
- assistant text replay grouping by item id and phase
- reasoning encrypted-content replay and item-reference compatibility
- compaction replay
- assistant tool-call and tool-result replay policy
- tool message function outputs and MCP approval responses

That made the module difficult to extend safely when OpenAI adds new Responses
input item types, because unrelated behaviours lived in one file.

## Implemented Shape

- Added `openai_responses_user_part_encoder.dart`.
  - Owns user text/image/file input part encoding.
  - Owns OpenAI file references, image detail, image data URLs, PDF URLs, and
    PDF data URLs.
- Added `openai_responses_assistant_prompt_projection.dart`.
  - Owns assistant text grouping, reasoning replay, tool-call replay,
    assistant tool-result replay warnings, and compaction item projection.
- Added `openai_responses_tool_prompt_projection.dart`.
  - Owns tool message projection for function call outputs and MCP approval
    responses.
- Added `openai_responses_replay_policy.dart`.
  - Owns the small `store`/`conversation` decisions shared by assistant and
    tool replay.
- Kept `OpenAIResponsesPromptCodec`.
  - It now routes by prompt message role, handles system message mode, and
    delegates provider-facing content projection to the deeper modules.

## Benefit

This deepens the OpenAI Responses module:

- user media encoding has locality separate from assistant replay policy
- reasoning and compaction replay rules can evolve without reopening user file
  input encoding
- MCP approval and tool output projection have a focused test surface
- `OpenAIResponsesRequestCodec` remains a request assembly module instead of a
  prompt conversion owner
- typed OpenAI prompt-part options and provider replay metadata stay
  provider-owned

## Verification

- `dart test test/openai_responses_prompt_projection_test.dart` in
  `packages/llm_dart_openai`
- `dart test test/openai_responses_codec_test.dart` in
  `packages/llm_dart_openai`
- `dart analyze` in `packages/llm_dart_openai`

Existing Responses codec tests continue to cover full request body behaviour.
New focused tests cover:

- user image file references and PDF byte encoding
- assistant text grouping by replay item metadata
- duplicate reasoning item-reference suppression
- removal and warning for reasoning replay without encrypted content when
  `store` is false
- MCP approval response item references based on `store`

## Remaining Risks

The OpenAI Responses tool-call projection still only covers the current Dart
tool shapes and does not yet implement AI SDK-specific provider tools such as
shell, apply-patch, or tool-search replay. That is acceptable because those
tools are not public Dart provider tools today. If equivalent native tools are
added later, the assistant and tool projection modules are now the correct
places to add them.
