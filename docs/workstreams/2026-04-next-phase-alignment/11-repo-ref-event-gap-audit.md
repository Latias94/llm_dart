# Repo-Ref Event Gap Audit

## Goal

Re-check the current `llm_dart` event and UI stream layering against the
current `repo-ref/ai` implementation.

The question is no longer:

> should `llm_dart` add more shared stream events for symmetry?

The useful question is:

> after the transport, chat, and Flutter refactors already landed, is there
> still any missing structural layer or missing shared event family that
> blocks honest alignment with `repo-ref/ai`?

## Reference Reading

The current audit was re-checked against the reference repository files that
actually define the layering:

- `repo-ref/ai/packages/ai/src/generate-text/stream-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/core-events.ts`
- `repo-ref/ai/packages/ai/src/ui-message-stream/ui-message-chunks.ts`
- `repo-ref/ai/packages/ai/src/ui/process-ui-message-stream.ts`
- `repo-ref/ai/packages/ai/src/ui/chat.ts`

Those files confirm that the reference repository is still built around three
separate layers, not one:

1. model-facing streamed generation parts
2. UI/message stream chunks
3. accumulated UI messages and chat state

## What `repo-ref/ai` Actually Separates

### 1. Model Stream Layer

`streamText(...)` produces `TextStreamPart`.

That layer models:

- text start / delta / end
- reasoning start / delta / end
- tool input start / delta / end
- tool calls
- tool results
- tool errors
- tool approval requests
- denied tool outputs
- source and file parts
- start / finish / abort / raw / error
- step start / step finish markers

This is the normalized streamed generation layer.

### 2. UI Chunk Layer

`toUIMessageStream(...)` projects model stream parts into `UIMessageChunk`.

That layer adds UI/runtime protocol semantics such as:

- `start`
- `finish`
- `message-metadata`
- `tool-input-available`
- `tool-input-error`
- `tool-output-available`
- `tool-output-error`
- `data-*`
- `start-step`
- `finish-step`

This layer is richer than the model stream on purpose.

### 3. UI State Layer

`processUIMessageStream(...)` accumulates UI chunks into mutable UI message
state and chat runtime state.

That layer owns:

- partial tool-input parsing
- message metadata merging
- typed data-part validation
- active text/reasoning lanes
- tool invocation state transitions
- step-boundary state resets

The reference repository does not ask the model stream layer to do UI-runtime
jobs directly.

## What `llm_dart` Already Has Now

The important finding from the re-audit is that `llm_dart` already matches the
same three-layer shape in Dart-first form.

### 1. Shared Model Stream Layer

`llm_dart_core` already exposes `TextStreamEvent`.

That surface already covers:

- `StartEvent`
- `ResponseMetadataEvent`
- text start / delta / end
- reasoning start / delta / end
- reasoning-file
- tool input start / delta / end
- malformed tool input
- tool call
- tool result
- tool approval request
- denied tool output
- source / file
- step start / finish
- finish / abort / raw / error
- custom provider-owned events

This is already broad enough for the shared normalized generation stream.

### 2. Shared UI Chunk Layer

`llm_dart_core` already exposes `ChatUiStreamChunk` with:

- `ChatUiMessageStartChunk`
- `ChatUiMessageMetadataChunk`
- `ChatUiEventChunk`
- `ChatUiDataPartChunk`
- `ChatUiTransientDataPartChunk`
- `ChatUiMessageFinishChunk`

It now also exposes the transport-neutral projector
`projectTextStreamEventStream(...)`, so the `TextStreamEvent ->
ChatUiStreamChunk` mapping no longer needs to live only inside the HTTP server
adapter layer.

This is the same architectural middle layer that earlier workstreams argued
for, but now in implemented form rather than only design intent.

### 3. UI State / Session Layer

The next layer is already split above that:

- `ChatUiAccumulator`
- `ChatUiStreamAccumulator`
- `ChatUiStreamReader`
- `DefaultChatSession`
- `HttpChatTransport`
- `ChatController`

That means `llm_dart` no longer jumps directly from raw shared events into
Flutter/session state.

## Precise Differences That Still Exist

The re-audit does find differences, but they are not all real gaps.

### Difference 1: `repo-ref/ai` Has A Separate Model-Level `tool-error`

The reference stream layer distinguishes:

- `tool-result`
- `tool-error`

`llm_dart` intentionally models both through `ToolResultEvent`, using
`ToolResultContent.isError` to distinguish the error case.

### Decision

Do not add a separate shared `ToolErrorEvent`.

Reason:

- the current Dart model still preserves the semantic distinction
- UI state already maps `isError` into `ToolUiPartState.outputError`
- prompt replay already carries tool-result error state through
  `ToolResultPromptPart.isError`
- adding a second shared event family would mostly duplicate the same flow

This is a naming and normalization difference, not a missing capability.

