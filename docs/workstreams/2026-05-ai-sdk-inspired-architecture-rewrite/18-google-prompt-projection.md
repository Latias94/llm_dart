# Google Prompt Projection

## Decision

Split Google prompt projection into deeper provider-owned modules while keeping
`GooglePromptMessageEncoder` as the message-role entry.

This is a package-internal refactor. Public Google options, tool replay,
function-call id behaviour, and wire output remain unchanged.

## Reference Shape

`repo-ref/ai` keeps prompt normalization and provider projection separate:

- the generic prompt conversion step handles normalized prompt shape
- provider-specific conversion then owns the wire representation

The Dart codebase already has provider-facing prompt messages, so this slice
deepens the Google provider projection directly instead of recreating the AI
SDK type stack.

## Problem

`google_prompt_message_encoder.dart` owned several unrelated behaviours:

- user text and binary encoding
- provider reference resolution for fileData
- assistant thought/replay projection
- function-call id compatibility for Gemini 3
- tool response replay
- Google-native replay custom parts

That made the module shallow: callers had to know too much about how Google
prompt items are encoded.

## Implemented Shape

- Added `google_prompt_replay_metadata.dart`.
  - Owns prompt-part replay metadata extraction and the Google function-call id
    compatibility predicate.
- Added `google_binary_part_encoder.dart`.
  - Owns user binary part encoding and assistant inline data encoding.
- Added `google_user_prompt_projection.dart`.
  - Owns user text/binary prompt-part projection.
- Added `google_assistant_prompt_projection.dart`.
  - Owns assistant thought fields, assistant replay parts, and Google replay
    custom parts.
- Added `google_tool_prompt_projection.dart`.
  - Owns tool result replay and function response replay.
- Kept `GooglePromptMessageEncoder`.
  - It now routes by message role and delegates the encoding details.

## Benefit

This deepens the Google prompt layer:

- user binary encoding has locality separate from assistant replay policy
- thought/replay metadata parsing has one reusable seam
- function-call id replay rules are no longer hidden inside the full message
  encoder
- tool replay and assistant replay can evolve independently
- focused tests now cover the new modules directly

## Verification

- `dart test test/google_prompt_projection_test.dart` in
  `packages/llm_dart_google`
- `dart test test/google_generate_content_codec_test.dart` in
  `packages/llm_dart_google`
- `dart analyze` in `packages/llm_dart_google`

Existing Google request tests still cover the full wire body. New focused tests
cover:

- user text and file reference encoding
- assistant thought signatures and Gemini 3 function-call replay ids
- assistant replay custom parts for Google tool responses
- tool response replay and function response replay
- assistant inline bytes with thought metadata

## Remaining Risks

This slice does not yet split Google stream/result codecs. Those modules are
large enough to revisit later, but they are not the same kind of prompt
projection coupling that this goal was targeting.
