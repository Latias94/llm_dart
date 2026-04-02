# Event And UI Projection Gap Analysis

## Goal

This document compares the current `llm_dart` event and UI projection design with the Vercel AI SDK message-stream design.

The purpose is not to copy the full AI SDK UI chunk protocol. The purpose is to decide:

- which concepts are already covered well enough in `llm_dart`
- which concepts should become stable core concepts
- which concepts should remain transport-only or UI-only
- which parts of the current Dart design are worth preserving on purpose

## 1. Reference Framing

The Vercel AI SDK has three useful ideas in this area:

1. it separates model messages from UI messages
2. it has a rich incremental UI stream vocabulary
3. it treats transport-level message markers separately from model semantics

For `llm_dart`, only the first and third ideas should be copied directly.

The second idea should be used as a signal, not as a one-to-one shape to mirror in `TextStreamEvent`.

That means:

- `TextStreamEvent` should keep representing cross-provider model stream semantics
- `HttpChatTransport` may use a richer transport protocol for UI/session concerns
- `ChatUiAccumulator` remains the reusable projector from model semantics to UI state

## 2. What The Current Dart Design Already Gets Right

Compared with the AI SDK reference, several current choices should be preserved:

### 1. Unified `ToolUiPart`

The AI SDK uses TypeScript unions such as `tool-weather`, `tool-search`, and `dynamic-tool`.

That design is useful in TypeScript because the tool name can drive static type inference. In Dart, that benefit is much weaker, while the runtime API becomes more fragmented.

The current Dart design is better for this codebase:

- keep one `ToolUiPart`
- keep `toolName` as data
- keep `isDynamic` as a capability flag
- keep one shared state machine for provider-executed and client-executed tools

This matches the library goal of a unified interface with provider-specific details still preserved when needed.

### 2. `GeneratedFile` As A Runtime Object

The AI SDK UI parts use URL-based file references only.

The current Dart design supports:

- `uri`
- `bytes`
- optional `filename`

That is a better fit for Flutter and pure Dart use cases:

- local/offline previews
- mobile attachments
- in-memory generated artifacts
- tests that do not depend on hosted URLs

This should be preserved.

### 3. Payload-Carrying Custom Parts

The AI SDK custom UI part mainly carries `kind`.

The current Dart design already supports:

- `CustomEvent(kind, data, providerMetadata)`
- `CustomContentPart(kind, data, providerMetadata)`
- `CustomUiPart(kind, data, providerMetadata)`

That is useful and should stay, because provider-native blocks often need both a semantic key and a JSON-safe payload.

## 3. Coverage Matrix

The table below compares the AI SDK UI chunk vocabulary with the current `llm_dart` core model.

| Reference concept | Current `llm_dart` status | Recommendation |
| --- | --- | --- |
| `text-start` / `text-delta` / `text-end` | Covered by `TextStartEvent`, `TextDeltaEvent`, `TextEndEvent` | Freeze as-is |
| `reasoning-start` / `reasoning-delta` / `reasoning-end` | Covered by reasoning start/delta/end events | Freeze as-is |
| `tool-input-start` / `tool-input-delta` / final input available | Covered by `ToolInputStartEvent`, `ToolInputDeltaEvent`, `ToolInputEndEvent`, and `ToolCallEvent` | Freeze as-is |
| `tool-output-available` | Covered by `ToolResultEvent(isError: false)` | Freeze as-is |
| `tool-output-error` | Covered by `ToolResultEvent(isError: true)` | Freeze result-level error as-is |
| `tool-approval-request` | Covered by `ToolApprovalRequestEvent` and approval state in `ToolUiPart` | Freeze as-is |
| `tool-output-denied` | Covered by `ToolOutputDeniedEvent` | Freeze as-is |
| `start-step` / `finish-step` | Covered by `StepStartEvent` and `StepFinishEvent` | Freeze as-is |
| `source-url` / `source-document` | Covered by typed `SourceReference` (`kind` plus optional `filename`) | Freeze the updated source model |
| `file` | Covered by `FileEvent` and `GeneratedFile` | Freeze generic file model |
| `reasoning-file` | Covered by `ReasoningFileEvent` and `ReasoningFileUiPart` | Freeze as-is |
| `data-*` UI chunks | Covered by `DataUiPart<T>`, `ChatTransportDataPartChunk`, and `ChatSession.addDataPart(...)` | Freeze the transport/UI-only boundary; do not add to `TextStreamEvent` |
| `start` / `finish` / `message-metadata` | Covered by `ChatUiMessageStartChunk`, `ChatUiMessageMetadataChunk`, and `ChatUiMessageFinishChunk` | Keep transport/UI-only |
| `abort` | Covered by shared `AbortEvent` plus transport-level abort chunks | Freeze as the narrow shared session-lifecycle exception |
| `tool-input-error` | Covered by `ToolInputErrorEvent`, projected through the existing tool error UI path | Freeze the current event/UI split |

