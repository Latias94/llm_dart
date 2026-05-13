# Metadata And Replay Options Boundary

Date: 2026-05-13

## Decision

Ordinary request-side `ProviderMetadata` is no longer part of prompt-part or
tool-output-content-part constructors.

Replay metadata must now flow through:

- `ProviderReplayPromptPartOptions`
- provider-owned typed replay helpers that emit `providerOptions`

Output metadata remains valid on generated content, stream events, results, UI
projection, and replay observations.

## Implemented Slice

- removed `providerMetadata` from provider-facing prompt parts
- removed `providerMetadata` from structured tool-output content parts
- updated serialization to reject legacy request-side metadata on those shapes
- updated runtime/chat replay bridges to read replay metadata from
  `providerOptions`
- updated provider replay helpers in OpenAI, Google, and Anthropic to emit
  `ProviderReplayPromptPartOptions`
- added a dedicated guard for replay metadata flow

## Why This Matters

This breaks the old ambiguity where input customization and output observation
could share the same field name.

The new shape keeps the architecture easier to explain:

- request customization is typed and explicit
- replay data is typed and explicit
- provider-observation metadata stays output-side

## Validation

- `dart analyze packages/llm_dart_provider packages/llm_dart_chat packages/llm_dart_google packages/llm_dart_openai packages/llm_dart_anthropic test tool`
- `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`
- `dart test packages/llm_dart_anthropic/test/anthropic_code_execution_replay_test.dart packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart`
- `dart test packages/llm_dart_google/test/google_generate_content_codec_test.dart`
- `dart test packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_chat_completions_mainline_test.dart`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`

## Next Boundaries

- freeze the long-term `CallOptions.providerOptions` composition policy
- freeze the structured text/object result direction
- finish the remaining prompt-surface convergence docs and examples
