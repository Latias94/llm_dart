# Event Completeness Audit

## Goal

This document freezes the current conclusion after comparing our event model with the `repo-ref/ai` provider stream parts and UI message chunks.

It answers one practical refactor question:

> Do we still need to widen `TextStreamEvent`, or is the remaining gap mostly a UI transport concern rather than a shared model-stream concern?

## 1. Reference Split In `repo-ref/ai`

The reference codebase has two different layers that are easy to conflate:

- provider stream parts such as `LanguageModelV4StreamPart`
- UI transport chunks such as `UIMessageChunk`

That distinction matters.

The provider stream layer already stays relatively small:

- `stream-start`
- `response-metadata`
- text start / delta / end
- reasoning start / delta / end
- tool input start / delta / end
- tool approval request
- tool call
- tool result
- source
- file
- reasoning-file
- finish
- raw
- error

The UI transport layer is where extra lifecycle vocabulary appears:

- `start`
- `finish`
- `message-metadata`
- `abort`
- `tool-input-available`
- `tool-output-available`
- `tool-output-error`
- `start-step`
- `finish-step`
- `data-*`

The main architectural lesson is:

- provider stream completeness and UI chunk completeness are not the same review target

## 2. Current `llm_dart` Status

Our current core event model already covers the shared provider-stream semantics well.

### Provider-Stream Parity

| Reference provider concept | Current `llm_dart` status | Conclusion |
| --- | --- | --- |
| `stream-start` | `StartEvent` | sufficient |
| `response-metadata` | `ResponseMetadataEvent` | sufficient |
| text start / delta / end | `TextStartEvent` / `TextDeltaEvent` / `TextEndEvent` | sufficient |
| reasoning start / delta / end | `ReasoningStartEvent` / `ReasoningDeltaEvent` / `ReasoningEndEvent` | sufficient |
| reasoning-file | `ReasoningFileEvent` | sufficient |
| tool input start / delta / end | `ToolInputStartEvent` / `ToolInputDeltaEvent` / `ToolInputEndEvent` | sufficient |
| malformed tool input | `ToolInputErrorEvent` | stronger than the older flattened error path |
| tool call | `ToolCallEvent` | sufficient |
| tool result | `ToolResultEvent` | sufficient |
| tool approval request | `ToolApprovalRequestEvent` | sufficient |
| denied output | `ToolOutputDeniedEvent` | sufficient |
| source | `SourceEvent` with typed `SourceReference` | sufficient |
| file | `FileEvent` with `GeneratedFile` | sufficient |
| finish | `FinishEvent` | sufficient |
| raw | `RawChunkEvent` | sufficient |
| error | `ErrorEvent` | sufficient |

This means the current `TextStreamEvent` surface is not materially behind the reference provider stream layer.

## 3. Where The Remaining Differences Actually Live

Most of the visible remaining differences are UI-transport concerns, not model-stream gaps.

### 1. UI Message Lifecycle Markers

The AI SDK uses transport chunks such as:

- `start`
- `finish`
- `message-metadata`
- `abort`

These are not provider output semantics.

They are session and transport protocol markers.

Recommended boundary:

- keep them out of `TextStreamEvent`
- if needed, carry them in `ChatTransportChunk` or future HTTP chat protocol revisions

### 2. Tool Availability And Output UI Chunks

The AI SDK UI stream uses:

- `tool-input-available`
- `tool-output-available`
- `tool-output-error`

In `llm_dart`, those are already represented through:

- `ToolCallEvent`
- `ToolResultEvent`
- `ToolInputErrorEvent`
- `ToolUiPart`

This Dart split is acceptable and should stay.

The extra AI SDK UI chunk names are projection-level states, not evidence that core needs new event classes.

### 3. Typed Tool UI Parts

The AI SDK uses:

- `tool-weather`
- `tool-search`
- `dynamic-tool`

The current Dart design keeps one `ToolUiPart` with:

- `toolName`
- `providerExecuted`
- `isDynamic`
- shared tool lifecycle state

That is still the better fit for this repository.

The reference pattern is useful for TypeScript inference, but it is not a good reason to fragment the Dart core UI model.

## 4. Step Boundary Decision

One important difference should be frozen explicitly.

The AI SDK places `start-step` and `finish-step` in the UI chunk layer.

`llm_dart` currently keeps:

- `StepStartEvent`
- `StepFinishEvent`

This is still acceptable for Dart.

Why:

- the step boundary is reused by `DefaultChatSession` during assistant-turn continuation
- follow-up tool or approval continuations can synthesize a new step boundary without inventing provider-owned wire detail
- snapshots and UI projection already persist those step boundaries cleanly

Recommended rule:

- keep `StepStartEvent` and `StepFinishEvent` in the shared Dart event layer
- do not treat their existence as a reason to copy the full AI SDK UI chunk protocol

In other words:

- step boundaries are shared session semantics in our architecture
- `start` / `finish` / `abort` remain transport semantics

## 5. What Should Not Be Added Now

Do not add new common core events just to mirror the reference UI chunk names.

Specifically, do not add:

- `MessageStartEvent`
- `MessageFinishEvent`
- `MessageMetadataPatchEvent`
- `AbortEvent`
- `ToolOutputAvailableEvent`
- `ToolOutputErrorEvent`
- typed `ToolWeatherUiPart` / `ToolSearchUiPart` style subclasses

Those would widen the core without solving a real shared provider-stream problem.

## 6. What The Next Work Actually Is

The next work is not event proliferation.

The next work is event coverage discipline.

### Current Provider Coverage Snapshot

The migrated provider packages already use a meaningful subset of the shared event surface:

| Provider package | Current emitted shared events | Current coverage note |
| --- | --- | --- |
| `llm_dart_openai` | response metadata, text, reasoning, source, tool input, malformed tool input, tool approval request, tool result, custom replay, finish, error | strong coverage for approval, malformed-input, reasoning-summary, and failed-response flows; no common file or reasoning-file events are expected from the current Responses stream mainline |
| `llm_dart_anthropic` | response metadata, text, reasoning, source, tool input, malformed tool input, tool result, custom replay, finish, error | strong coverage for provider-native replay families, with explicit malformed tool-input regression coverage; no common approval/file events are expected from the current Anthropic stream mainline |
| `llm_dart_google` | response metadata, text, reasoning, source, tool input, tool result, reasoning-file, file, finish | stream regression coverage now explicitly includes source, file, reasoning-file, and finish metadata paths |

One important practical observation:

- `StepStartEvent` and `StepFinishEvent` are currently more session-driven than provider-driven
- `DefaultChatSession` already synthesizes step boundaries for continued assistant turns
- that is another reason not to judge event completeness only by raw provider emission counts

Recommended next steps:

1. keep the current `TextStreamEvent` surface stable
2. expand provider coverage tests so migrated providers consistently emit the existing shared events when their wire protocols support them
3. keep provider-native execution and retrieval detail in provider-owned custom events and UI parts
4. extend transport-level protocols only when remote UI lifecycle markers or metadata patches are truly needed

This is a better use of the breaking window than introducing more core event types.

## 7. Review Rule

When a new event type is proposed, ask:

> Is this a cross-provider model or session semantic, or is it only a UI transport marker that the reference client happens to expose?

If it is only a UI transport marker, it should stay out of `TextStreamEvent`.