### Difference 2: `repo-ref/ai` Step Parts Carry Richer Per-Step Payloads

The reference `start-step` / `finish-step` parts can carry request, response,
usage, warnings, and finish metadata directly in the stream.

`llm_dart` keeps `StepStartEvent` and `StepFinishEvent` intentionally narrow.
The richer per-step data already lives in:

- `GenerateTextStepStartEvent`
- `GenerateTextStepResult`
- `StreamTextRunResult.stepStream`
- runner callbacks such as `onStepStart` and `onStepFinish`

### Decision

Do not widen shared `TextStreamEvent` step markers yet.

Reason:

- local direct-call code already has a richer typed channel through runner
  callbacks and step results
- Flutter/chat transport flows mainly need step boundaries, not full request
  and response payload replay
- if remote UI delivery later needs richer step diagnostics, the safer home is
  a higher-level `ChatUiMessageMetadataChunk` or `DataUiPart`, not a wider
  shared event contract

This is a feature defer decision, not an architectural miss.

### Difference 3: `repo-ref/ai` Names More UI Chunk States Explicitly

The reference UI chunk layer has named chunk types such as:

- `tool-input-available`
- `tool-output-available`
- `tool-output-error`

`llm_dart` keeps the middle layer narrower:

- `ChatUiEventChunk` carries `TextStreamEvent`
- `ChatUiAccumulator` projects that into `ToolUiPartState`
- message lifecycle and metadata remain first-class chunk families

### Decision

Keep the current Dart design.

Reason:

- the current split is already honest
- it avoids duplicating text, reasoning, and tool vocabularies across two
  shared protocols
- tool state expansion remains localized to UI projection, not shared stream
  definitions

The reference repository uses a richer UI chunk vocabulary because its browser
client consumes that protocol directly. `llm_dart` already gets the same value
through chunk-plus-accumulator layering.

### Difference 4: `repo-ref/ai` Pushes Validation Into UI Stream Processing

The reference `processUIMessageStream(...)` validates:

- message metadata schemas
- typed `data-*` parts
- partial JSON tool-input updates

`llm_dart` currently has:

- JSON-safe message metadata patches
- typed `DataUiPart<T>`
- tool-input partial parsing in `ChatUiAccumulator`
- session and controller layers above that

### Decision

Treat this as a possible future ergonomics enhancement, not an event-surface
gap.

If stronger validation is needed later, it should likely arrive as additive
reader/session utilities, not as more shared event classes.

## What The Current Dart Design Gets Right

### 1. The Shared Event Surface Is Still Small And Honest

The current `TextStreamEvent` surface already captures the cross-provider
semantic subset without leaking transport-specific or UI-specific protocol
markers into shared core.

### 2. The Middle Layer Now Really Exists

This was the main historical gap versus `repo-ref/ai`.

It is no longer a future design direction. It already exists through
`ChatUiStreamChunk`, `ChatUiStreamAccumulator`, and `ChatUiStreamReader`.

### 3. Flutter-Friendly Chat Already Has The Right Ownership Split

The current stack is now:

1. provider and shared stream events
2. UI/session chunks
3. accumulated chat messages
4. chat session state
5. Flutter controller adapter

That is the right shape for chat apps.

## Real Remaining Improvement Targets

The useful remaining opportunities are above the shared event core.

### 1. Reader / Session Observation Ergonomics

If `llm_dart` wants to borrow more from the reference repository, the next
truthful candidate is richer reader-level or session-level observation helpers,
for example:

- additive message metadata validation hooks
- additive typed data-part validation hooks
- additive per-step observation helpers for UI code

### 2. Optional Remote Step Diagnostics

If real transport-backed products need per-step usage or provider diagnostics
in the UI, the next design pass should first explore:

- `ChatUiMessageMetadataChunk`
- additive `DataUiPart`
- transport-owned protocol additions

before widening `TextStreamEvent`.

### 3. Transport And Session Documentation

The architecture is already mostly correct. What still helps users is clearer
documentation about:

- when to consume `TextStreamEvent` directly
- when to consume `ChatUiStreamChunk`
- when to consume `ChatUiMessage` / `ChatState`

## Final Decision

The re-audit does **not** justify widening the shared event model again.

The current repository is already structurally aligned with the reference
repository's most important stream lesson:

1. normalized model stream
2. richer UI chunk protocol
3. accumulated UI/session state

The remaining differences are now mostly:

- naming choices
- richer browser-oriented UI chunk vocabulary in the reference repository
- richer per-step payloads in reference stream parts
- optional validation ergonomics above the current Dart reader/session layer

None of those require new shared event families today.

## Bottom Line

The event line remains frozen.

If this area reopens later, the most likely honest targets are:

- reader/session observation ergonomics
- transport-level step diagnostics
- additive validation helpers

The least honest next move would be widening `TextStreamEvent` for symmetry
alone.
