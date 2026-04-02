# 87. Dedicated UI Stream Chunk Layer

## Why This Needs A Separate Design Pass

The recent event-surface alignment closed the narrow shared-core gap that was
actually justified:

- `AbortEvent` now exists in `TextStreamEvent`
- Flutter transport and session code can now distinguish aborted turns from
  generic failures

That fix does **not** remove the larger remaining architectural gap versus
`repo-ref/ai`.

The remaining gap is no longer "missing core provider events".

The remaining gap is that `llm_dart` still lacks a dedicated incremental
UI/session stream layer **above** `TextStreamEvent` and **below**
`ChatUiMessage`.

Today, that missing layer shows up in several small but persistent symptoms:

- `HttpChatTransportStartChunk` mixes transport control (`requestId`,
  `resumeToken`) with message concerns (`messageId`)
- `DefaultChatSession` still consumes a transport-owned chunk type instead of a
  UI/session-owned chunk type
- remote message metadata patches do not have a first-class path
- remote message IDs are still transport details instead of explicit session
  inputs
- HTTP transport sometimes needs to synthesize shared events just to express
  message-lifecycle or transport-lifecycle boundaries cleanly

## Reference Lesson From `repo-ref/ai`

The useful lesson from `repo-ref/ai` is not "copy every UI chunk name".

The useful lesson is the layering split:

1. provider stream parts
2. incremental UI/message chunks
3. accumulated UI messages

For `llm_dart`, the matching split should become:

1. `TextStreamEvent`
2. `ChatUiStreamChunk`
3. `ChatUiMessage`

That means the repository should keep:

- `TextStreamEvent` as the normalized provider/session model stream
- `ChatUiMessage` as the accumulated render-oriented message

And it should add:

- a dedicated `ChatUiStreamChunk` layer for message/session streaming semantics

## Current Layering Problem

Right now, the stack is uneven:

- `TextStreamEvent` is shared and stable
- `ChatUiMessage` is shared and stable
- the middle layer is missing

Instead, the current code jumps from:

- `TextStreamEvent`
- plus transport-specific `ChatTransportChunk`
- straight into `DefaultChatSession`

This forces one type to carry several unrelated responsibilities:

- model events
- UI-only data ingress
- remote transport lifecycle
- reconnect bookkeeping
- server-chosen message identity

That is the exact type of coupling the refactor is trying to remove.

## Frozen Design Direction

### 1. Add A Dedicated `ChatUiStreamChunk` Layer

The repository should add a dedicated UI/session chunk model above
`TextStreamEvent`.

This is not a provider-wire model.
This is not an HTTP-only model.

It is the incremental runtime layer used by chat session and UI projection.

### 2. Keep `TextStreamEvent` Narrow

`TextStreamEvent` must remain the shared normalized model stream for:

- text
- reasoning
- tool input and tool results
- sources
- files
- step boundaries
- finish and abort semantics
- errors

The new UI chunk layer should not duplicate those model semantics with a second
set of text/tool/reasoning event classes.

### 3. Put The UI Chunk Model In The Shared UI Layer, Not The HTTP Codec Layer

The recommended ownership split is:

- `llm_dart_core`
  - `TextStreamEvent`
  - `ChatUiMessage`
  - `ChatUiAccumulator`
  - future `ChatUiStreamChunk`
  - future `ChatUiStreamAccumulator` or equivalent projector
- `llm_dart_chat`
  - `ChatSession`
  - `ChatTransport`
  - `HttpChatTransport`
  - transport reconnect state
- `llm_dart_transport`
  - HTTP request/chunk codecs

Reason:

- the chunk model is still pure Dart and UI-facing
- it should be reusable by direct transport and HTTP transport
- only the wire envelope, checkpoint control, and reconnect protocol are truly
  HTTP transport concerns

### 4. The UI Chunk Layer Should Be Additive, Not A Copy Of `repo-ref/ai`

The right Dart design is narrower than `repo-ref/ai`.

Recommended initial chunk families:

- `message-start`
- `message-metadata`
- `event`
- `data-part`
- `message-finish`

Where:

- `event` carries one `TextStreamEvent`
- `data-part` carries one `DataUiPart<Object?>`
- `message-start`, `message-metadata`, and `message-finish` carry
  UI/session-level message lifecycle data

This gives us the missing middle layer without duplicating text, reasoning,
tool, source, and file chunk vocabularies.

## Recommended `ChatUiStreamChunk` Contract

### `message-start`

Purpose:

- declare the assistant message boundary explicitly
- allow remote/server-owned message IDs
- optionally attach initial message metadata

Recommended fields:

- `messageId`
- optional JSON-safe `metadata`

Rules:

- direct transport may omit `message-start` and let the session keep its local
  generated message ID
- remote transports should emit `message-start` whenever the backend owns the
  authoritative assistant message ID or wants to seed metadata early

### `message-metadata`

Purpose:

- patch accumulated `ChatUiMessage.metadata` without abusing shared model events

Recommended fields:

- JSON-safe `metadata`

Rules:

