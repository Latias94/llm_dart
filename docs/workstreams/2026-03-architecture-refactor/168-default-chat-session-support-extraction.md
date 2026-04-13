# 168 Default Chat Session Support Extraction

## Goal

Record the next structural cleanup step after landing:

- the streamed runner,
- the lightweight `readChatUiStream(...)` helper,
- and the first reuse of that helper inside `DefaultChatSession`.

The focus of this slice is not user-visible API expansion.

It is reducing how much unrelated logic still lives directly inside
`DefaultChatSession`.

## What Landed

`DefaultChatSession` now delegates more of its pure transformation and
message-state logic into focused support modules:

- `chat_ui_stream_reader.dart`
  - stateful chunk-to-message projection
- `chat_session_tool_support.dart`
  - tool/approval state inspection and tool-part mutation helpers
- `chat_session_message_support.dart`
  - `PromptMessage <-> ChatUiMessage` replay mapping helpers

`DefaultChatSession` now reads more honestly as a coordinator for:

- chat lifecycle
- state transitions
- transport invocation
- active-turn ownership
- automatic tool execution scheduling
- prompt-history mutation timing

instead of also being the home for every pure mapping helper.

## Why This Matters

Before this slice, `DefaultChatSession` still carried several different
responsibilities at once:

- chunk-stream projection
- assistant prompt replay encoding
- prompt-to-UI mapping
- tool/approval state derivation
- active-turn lifecycle coordination

That made the file harder to reason about and also increased the chance that
non-session consumers would copy logic instead of reusing it.

The new split makes the boundary cleaner:

- pure transformation and status helpers live in support modules
- stateful projection lives in the reusable reader
- session-specific orchestration remains in `DefaultChatSession`

## Frozen Boundary

This extraction does **not** turn `DefaultChatSession` into a thin shell.

It still owns:

- chat request triggering
- when to append assistant prompt replay
- when to schedule or suppress automatic tool execution
- approval-driven continuation decisions
- reconnect and stop behavior
- state emission and prompt-history mutation

That is still the correct place for those concerns.

What should continue moving out of the session file are only helpers that are:

- pure
- replay-oriented
- message-state oriented
- reusable by other chat runtime helpers

## Practical Result

The chat runtime layering is now clearer:

1. `llm_dart_core`
   - event and message models
   - pure accumulators
2. `llm_dart_chat`
   - reusable stateful stream reader
   - reusable tool/message support helpers
   - `DefaultChatSession` orchestration
3. app / Flutter layer
   - UI wiring and product policy

This is much closer to the intended architecture than keeping one oversized
session file as the hidden implementation hub.

## What Still Remains In `DefaultChatSession`

The biggest remaining session-owned logic is now concentrated around:

- automatic tool execution orchestration
- provider-executed approval continuation timing
- prompt-history update timing versus active-turn state transitions

That remaining weight is more legitimate than the earlier pure helper weight,
so future extraction should stay selective rather than mechanical.

## Conclusion

This slice is a structural cleanup win:

- no API churn was needed
- no event vocabulary changed
- runtime behavior stayed stable under existing tests
- reusable logic moved to focused support modules
- `DefaultChatSession` became a more honest orchestration layer