## 4. Historical Gaps And Their Current Status

Not every mismatch with the AI SDK is a real gap.

The following items were the important review targets in this area. They are now
either resolved or narrowed enough to freeze.

### 1. `reasoning-file` Was A Real Common Gap And Is Now Resolved

The current implementation now preserves:

- `ReasoningFilePromptPart`
- `ReasoningFileContentPart`
- `ReasoningFileEvent`
- `ReasoningFileUiPart`

Boundary rule:

- keep one shared `GeneratedFile` payload object
- distinguish reasoning-vs-final output by the wrapper part or event type

This item is no longer an open event/UI gap.

### 2. Assistant Replay Fidelity Is No Longer The Same Structural Gap

The current implementation now preserves:

- reasoning parts in assistant replay
- reasoning files in assistant replay
- replayable custom parts in assistant replay
- part-level `ProviderMetadata` on replayable prompt parts

Current boundary:

- assistant prompt history should preserve replayable assistant semantics
- citations, UI-only data parts, and transport markers still stay out of prompt
  history
- remaining lossiness is now mostly provider-owned replay policy, not a shared
  event/UI-model flaw

This item is no longer an open event/UI gap.

### 3. `SourceReference` Is Now Explicitly Typed

The current implementation now preserves:

- explicit `kind`
- stable `sourceId`
- optional `uri`
- optional `title`
- optional `filename`
- optional `mediaType`
- optional provider metadata

Current boundary:

- common kinds are `url`, `document`, and `other`
- document citations may carry `filename` without forcing provider metadata inspection
- generated artifacts still belong in `GeneratedFile`, not in `SourceReference`

This item is no longer an open event/UI gap.

### 4. UI-Only Data Ingress Is Now Defined

The current implementation now preserves a separate UI-only data path:

- `DataUiPart<T>` has an optional stable `id`
- `ChatTransport` now carries `ChatTransportEventChunk` and `ChatTransportDataPartChunk`
- `ChatSession.addDataPart(...)` supports local UI-only ingress without mutating prompt history
- `HttpChatTransport` serializes `data-part` chunks and replays them during reconnect recovery

Current boundary:

- do not add `DataEvent` to `TextStreamEvent`
- keep provider model streams producing only model semantics
- keep `data-part` as a session/transport concern
- upsert only when both `key` and `id` match; otherwise append
- snapshots keep data parts, prompt history does not

This item is no longer an open event/UI gap.

### 5. Approval Response Reason Is Now Preserved

The current implementation now preserves:

- approval ID
- approved / denied
- optional `reason`

That preservation now exists across:

- `ToolApprovalResponse` in the session API
- `ToolApprovalResponsePromptPart` and prompt persistence
- `ToolApprovalUiState` and snapshot/UI persistence

Boundary rule:

- keep approval request as a separate concept from approval response
- preserve `reason` locally even when a provider continuation protocol does not define a reason field

Provider note:

- OpenAI Responses currently exposes approval continuation fields for request ID and approve/deny only
- adapters should therefore preserve `reason` in prompt/session/UI state without inventing unsupported upstream wire fields

This item is no longer an open event/UI gap.

