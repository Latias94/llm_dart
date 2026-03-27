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
| `source-url` / `source-document` | Only partially covered by generic `SourceReference` | Strengthen the source model |
| `file` | Covered by `FileEvent` and `GeneratedFile` | Freeze generic file model |
| `reasoning-file` | Not represented separately | Keep out of core for now; re-evaluate after a second provider needs it |
| `data-*` UI chunks | `DataUiPart<T>` exists, but there is no `TextStreamEvent` path | Keep UI-only; do not add to `TextStreamEvent` |
| `start` / `finish` / `message-metadata` / `abort` | Intentionally not in `TextStreamEvent` | Keep transport-only |
| `tool-input-error` | No first-class representation | Add explicit malformed-tool-input semantics in a future breaking round |

## 4. Real Gaps We Should Address

Not every mismatch with the AI SDK is a real gap.

The following items need explicit architectural decisions. `SourceReference` and malformed tool input remain open gaps. Approval-response reason was a real prompt/UI/session gap, but it is now implemented and should stay frozen.

### 1. `SourceReference` Is Too Loose

Today `SourceReference` is essentially:

- `sourceId`
- optional `uri`
- optional `title`
- optional `mediaType`
- optional provider metadata

That means callers have to infer source semantics from nullable fields.

Examples of ambiguity:

- a web citation and a retrieved document both become `SourceReference`
- a file-backed citation may have no `uri`, so the UI must guess whether it is a document source, a file artifact, or just an opaque reference

Recommended direction:

- strengthen `SourceReference` with an explicit source kind
- either use a sealed hierarchy or a small enum such as `url`, `document`, `file`, `other`
- keep provider metadata for provider-specific citation details

This is a good candidate for a near-term breaking change because it improves Flutter rendering and persistence without polluting the event model.

### 2. Approval Response Reason Is Now Preserved

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

### 3. Malformed Tool Input Should Not Collapse Into Generic Stream Failure

The AI SDK distinguishes tool input failure from tool output failure.

The current Dart core can represent:

- streamed tool input
- final tool call input
- tool execution output error

But it cannot represent a distinct "the tool call input itself is invalid" state.

That matters when:

- a provider emits malformed tool-call arguments
- partial tool arguments never become valid structured input
- tool validation fails before any tool execution happens

Recommended direction:

- add a first-class malformed-input concept, for example `ToolInputErrorEvent`
- evolve `ToolUiPart` so tool error state is not limited to output failure only
- keep `ToolResultEvent(isError: true)` for execution/result-stage errors

This is the strongest candidate for a future core-event addition.

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
- if streaming data parts are needed later, add them to the transport/UI stream layer instead

### 2. Message Start / Finish / Metadata Patch / Abort Markers

These remain transport-level or session-level concerns:

- chat transport request lifecycle
- reconnect bookkeeping
- UI message metadata patches
- abort markers

They should stay in `HttpChatTransport` protocol design, not in core events.

### 3. Full UI-Chunk Mirroring

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

### 2. Keep Generic Files

Do not split files into many common part kinds unless multiple providers genuinely need the distinction.

For now:

- keep one `GeneratedFile`
- keep one `FileEvent`
- keep one `FileUiPart`

If a provider later needs special reasoning-file handling, that can be revisited with real evidence.

## 7. Recommended Next Breaking-Round Scope

If the repository wants to tighten the event/UI model next, the recommended order is:

1. strengthen `SourceReference` with an explicit source kind
2. design malformed-tool-input semantics and decide whether that becomes `ToolInputErrorEvent`
3. define how UI-only data parts should enter `ChatSession` and `HttpChatTransport` without expanding `TextStreamEvent`
4. only after that, re-evaluate whether reasoning-file needs a common model

## 8. Conclusion

The main conclusion is not that `llm_dart` lacks many events.

The main conclusion is:

- most of the important model-stream semantics are already present
- the remaining gaps are concentrated around source typing, malformed tool input, and UI-only data ingress design
- the biggest temptation to avoid is copying UI transport concepts such as message markers or data chunks into `TextStreamEvent`
- the current Dart-specific strengths, especially unified tool parts and richer file references, should be preserved
