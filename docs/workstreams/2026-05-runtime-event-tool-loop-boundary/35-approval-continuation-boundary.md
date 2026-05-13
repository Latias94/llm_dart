# Approval Continuation Boundary

## Decision

The first runtime surface does not execute or auto-continue while provider tool
approval requests are waiting for responses.

When a step contains `ToolApprovalRequestEvent` / `ToolApprovalRequestContent`,
the AI runtime now stops the loop and returns the observable step state instead
of throwing. This remains true even if the same step also contains
client-executable tool calls.

## Ownership

Approval response collection is chat/session state, not model-call runtime
state:

- `llm_dart_ai` records the approval request in the full stream and step result.
- `llm_dart_ai` stops local tool execution while approval is pending.
- `llm_dart_chat` owns `respondToolApproval(...)`, persisted approval state,
  prompt replay of `ToolApprovalResponsePromptPart`, and transport-backed
  continuation.

This keeps `streamText(...)` deterministic and avoids mixing interactive UI
approval with local function tool execution in a single runtime loop.

## Important Distinction

Provider-executed tool calls without approval requests still do not block local
client tools in the same step. They are replayed as provider-owned tool-call
state, while declared client tools can still execute locally.

Only explicit approval requests stop local execution.

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart --plain-name "provider approval is waiting"`
- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart --plain-name "provider-executed calls appear"`
- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_core/test/generate_text_runner_test.dart packages/llm_dart_core/test/stream_text_runner_test.dart`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart --plain-name "approval"`
