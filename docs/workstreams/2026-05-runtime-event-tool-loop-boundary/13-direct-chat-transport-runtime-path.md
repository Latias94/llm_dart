# Direct Chat Transport Runtime Path

Date: 2026-05-13
Status: implemented

## What Landed

`DirectChatTransport` now sends chat requests through the AI runtime path:

- uses `streamText(...)` instead of calling `LanguageModel.doStream(...)`
  directly
- keeps existing prompt, `GenerateTextOptions`, and `CallOptions` forwarding
- projects the runtime text stream through `projectTextStreamEventStream(...)`
- forwards `ChatRequestOptions.metadata` as message-start metadata

This means direct chat now benefits from the provider stream adapter and
runtime event validation before events become chat UI chunks.

## Why This Matters

Previously direct chat was a separate provider-stream path. That made chat a
second owner of stream semantics and bypassed the runtime boundary we are
building. This slice keeps chat focused on chat transport/UI chunks while
letting `llm_dart_ai` own model stream adaptation.

## Validation

- `dart analyze packages/llm_dart_chat`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`

## Remaining Work

Direct chat still has its own chat-session tool continuation logic. A later M5
slice should either delegate automatic tool execution to the AI runtime or
document a strict adapter boundary for chat-specific tool output submission.
