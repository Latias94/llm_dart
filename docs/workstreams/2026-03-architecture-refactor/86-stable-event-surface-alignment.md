# 86. Stable Event Surface Alignment

## Why Revisit The Event Surface

Earlier workstream notes correctly concluded that `llm_dart` should not copy the
entire `repo-ref/ai` UI chunk layer into the shared core. That conclusion still
stands.

However, the recent stable cancellation work exposed one narrow but important
gap:

- cancellation is now part of stable `CallOptions`
- Flutter chat sessions and HTTP chat transport already have an explicit abort
  concept
- shared `TextStreamEvent` still treated cancellation as either
  `FinishReason.aborted` or `ErrorEvent(code: transport-cancelled)`

That left the stable event model without a distinct "aborted, not failed"
signal, even though the surrounding layers already needed that distinction.

## Reference Comparison

Compared with `repo-ref/ai`:

- `llm_dart` already has strong normalized model-layer events for text,
  reasoning, tool input, tool calls/results, sources, files, custom parts, and
  terminal errors
- `llm_dart` already has a separate chat-UI projection layer through
  `ChatUiAccumulator`, `ChatUiMessage`, `llm_dart_chat`, and Flutter adapters
  in `llm_dart_flutter`
- `repo-ref/ai` still remains ahead in two areas:
  - explicit `abort` parts in the streamed text/result layer
  - a richer UI-stream chunk protocol with `start-step` / `finish-step`,
    `source-url` / `source-document`, and message-level start/finish metadata

The correct response is not to merge all of those concerns into one Dart model.
The correct response is to separate which gaps are truly shared-core concerns
and which belong to a future UI-stream layer.

## Decisions

### 1. Keep `TextStreamEvent` As The Shared Model-Layer Stream

`TextStreamEvent` remains the normalized shared event surface above provider
codecs and below Flutter/session/UI-specific transports.

It should continue to model:

- provider-normalized generation events
- replay-safe content and tool lifecycle boundaries
- terminal lifecycle outcomes that matter to app logic

It should not be widened into a UI transport chunk protocol.

### 2. Add A Narrow Shared `AbortEvent`

`AbortEvent` is justified as a shared core event because abort is not only a UI
transport concern:

- it can originate from stable shared cancellation
- it changes application-level control flow
- it is semantically different from a provider or transport failure

This is the narrow exception to the earlier "no more shared core events"
direction.

### 3. Keep `FinishEvent(finishReason: aborted)` For Compatibility

The stable surface should preserve the existing terminal contract:

- `AbortEvent(reason)` carries the explicit aborted signal
- `FinishEvent(finishReason: FinishReason.aborted)` still closes the turn

That pairing matches how `repo-ref/ai` can emit an abort signal while still
keeping downstream consumers on a terminal path. Existing consumers that only
look at `FinishEvent` continue to work.

### 4. Do Not Pull Full Step Metadata Into Core Yet

`repo-ref/ai` exposes `start-step` and `finish-step` parts with request,
response, warnings, usage, and provider metadata.

`llm_dart` should not rush that into the stable shared stream until a streamed
multi-step runner actually needs it. The next step there should be additive and
runner-driven, not speculative.

### 5. Keep Sources Normalized In Core

Core should keep:

- `SourceReference`
- `SourceReferenceKind.url`
- `SourceReferenceKind.document`

If a future UI-stream protocol wants separate `source-url` and
`source-document` chunks, that split should happen in the UI transport layer,
not by replacing the shared core source model.

### 6. Keep Tool Output Errors On The Existing Shared Path For Now

`repo-ref/ai` has distinct `tool-error` stream parts.

`llm_dart` already has:

- `ToolInputErrorEvent` for malformed or invalid tool input
- `ToolResultEvent(toolResult.isError == true)` for tool-output error states
- `ChatUiAccumulator` projection into `ToolUiPartState.outputError`

That is sufficient for now. The current architecture priority is explicit abort
semantics, not a larger tool-event split.

### 7. Plan A Separate Future UI Chunk Layer

The main remaining structural gap versus `repo-ref/ai` is not another provider
event family. It is a dedicated UI-stream chunk layer above `TextStreamEvent`.

That future layer can own:

- message start/finish chunks
- step start/finish chunks
- URL-vs-document source chunk shaping
- transport-friendly data parts
- resumable HTTP chat streaming semantics

## What Landed In This Pass

The alignment pass now adds the narrow missing shared-core piece:

- `AbortEvent(reason)` in `TextStreamEvent`
- `TextStreamEventJsonCodec` support for `abort`
- `ChatUiAccumulator` metadata tracking for:
  - `ChatUiMetadataKeys.isAborted`
  - `ChatUiMetadataKeys.abortReason`
- `HttpChatTransport` now emits `AbortEvent` before
  `FinishEvent(finishReason: aborted)`
- `DefaultChatSession.stop()` now mirrors the same order
- `ChatMessageMapper` now exposes `isAborted` and `abortReason`

## Remaining Follow-Up

The next event-surface steps should be:

1. Decide whether streamed multi-step orchestration really needs richer
   step-start/step-finish metadata in the shared core.
2. Design a dedicated UI chunk layer instead of stretching `TextStreamEvent`
   into transport/UI responsibilities.
3. Revisit whether provider-native streaming cancellation paths should emit
   `AbortEvent` directly instead of only surfacing `transport-cancelled`
   through `ErrorEvent`.
4. Revisit total-usage versus step-usage surfacing when shared streamed
   multi-step orchestration actually lands.

## Practical Outcome

The stable event model is still intentionally smaller than `repo-ref/ai`.

That difference remains deliberate.

The change here is narrower: `llm_dart` now explicitly acknowledges that
"aborted" is a first-class lifecycle outcome, not merely a special case of
"error" or a finish-reason detail hidden at the end of the stream.