- phase 1 should support merge-only semantics
- deleting metadata keys should not be part of the first design
- metadata patches may appear before or after the terminal `FinishEvent`

This is the clean answer to the current "where should delayed remote message
metadata live?" problem.

### `event`

Purpose:

- carry one `TextStreamEvent`

Rules:

- this remains the primary path for normalized shared model semantics
- `AbortEvent` and `FinishEvent` continue to travel here
- step boundaries remain shared event semantics in Dart and do not move into a
  second step-specific UI chunk vocabulary

### `data-part`

Purpose:

- carry one `DataUiPart<Object?>`

Rules:

- remains UI/session-only
- never enters prompt history
- keeps current upsert-by-`key + id` semantics

### `message-finish`

Purpose:

- mark the end of message-stream delivery independently from
  `FinishEvent`-as-model-semantic
- optionally carry a final metadata patch

Rules:

- does not replace `FinishEvent`
- session state should still derive terminal model outcomes from
  `FinishEvent`, `AbortEvent`, or `ErrorEvent`
- `message-finish` is about message-stream closure and final metadata
  finalization, not about redefining model finish semantics

## Why This Layer Is Better Than Widening `TextStreamEvent`

This keeps responsibilities aligned:

- `TextStreamEvent` remains about model/session semantics
- `ChatUiStreamChunk` becomes the incremental UI/session boundary
- `ChatUiMessage` remains the accumulated render state

It also solves the actual remaining problems without inventing more shared core
events:

- remote message IDs get a real place to enter
- delayed metadata patches get a real place to enter
- transport start/checkpoint/keepalive no longer need to leak toward session
- `DefaultChatSession` can stop treating transport-owned chunks as its runtime
  state protocol

## Relationship To HTTP Transport

This design also clarifies that there are **two** chunk layers, not one:

1. session-facing UI chunks
2. wire-facing HTTP chunks

The HTTP wire protocol should remain a separate concern.

That means:

- `checkpoint`
- `keepalive`
- transport-level request identifiers
- reconnect tokens
- wire-format compatibility

should stay in the HTTP transport protocol, not in the shared UI chunk model.

## Recommended HTTP Protocol Evolution

The current HTTP chat protocol can stay as a stable baseline.

However, the next protocol revision should stop mixing message and transport
control in one `start` chunk.

Recommended direction for a future richer protocol revision:

- `transport-start`
- `message-start`
- `message-metadata`
- `event`
- `data-part`
- `message-finish`
- `checkpoint`
- `keepalive`
- `error`

Notes:

- the existing `abort` wire chunk should remain decode-compatible for the
  current protocol
- a richer protocol revision should prefer explicit `AbortEvent` in `event`
  chunks plus normal message finalization instead of inventing another runtime
  abort channel
- `checkpoint` and `keepalive` remain transport-only, not session-visible UI
  chunks

## Session-Side Refactor Direction

`DefaultChatSession` should eventually stop consuming transport-owned chunk
types directly.

Recommended direction:

1. add `ChatUiStreamChunk`
2. add a small UI-stream projector/accumulator that understands:
   - message ID updates
   - metadata merge patches
   - `TextStreamEvent` application through `ChatUiAccumulator`
   - `DataUiPart` application
3. let `DirectChatTransport` and `HttpChatTransport` both emit the same
   session-facing chunk family
4. keep HTTP wire-control chunks hidden inside `HttpChatTransport`

This keeps `DefaultChatSession` focused on:

- prompt history
- tool continuation
- approval handling
- snapshot/export behavior
- chat status transitions

instead of also being the glue code for transport/wire chunk interpretation.

## Backward-Compatibility Strategy

The repository does not need to replace everything in one step.

Recommended migration order:

1. freeze this dedicated UI chunk design
2. add `ChatUiStreamChunk` as a new additive API
3. add adapters:
   - `TextStreamEvent -> ChatUiStreamChunk`
   - `HttpChatTransportChunk -> ChatUiStreamChunk`
4. migrate `DefaultChatSession` to the new runtime chunk model
5. only then decide whether `ChatTransportChunk` should be deprecated or
   removed in the breaking round
6. optionally introduce an HTTP transport protocol v2 after the runtime model
   has proven stable

## What This Design Deliberately Does Not Do

This design does **not**:

- copy the full `repo-ref/ai` UI chunk vocabulary into Dart
- replace shared `TextStreamEvent` text/tool/reasoning semantics
- move step boundaries out of the shared Dart event layer
- push reconnect checkpoints or keepalive markers into `llm_dart_core`
- make provider-specific UI payloads shared-core concepts

## Practical Outcome

The next maturity step for `llm_dart` is no longer "more events in core".

It is:

- a dedicated UI/session chunk layer above `TextStreamEvent`
- a cleaner split between session runtime chunks and HTTP wire chunks
- an eventual session refactor that consumes that dedicated runtime layer

That is the architecture move that gets `llm_dart` closer to the structural
strength of `repo-ref/ai` without sacrificing the Dart-specific strengths of
the current design.
