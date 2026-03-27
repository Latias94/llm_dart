# Malformed Tool Input Design

## Background

`llm_dart` already models:

- streamed tool input text
- finalized tool input
- tool execution output
- tool execution output error

What it still does not model explicitly is:

- tool input that becomes invalid before any tool execution happens

This gap matters because invalid tool arguments are not the same thing as tool execution failure.

## What The Vercel AI SDK Actually Distinguishes

In `repo-ref/ai`, invalid tool input is emitted as a dedicated `tool-input-error` stream chunk.

That chunk carries:

- `toolCallId`
- `toolName`
- `input`
- `errorText`
- optional `providerExecuted`
- optional `dynamic`
- optional `title`
- optional provider metadata

Important nuance:

- the distinction is explicit at the event/chunk layer
- the UI layer does not necessarily need a brand-new state enum just to preserve that distinction
- the AI SDK currently projects `tool-input-error` into the existing tool error rendering path

That is the useful lesson for Dart: separate semantics first, then decide whether UI state needs a second-level distinction.

## Current Dart Gap

Today the Dart core can do the following:

- `ToolInputStartEvent`
- `ToolInputDeltaEvent`
- `ToolInputEndEvent`
- `ToolCallEvent`
- `ToolResultEvent(isError: true)`

That means two different failures can collapse together:

1. the tool input itself is malformed or validation fails before execution
2. the tool executed, but its output is an error

Those are different stages and should not share the same core event.

## Recommended Core Event

Add a first-class event:

```dart
final class ToolInputErrorEvent extends TextStreamEvent {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final String errorText;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final ProviderMetadata? providerMetadata;
}
```

Recommended meaning:

- the model or a validator produced a tool call candidate
- the tool input was malformed, incomplete, or schema-invalid
- no tool execution result exists yet

Rules:

- use `ToolInputErrorEvent` for pre-execution failure only
- keep `ToolResultEvent(isError: true)` for execution/result-stage failure only
- do not overload generic `ErrorEvent` when tool identity and invalid input are known

## UI Projection Recommendation

The first implementation round does not need a new `ToolUiPartState`.

Recommended projection:

- map `ToolInputErrorEvent` into the existing error rendering path
- keep `ToolUiPartState.outputError` for now
- preserve invalid input in `input` and/or `inputText` when available
- store `errorText` as the visible error payload

Why this is the pragmatic path:

- it preserves the important semantic distinction in the core stream model
- it avoids forcing a second breaking change into the Flutter UI state machine immediately
- it keeps the door open for a later `ToolErrorStage` or `ToolUiPartState.inputError` if real provider evidence demands it

## Provider Guidance

Providers or higher layers should emit `ToolInputErrorEvent` when:

- a provider returns malformed tool-call arguments
- streamed tool arguments never become valid structured input
- local schema validation fails before any tool execution starts

Providers should continue to emit generic `ErrorEvent` when:

- the failure has no tool identity
- the failure is transport-level or call-level rather than tool-input-level

## Recommended Implementation Scope

The next implementation round should update:

1. `TextStreamEvent`
2. `TextStreamEventJsonCodec`
3. `ChatUiAccumulator`
4. core tests for event serialization and UI projection
5. provider adapters only when they can genuinely identify malformed tool input

It should not immediately expand:

- prompt persistence
- chat transport wire markers
- UI-only chunk vocabularies

Those should remain separate from the core model-stream boundary.

## Decision Summary

The next breaking round should separate malformed tool input from tool execution failure at the core event layer.

It should not assume that this requires a new Flutter UI state enum in the same round.
