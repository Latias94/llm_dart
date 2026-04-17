# Default Chat Session Diagnostics Seam

## Goal

Decide whether `DefaultChatSession` and the Flutter-facing `ChatController`
should now expose another app-facing diagnostics surface after the recent
reader-level observation and validation additions.

The question is not whether diagnostics are useful.

The question is which layer should own them.

## Short Answer

Do not add a new diagnostics API to `ChatSession` or `ChatController` now.

The current ownership split is already the honest one:

- durable runtime state belongs in `ChatState`
- transient runtime-only signals belong in `ChatSession.transientDataParts`
- direct chunk-consumer observation belongs in `ChatUiStreamReader`
- reconnect and replay diagnostics belong in transport
- provider-native or raw diagnostic payloads stay provider-owned

This boundary should remain frozen unless repeated real integrations prove that
session-level diagnostics are missing as a distinct product need.

## Current Public Surface

The app-facing runtime surface is intentionally small.

### `ChatSession`

Today `ChatSession` exposes:

- `state`
- `states`
- `transientDataParts`
- mutation and recovery actions such as `sendMessage(...)`, `regenerate()`,
  `respondToolApproval(...)`, `resume()`, `stop()`, and `clearError()`
- snapshot export through `exportSnapshot()`

That means session consumers already have:

- durable message snapshots
- runtime status transitions
- error visibility
- runtime-only transient UI data
- reconnect control

### `ChatController`

`ChatController` remains a thin Flutter adapter above `ChatSession`.

It mirrors:

- `state`
- `states`
- `error`
- `messages`
- `transientDataParts`
- the same command surface as the underlying session

It does not own another lifecycle model, and it should not start owning one
through a new diagnostics facade either.

## What The Current Code Already Proves

### 1. `DefaultChatSession` Already Uses The Reader Internally Without Re-Exporting It

`DefaultChatSession` reuses `ChatUiStreamReader` for chunk projection, but it
does not surface the reader's extra helper streams directly.

That is deliberate.

The reader is for direct `Stream<ChatUiStreamChunk>` consumption.
The session is for full conversation runtime orchestration.

If the session re-exported reader helpers mechanically, it would blur that
boundary again.

### 2. Durable App-Facing Diagnostics Already Have A Home

The existing session state already carries the durable app-facing diagnostics
that matter most:

- `ChatState.status`
- `ChatState.error`
- accumulated `ChatUiMessage` state
- durable message metadata already merged into those messages

This is the snapshot-safe and replay-safe layer.

If an app needs to render:

- the current assistant state
- tool progress
- approval waiting
- final finish status
- final message metadata

it already has the correct surface through `ChatState` and `ChatUiMessage`.

### 3. Runtime-Only Signals Already Have A Separate Side Channel

The current runtime already has one explicit non-persistent diagnostics seam:

- `ChatUiTransientDataPartChunk`
- `ChatUiStreamReader.transientDataParts`
- `ChatSession.transientDataParts`
- `ChatController.transientDataParts`

That is already the honest home for:

- short-lived progress pulses
- optimistic local hints
- temporary runtime banners
- non-persistent diagnostic markers

There is no clear evidence yet that another generic session diagnostics stream
would be cleaner than this existing side channel.

### 4. Reader-Level Observation And Validation Already Landed At The Right Layer

`ChatUiStreamReader` now exposes additive direct-consumer seams for:

- `stepEvents`
- `stepFinishStream`
- `messageMetadataValidator`
- `dataPartValidator`

Those are useful for callers that already own raw UI chunk streams.

They are not automatically session concerns.

Promoting them into `ChatSession` would force us to answer broader lifecycle
questions that the current architecture intentionally avoids:

- should step events replay for late listeners
- should they survive reconnect
- should validation failures surface as stream errors or session errors
- should controllers mirror them too
- should they be included in snapshots or persistence

Those are session-contract questions, not reader-helper questions.

### 5. Reconnect Diagnostics Are Already Transport-Owned

`ChatSession.resume()` is a recovery command, not a general diagnostics API.

The actual reconnect and replay mechanics remain transport-owned:

- transport replay chunk selection
- resume token management
- in-memory reconnect scope
- replay ordering and final metadata patch timing

If stronger reconnect diagnostics are ever needed, the first honest home is
transport or a transport-facing adapter, not `ChatSession`.

## Why Another Session Diagnostics API Would Be The Wrong Layer

### It Would Duplicate Existing Surfaces

A new `ChatSession.stepEvents`, `ChatSession.diagnostics`, or
`ChatController.diagnostics` stream would overlap with:

- `ChatState`
- `transientDataParts`
- reader-level step observation
- transport-owned reconnect behavior

That would create two half-overlapping ways to observe the same assistant turn.

### It Would Force Premature Replay And Persistence Decisions

The moment a diagnostics stream becomes part of `ChatSession`, we would need to
freeze answers for:

- replay semantics
- snapshot semantics
- reconnect semantics
- Flutter controller mirroring
- error propagation rules

The current repository does not show evidence that these rules are stable
enough to freeze.

### It Would Encourage The Wrong Direction Versus `repo-ref/ai`

The useful lesson from `repo-ref/ai` is not:

> push every observation seam into one chat-session facade

The useful lesson is:

- keep model stream, UI chunk, and accumulated chat state separate
- let direct stream consumers use richer stream-processing helpers
- keep higher-level chat/runtime abstractions smaller and more product-shaped

`llm_dart` is now already much closer to that separation.

Growing another session-level diagnostics surface would move in the opposite
direction.

## Frozen Ownership Map

The current diagnostics ownership should stay as follows.

### Keep In `ChatState` / `ChatSession`

- durable status transitions
- durable assistant message projection
- session-visible `ModelError`
- recovery control through `resume()`

### Keep In `ChatSession.transientDataParts`

- runtime-only transient `data-*` signals intended for app UI consumption

### Keep In `ChatUiStreamReader`

- step-boundary helper streams
- reader-level validation hooks
- direct chunk-consumer observation ergonomics

### Keep In Transport

- reconnect and replay mechanics
- resume token handling
- transport-owned recovery diagnostics

### Keep Provider-Owned

- raw provider payloads
- provider-native warnings or debug data
- provider-specific custom parts and metadata

## What Should Not Be Added Now

Do not add any of the following in this phase:

- `ChatSession.stepEvents`
- `ChatSession.stepFinishStream`
- `ChatSession.messageMetadataValidator`
- `ChatSession.dataPartValidator`
- `ChatSession.diagnostics`
- `ChatController.stepEvents`
- `ChatController.diagnostics`
- raw chunk passthrough on session or controller

These would widen the public runtime contract without enough evidence that the
new ownership is correct.

## Reopen Threshold

This decision should reopen only if repeated real integrations show the same
missing session-facing seam.

Valid signals would look like:

- at least two independent app integrations building the same diagnostics
  wrapper on top of `ChatSession`
- repeated need for session-level per-step diagnostics that cannot be handled
  cleanly by `ChatState`, `transientDataParts`, or direct reader usage
- a stable reconnect-diagnostics contract that is clearly transport-neutral and
  clearly app-facing

Absent that evidence, widening session/controller would mainly add lifecycle
surface area without clarifying ownership.

## Bottom Line

`DefaultChatSession` is already using the right lower-layer helpers internally.

That does not mean it should re-export all of them.

The correct freeze decision is:

- keep diagnostics layered
- keep reader extras below session
- keep transport recovery transport-owned
- keep app-facing runtime surface small until real product pressure appears
