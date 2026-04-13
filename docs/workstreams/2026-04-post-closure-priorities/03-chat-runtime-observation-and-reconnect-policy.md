# Chat Runtime Observation And Reconnect Policy

## Purpose

This note closes the remaining runtime-helper question in the post-closure
phase:

- do transient `data-*`, step-finish observation, and reconnect semantics still
  justify widening shared UI/runtime helpers
- or is the current split already the right stable boundary

## Current Implemented Surface

The current runtime already exposes three distinct observation paths:

### 1. Persistent Message Projection

This is the durable assistant-message path:

- `ChatUiMessage`
- `ChatUiPart`
- `ChatUiDataPartChunk`
- `ChatUiMessageFinishChunk`
- `ChatSession.states`
- `ChatUiStreamReadResult.result`

This path is persisted, snapshot-safe, and replay-safe.

### 2. Transient Runtime Signals

This is the non-persistent side channel:

- `ChatUiTransientDataPartChunk`
- `ChatUiStreamReadResult.transientDataParts`
- `ChatSession.transientDataParts`

This path is intentionally not part of persisted message state.

### 3. Lightweight Step Observation

This is the narrow boundary marker path:

- `StepStartEvent`
- `StepFinishEvent`
- `ChatUiStreamReadResult.stepFinishStream`

This path is intentionally lighter than the full runner-facing step model.

## What The Code Actually Does Today

The current implementation and tests show four important facts.

### 1. Final Message Metadata Can Land After `FinishEvent`

`DefaultChatSession` intentionally does not finalize the assistant turn as soon
as it sees `FinishEvent`.

It waits for stream completion so that trailing transport-owned metadata patches
can still land through:

- `ChatUiMessageMetadataChunk`
- `ChatUiMessageFinishChunk`

That means final message metadata is allowed to arrive after the semantic model
finish event, and the session treats that as part of the same assistant turn.

### 2. Transient Data Is Runtime-Only By Default

Transient data currently:

- reaches `ChatUiStreamReader.transientDataParts`
- reaches `ChatSession.transientDataParts`
- does not mutate persisted `ChatUiMessage.parts`
- does not enter snapshots
- does not enter prompt history
- does not replay on reconnect by default

This is already the right split for:

- heartbeats
- short-lived progress pulses
- temporary status banners
- optimistic local hints

If an application wants durable UI state, it should emit a normal persisted
`DataUiPart` instead.

### 3. `stepFinishStream` Is A Reader-Level Convenience, Not A Session-Level Contract

`ChatUiStreamReader` exposes `stepFinishStream`, but `DefaultChatSession` does
not widen that into a new session API.

That is a good boundary:

- the reader is a chunk-consumption helper
- the session is the full conversation runtime

Session consumers already have richer app-facing signals through:

- `ChatState`
- assistant message snapshots
- persistent `StepBoundaryUiPart`
- tool and approval status in `ChatStatus`

The current repository does not show pressure for another step callback layer
on `ChatSession` or `ChatController`.

### 4. Reconnect Is A Transport-Level Recovery Contract

`HttpChatTransport` reconnect is currently based on:

- an in-memory `resumeToken`
- replayable persistent chunks collected in the transport
- a follow-up reconnect request carrying `chatId` plus `resumeToken`

The replay set currently includes:

- `message-start`
- `message-metadata`
- persistent `event`
- persistent `data-part`
- `message-finish`

The replay set intentionally excludes:

- `transport-start`
- `checkpoint`
- `keepalive`
- `transient-data-part`

That means reconnect is:

- transport-owned
- in-memory
- scoped to the current runtime process

It is not a durable restore-after-restart contract.

## Boundary Decision

The current runtime-observation split is good enough and should stay frozen for
now.

### Keep Persistent Message State Small And Honest

Persisted `ChatUiMessage` state should continue to hold only durable message
content and durable message metadata.

### Keep Transient Data On The Side Channel

Transient runtime signals should continue to flow through:

- `ChatUiTransientDataPartChunk`
- reader/session side streams

They should not be promoted into persisted message state by default.

### Keep Step Observation Narrow Above The Reader

`stepFinishStream` should remain a reader-level helper and should not grow into
another session/controller lifecycle surface unless repeated app integrations
prove that need.

### Keep Reconnect Transport-Owned

Reconnect should remain a transport capability:

- `ChatSession.resume()` only resumes an existing transport-owned in-flight
  turn
- it should not be treated as snapshot persistence or durable session restore
- any stronger durable resume model would need a separate product contract

## Reopen Threshold

This policy should only reopen if at least two concrete integrations show the
same missing runtime helper need.

Valid pressure signals would look like:

- repeated application wrappers reconstructing the same step-finish callback
  facade on top of `ChatSession`
- repeated demand for transient-data replay or persistence with the same
  semantics
- a real product need for restart-safe reconnect rather than current in-memory
  transport recovery

Absent that evidence, widening the runtime surface would mostly add lifecycle
complexity without clarifying ownership.

## Bottom Line

The worthwhile runtime adoptions are already in place:

- persistent message projection
- transient side-channel delivery
- narrow step-finish observation at the reader layer
- transport-owned reconnect

The next step is not another shared runtime helper expansion.
The next step is to keep this boundary small until real integration pressure
proves otherwise.
