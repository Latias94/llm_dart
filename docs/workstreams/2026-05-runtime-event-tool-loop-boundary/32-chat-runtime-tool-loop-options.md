# Chat Runtime Tool Loop Options

## Decision

`ChatRequestOptions` now carries the app-facing text runtime tool-loop
configuration used by `streamText(...)`:

- declared function tools and tool choice
- local function tool executor
- `maxSteps` and composable `stopWhen` conditions
- run, step, tool, chunk, finish, and error callbacks

`DirectChatTransport` forwards those options directly into
`streamText(...)` before projecting runtime events into `ChatUiStreamChunk`.
This keeps direct in-process chat on the same runtime path as plain AI callers.

`HttpChatTransport` deliberately does not serialize those local runtime hooks
yet. It accepts the existing JSON-safe fields (`GenerateTextOptions`,
serializable `CallOptions`, stream protocol, and metadata), but rejects tools,
tool choice, runtime callbacks, `functionToolExecutor`, `stopWhen`, or custom
`maxSteps` with `UnsupportedError`.

## Boundary

The split is intentional:

- `llm_dart_ai` owns tool execution inside a single runtime run.
- `DirectChatTransport` is a thin adapter from chat requests into that runtime.
- `DefaultChatSession` owns chat state, persistence, approval state, manual
  tool output submission, and session-level continuation after a tool output is
  accepted.
- `HttpChatTransport` owns a JSON transport protocol. It must not silently drop
  non-serializable Dart callbacks or local executors.

The existing `DefaultChatSession.onToolCall` and `ToolExecutionRegistry` APIs
remain chat-level ergonomics for UI/session-managed client-side tools. They are
not a provider stream accumulator. They run after a tool call is represented in
chat state and then continue the same assistant message through the configured
transport.

## Why Not Serialize This Now

Serializing tools and tool execution over HTTP is a different contract from
local runtime execution. It needs explicit choices for:

- remote tool registry shape
- function input schema serialization and validation
- server-side or client-side execution ownership
- approval request/response continuation across reconnects
- error and dynamic-tool semantics

Until that protocol is designed, failing loudly is safer than accepting fields
that the server cannot observe.

## Validation

- `dart analyze packages/llm_dart_chat`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart --plain-name "DirectChatTransport"`
- `dart test packages/llm_dart_chat/test/http_chat_transport_test.dart --plain-name "rejects local runtime tool loop options"`