### 6. Malformed Tool Input Is Now Represented Explicitly

The current implementation now preserves a dedicated pre-execution failure event:

- `ToolInputErrorEvent`

Current boundary:

- use `ToolInputErrorEvent` when the tool input itself is malformed or validation fails before execution
- keep `ToolResultEvent(isError: true)` for execution/result-stage failures
- keep the first Flutter projection round on the existing `ToolUiPartState.outputError` path instead of introducing a second UI error state immediately

This item is no longer an open event/UI gap.

## 5. Areas That Should Stay Out Of `TextStreamEvent`

The following concepts may be useful in chat transports or UI protocols, but they should not be promoted into the model stream boundary:

### 1. UI Data Parts

`DataUiPart<T>` already exists in the UI layer.

That is acceptable, but it should be treated as:

- app-owned or transport-owned UI state
- not model output by default
- not something every direct model stream must understand

Recommended rule:

- do not add `DataEvent` to `TextStreamEvent`
- use transport/session data-part ingress for streaming UI-only data instead

### 2. Message Start / Finish / Metadata Patch Markers

These remain transport-level or session-level concerns:

- chat transport request lifecycle
- reconnect bookkeeping
- UI message metadata patches

They should stay in `HttpChatTransport` protocol design, not in core events.

### 3. Abort Semantics

`AbortEvent` is the one narrow shared lifecycle exception that is now justified.

Why:

- local stop flows already need a first-class aborted lifecycle signal
- `FinishEvent(finishReason: aborted)` remains the terminal compatibility
  signal, but it is not enough on its own for all projection and session flows
- the transport protocol may still carry an explicit abort chunk without making
  abort purely transport-owned

Boundary rule:

- keep `AbortEvent` in the shared Dart event model
- do not widen that into a broader family of message lifecycle events
- keep message start / finish / metadata markers in transport-only chunk layers

### 4. Full UI-Chunk Mirroring

The AI SDK UI stream has a broader vocabulary because it is a client/server UI transport.

`llm_dart` should keep using:

- `TextStreamEvent` for model semantics
- `ChatUiAccumulator` for projection
- transport-specific chunk protocols only when needed

That boundary is one of the main reasons the current refactor is cleaner than the old architecture.

## 6. Areas That Should Stay Unified In Dart

The AI SDK reference should not push `llm_dart` into over-specializing the Dart API.

### 1. Keep Unified Tool Parts

Do not mirror TypeScript-style `tool-{name}` part types in Dart core.

Recommendation:

- keep one `ToolUiPart`
- keep one `ToolCallContent`
- preserve `toolName`, `providerExecuted`, `isDynamic`, `title`, and lifecycle metadata as fields

### 2. Keep One Shared File Payload

Do not create many different file payload objects.

Recommended rule:

- keep one `GeneratedFile`
- keep one normal `File*` family for final user-visible artifacts
- add one `ReasoningFile*` family for reasoning-only artifacts because real provider evidence now exists
- do not create further file subfamilies until more providers justify them

## 7. Recommended Next Breaking-Round Scope

If the repository wants to tighten the event/UI model next, the recommended order is:

1. add a common `ReasoningFile*` family across prompt, result, stream, and UI layers
2. add part-level provider metadata to replayable prompt parts and make assistant replay fidelity a first-class boundary
3. keep future Flutter convenience layers such as `ChatController` above the current session/transport boundary instead of widening `TextStreamEvent`

## 8. Conclusion

The main conclusion is not that `llm_dart` lacks many events.

The main conclusion is:

- most of the important model-stream semantics are already present
- the largest remaining event/UI gap, UI-only data ingress, is now resolved without expanding `TextStreamEvent`
- the remaining missing common event family with real provider evidence is `reasoning-file`
- the deeper remaining gap is assistant replay fidelity, not transport chunk vocabulary
- the biggest temptation to avoid is copying UI transport concepts such as message markers or data chunks into `TextStreamEvent`
- the current Dart-specific strengths, especially unified tool parts and richer file references, should be preserved
