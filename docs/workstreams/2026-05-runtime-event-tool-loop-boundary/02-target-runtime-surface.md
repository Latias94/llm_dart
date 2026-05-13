# Target Runtime Surface

This document is the initial target shape. Names can still change in M1, but
the ownership direction should not change without new evidence.

## Package Ownership

### `llm_dart_provider`

Provider owns model-call contracts:

- `GenerateTextRequest`
- `GenerateTextResult`
- provider/model-call stream parts
- provider metadata
- typed provider options
- prompt and content structures needed by provider codecs

Provider does not own:

- run lifecycle
- step lifecycle
- local tool execution loops
- UI message chunks
- chat session state
- agent abstractions

### `llm_dart_ai`

AI runtime owns generation orchestration:

- app-facing prompt normalization and validation
- `generateText(...)`
- `streamText(...)`
- `generateTextCall(...)`
- `streamTextCall(...)`
- run and step result models
- full-stream event vocabulary
- tool execution and continuation
- structured output parsing
- stream accumulation
- UI projection
- optional `Agent` / `ToolLoopAgent` helper if M1 makes it public

### `llm_dart_chat`

Chat owns application state and transport:

- chat state
- persistence snapshots
- HTTP/direct transport protocols
- manual tool output and approval response APIs
- transient data parts
- session lifecycle

Chat should consume runtime UI streams or agent streams. It should not be the
owner of model-call accumulation or provider stream semantics.

## Event Vocabulary

### Provider Model-Call Events

Final base name: `LanguageModelStreamEvent`.

These events describe one provider/model invocation:

- model call start / warnings
- response metadata
- text start/delta/end
- reasoning start/delta/end
- files and reasoning files
- sources
- tool input start/delta/end
- tool call
- provider tool result
- tool input error
- provider metadata
- raw chunks
- model call finish
- model call error

Rules:

- provider packages may emit only provider model-call events
- provider packages must not emit run start, step start, step finish, run
  finish, chat chunks, or local tool execution events
- provider-executed tools stay provider events because they are provider-owned
  facts

### AI Runtime Full-Stream Events

Final base name: `TextStreamEvent`.

These events describe the whole generation run:

- run start
- step start
- provider/model-call events adapted into runtime content events
- tool execution start
- preliminary tool result
- tool execution finish
- tool approval request
- tool approval response
- tool output denied
- step finish
- run finish
- abort
- error
- raw provider chunk when explicitly enabled

Rules:

- runtime injects step events
- runtime owns local tool result events
- runtime owns aggregate usage and final finish reason
- runtime can expose provider metadata, but only as response-side observation
  or replay data

## Result Surface

The long-term app-facing helpers should be:

- `generateText(...)`
  - non-streaming, multi-step runtime helper
  - returns the full run result
- `streamText(...)`
  - streaming, multi-step runtime helper
  - returns a stream result object
- `generateTextCall(...)`
  - combined text/result facade with optional `OutputSpec`
- `streamTextCall(...)`
  - streaming combined text/result facade with optional `OutputSpec`

The streaming result foundation should expose:

- `eventStream`
- `textStream`
- `partialOutputStream`
- `elementStream<T>()`
- `result`
- `steps`
- `lastStep` or `finalStep`
- `text`
- `reasoningText`
- `content`
- `toolCalls`
- `toolResults`
- `usage`
- `finishReason`
- `rawFinishReason`
- `providerMetadata`
- `toChatUiStream(...)` or equivalent UI projection

The old runner helpers should either:

- become private implementation details, or
- remain temporary migration aliases that delegate to the unified runtime
  foundation.

## Tool Execution Surface

The runtime tool engine should own:

- declared function tools
- local execution callback or registry
- tool execution start/end callbacks
- tool input lifecycle callbacks if supported in M1 scope
- tool approval requests and responses
- denied outputs
- dynamic tool input errors
- provider-executed tool passthrough
- preliminary outputs
- replay-safe prompt continuation
- stop conditions
- runtime context and tools context if M1 accepts the added surface

Suggested first shape:

- `ToolExecutionRequest`
  - step number
  - tool call
  - current messages
  - runtime context
  - call/provider metadata
- `ToolExecutionResult`
  - normalized `ToolOutput`
  - optional preliminary flag
  - provider/replay metadata when relevant
- `ToolExecutionEvents`
  - execution start
  - preliminary result
  - execution finish
  - execution error

## Step Control

The runtime should support composable stop conditions:

- `isStepCount(int count)`
- `isLoopFinished()`
- `hasToolCall(String name)`
- custom predicate over completed steps

`maxSteps` can remain a defensive guard, but it should not be the only public
loop policy.

## Chat Integration

`DirectChatTransport` should not call `LanguageModel.doStream(...)` directly.
It should call either:

- `streamText(...)` with chat prompt/options, then project to UI chunks, or
- a public `ToolLoopAgent.stream(...)` if M1 makes agents public.

Chat remains responsible for:

- when to submit a user message
- when to regenerate
- how to persist messages
- how to apply manual tool outputs
- how to respond to approvals
- how to reconnect HTTP streams

Runtime owns:

- how a model call becomes a step
- how local tools are executed
- how steps continue
- how full-stream events become UI chunks

## Dependency Policy

No new public package should be introduced in the first slice.

Acceptable internal refactors:

- move shared runtime code into `packages/llm_dart_ai/lib/src/runtime`
- move provider model-call event helpers into
  `packages/llm_dart_provider/lib/src/stream`
- move shared tool execution code into `packages/llm_dart_ai/lib/src/tool`
- keep chat adapters in `packages/llm_dart_chat/lib/src`

Only extract a public provider-utils package if at least two focused provider
packages prove the same stable helper contract and the dependency graph remains
clean.

## Migration Strategy

Preferred order:

1. Add new runtime foundation behind existing public helpers.
2. Make `streamText(...)` and `generateText(...)` delegate to the runtime
   foundation.
3. Make `generateTextCall(...)` and `streamTextCall(...)` use the same
   foundation.
4. Update chat direct transport to use the runtime result projection.
5. Rename or split provider stream events.
6. Remove or alias runner helpers.
7. Update examples, docs, guards, and publish validation.

This keeps the user-facing migration coherent: users move toward fewer primary
helpers, while provider authors move toward a narrower model-call contract.
