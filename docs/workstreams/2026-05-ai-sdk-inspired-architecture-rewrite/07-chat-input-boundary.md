# Chat Input Boundary

Date: 2026-05-14
Status: complete

## Decision

`ChatInput` represents a new user-authored chat turn. It now holds a
user-facing `UserModelMessage` instead of a provider-facing `PromptMessage`.

`DefaultChatSession` normalizes the input through `normalizeModelMessages(...)`
before appending it to provider prompt history or sending it through
`ChatTransport`.

## Boundary

- New app input uses `ChatInput`, `UserModelMessage`, and `ModelPart`.
- Replay state uses `PromptMessage`, `PromptPart`, chat transport payload
  prompt history, and durable `ChatSessionSnapshot.prompt`.

This keeps the chat API aligned with the user prompt layer without weakening
provider replay fidelity. Tool continuations, approval responses, provider
custom replay parts, and restored snapshots still operate on normalized
provider prompt state.

## Validation

- `dart analyze packages/llm_dart_chat`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`
- `dart test packages/llm_dart_chat/test/chat_session_message_support_test.dart packages/llm_dart_chat/test/chat_persistence_adapter_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`

The workspace dependency guard now rejects provider-facing
`PromptMessage`/`PromptPart` types in app-facing chat input surfaces while
allowing transport, snapshot, replay, and advanced runtime layers to keep using
provider prompts.
