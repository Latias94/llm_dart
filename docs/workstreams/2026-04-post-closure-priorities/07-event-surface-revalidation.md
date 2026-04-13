# 07 Event Surface Revalidation

## Why This Note Exists

The earlier architecture workstream already froze the broad conclusion that
`llm_dart` should not keep widening the shared event model just to mirror
`repo-ref/ai`.

This note revalidates that conclusion against the **current** reference code,
after the following pieces have also landed in `llm_dart`:

- `ChatUiStreamChunk`
- `ChatUiStreamReader` / `readChatUiStream(...)`
- `StreamTextRunner` / `streamTextRun(...)`
- the recent OpenAI stream-state and codec cleanup

The practical question is now:

> after re-checking the current reference code, is there still any meaningful
> missing shared event family in `llm_dart`?

## Short Answer

No.

The shared `TextStreamEvent` surface is already broad enough.

The remaining differences versus `repo-ref/ai` are either:

- UI-stream protocol choices,
- transport/message lifecycle markers,
- or provider-owned rendering/projection concerns.

Those should **not** trigger more shared core event types.

## What The Current Reference Actually Has

Re-checking the current `repo-ref/ai` source still shows two different layers.

### 1. Provider stream parts stay relatively small

The current `LanguageModelV4StreamPart` still centers on:

- `stream-start`
- `response-metadata`
- text start / delta / end
- reasoning start / delta / end
- tool input start / delta / end
- tool approval request
- tool call
- tool result
- custom content
- source / file / reasoning-file
- finish
- raw
- error

That is the provider-facing stream vocabulary.

### 2. UI message chunks are intentionally richer

The current `UIMessageChunk` also carries UI/runtime protocol concepts such as:

- `start`
- `finish`
- `message-metadata`
- `data-*`
- `tool-input-available`
- `tool-input-error`
- `tool-output-available`
- `tool-output-error`
- `tool-output-denied`
- `start-step`
- `finish-step`

Those are not proof that the provider-stream layer needs more event types.

They are evidence that the reference keeps a richer UI transport protocol above
the raw provider stream.

## What `llm_dart` Already Has Now

## 1. Shared provider-stream semantics are already covered

`TextStreamEvent` already covers:

- start
- response metadata
- text
- reasoning
- reasoning files
- tool input
- malformed tool input
- tool calls
- tool results
- approval requests
- denied outputs
- sources
- files
- step boundaries
- finish
- abort
- raw chunks
- errors

This is already at least as broad as the reference provider-stream layer, with
some deliberate shared-session additions.

## 2. UI and transport concerns already have a separate home

`llm_dart` no longer forces UI/runtime details back into the raw event layer.

That responsibility is already split across:

- `ChatUiStreamChunk`
- `ChatUiStreamAccumulator`
- `ChatUiStreamReader`
- `DefaultChatSession`
- transport-owned chat chunk codecs

So the old temptation to add message lifecycle events directly to
`TextStreamEvent` is no longer justified.

## 3. Orchestration maturity already has a separate home

The earlier remaining gap versus `repo-ref/ai` was step-aware streamed
orchestration.

That gap is no longer an event-model problem either, because the repository now
also has:

- `GenerateTextRunner`
- `StreamTextRunner`
- `GenerateTextStepResult`
- `GenerateTextStepStartEvent`

So step lifecycle pressure should continue to be resolved through runner or
UI/runtime layers, not by widening the shared event vocabulary.

## Boundary That Should Stay Frozen

Do **not** add new shared core events just to mirror current `UIMessageChunk`
names.

In particular, do **not** add shared-core equivalents for:

- `start`
- `finish`
- `message-metadata`
- `tool-input-available`
- `tool-output-available`
- `tool-output-error`

The current Dart split remains better:

- `ToolCallEvent` models finalized tool input availability
- `ToolResultEvent` models tool outputs, including `isError` and
  `preliminary`
- `ToolOutputDeniedEvent` covers explicit denied-output semantics
- UI/session lifecycle markers stay in chunk/runtime layers

## What Would Justify Reopening This Later

This question should only reopen if a **transport or server-facing**
requirement appears that needs tighter protocol parity with the reference UI
message stream.

Even then, the likely home is still:

- transport chunk codecs,
- server adapters,
- or a higher-level UI stream protocol,

not the shared `TextStreamEvent` model.

## Practical Next Priority

The next valuable work after this revalidation is still **not** more core
events.

The better next targets remain:

- provider-owned UI extension contracts,
- renderer and message-mapper guidance,
- chat-runtime observation and reconnect policy,
- and any provider-specific UI helpers justified by repeated use.

## Bottom Line

The event line is effectively closed again:

- the current reference does not expose a missing shared-core event family
- `llm_dart` already has the right split between raw events, UI chunks, and
  orchestration helpers
- any future parity work should happen above the shared event core, not inside
  it
