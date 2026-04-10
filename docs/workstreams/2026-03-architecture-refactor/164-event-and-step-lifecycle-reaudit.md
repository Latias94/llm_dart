# 164 Event And Step Lifecycle Re-Audit

## Goal

Re-check the remaining event, step-lifecycle, and UI-stream gap against the
actual current `repo-ref/ai` implementation instead of relying only on the
earlier high-level comparison.

The practical question is now:

> after the recent `ChatUiStreamChunk` and narrow runner work, what is still
> worth aligning with the reference, and what should stay deliberately
> different?

## Short Answer

The remaining worthwhile gap is still **not more core event types**.

It is two higher-layer maturity gaps:

1. a more productized streamed multi-step orchestration layer above the raw
   model stream,
2. a lighter reusable UI-stream processing helper above `ChatUiStreamChunk` for
   consumers that do not want the full `DefaultChatSession`.

## What The Reference Actually Has

Reading the current `repo-ref/ai` code again makes three things very clear.

### 1. `generateText(...)` and `streamText(...)` already own orchestration

The reference `generateText(...)` path now owns more than a single provider
call:

- multi-step looping,
- `prepareStep`,
- tool execution callbacks,
- `onStepFinish`,
- final aggregated finish data.

That is why its top-level API can expose step hooks directly without becoming
misleading.

### 2. `UIMessageChunk` is a richer UI protocol, not a raw model event layer

The reference `UIMessageChunk` includes:

- text / reasoning chunk families,
- tool input / output availability markers,
- step markers,
- start / finish / abort,
- message metadata patches,
- `data-*` chunks.

But that layer is explicitly UI-stream protocol vocabulary, not the provider
stream specification.

### 3. The reference also has a reusable UI-stream processor layer

The reference does not stop at defining chunk types.

It also provides reusable helpers such as:

- `processUIMessageStream(...)`
- `readUIMessageStream(...)`
- `handleUIMessageStreamFinish(...)`

That is an important maturity signal:

- the useful gap is not only chunk names,
- it is also the existence of a reusable stateful processor above the chunk
  protocol.

## What `llm_dart` Already Has

Our current architecture is stronger than an older snapshot would suggest.

### 1. Shared raw event coverage is already sufficient

`TextStreamEvent` already covers the important shared model/session semantics:

- text,
- reasoning,
- reasoning files,
- tool input,
- malformed tool input,
- tool calls,
- tool results,
- approval requests,
- denied output,
- sources,
- files,
- step boundaries,
- finish,
- abort,
- errors.

So the shared core event layer is not the problem.

### 2. We already have a dedicated UI chunk layer

`ChatUiStreamChunk` now already separates:

- message start,
- message metadata patch,
- message finish,
- event chunk,
- data-part chunk,
- transient data-part chunk.

That means we already made the most important architectural move:

- UI/session transport concerns are no longer being forced back into
  `TextStreamEvent`.

### 3. We already have a reusable pure projection layer

`ChatUiStreamAccumulator` already gives us a reusable pure projection layer from
chunk stream to `ChatUiMessage`.

That is directionally similar to the reference stateful UI-stream processing
layer, even though the API shape is smaller.

### 4. We already have a narrow shared runner

`GenerateTextRunner` now already provides:

- `onStepStart`,
- `onStepFinish`,
- `onFinish`,
- multi-step common function-tool continuation,
- accumulated run result and total usage.

So the gap is no longer "we have no step lifecycle API".

The gap is now about the next layer of maturity above that first runner.

## Remaining Gaps Worth Caring About

After re-checking the actual current reference implementation, the remaining
worthwhile gaps are now these.

## 1. Streamed multi-step orchestration

The reference still has a more mature streamed orchestration path than we do.

Our current split is:

- `streamText(...)` stays single-step and raw,
- `GenerateTextRunner` is multi-step but non-streaming.

That split is still correct.

But the next real maturity gap is now clear:

- if we want repo-ref-level orchestration maturity, the next thing to evaluate
  is a streamed runner or streamed run result layer above `streamText(...)`,
- not more `TextStreamEvent` variants.

## 2. A lighter reusable UI-stream processing helper

The reference has a helper layer for consumers that want to:

- read a UI chunk stream,
- project it into message state,
- optionally observe step finish,
- optionally observe final finish,
- optionally react to tool-call availability,
- without committing to the full chat client abstraction.

In `llm_dart`, that role is currently split between:

- `ChatUiStreamAccumulator` for pure projection,
- `DefaultChatSession` for full session lifecycle, tool continuation, retry,
  reconnect, approval handling, and persistence-friendly state management.

That means we currently have:

- a small projector,
- a full session,
- but not yet a clearly reusable **middle helper** for non-session consumers.

This is now the most plausible UI-stream maturity gap worth revisiting.

## What Is *Not* A Real Gap

This re-audit also makes several non-gaps clearer.

## 1. We do not need to mirror `UIMessageChunk` exhaustively

The reference chunk protocol carries:

- `tool-input-available`
- `tool-output-available`
- `tool-output-error`

We already model those through shared event semantics plus `ToolUiPart` state.

Copying those chunk names one-to-one into our runtime chunk model would mostly
duplicate information we already carry cleanly through:

- `ChatUiEventChunk(TextStreamEvent)`
- `ChatUiAccumulator`
- `ToolUiPart`

So this is not the right next move.

## 2. We do not need more core events

The reference code re-confirms that the event-vocabulary temptation is the
wrong one.

Do not add:

- message start / finish events to `TextStreamEvent`,
- message metadata patch events to `TextStreamEvent`,
- tool-output-available or tool-output-error as new shared core events,
- a new per-tool-type UI part family in Dart core.

The current shared event model is already broad enough.

## 3. We should not move callback orchestration into the pure accumulator

The reference `processUIMessageStream(...)` is stateful and callback-aware.

That does not mean our pure `ChatUiStreamAccumulator` should become callback
heavy.

The accumulator should stay:

- deterministic,
- replay-friendly,
- side-effect free.

If we add a reusable middle helper later, it should live **above** the
accumulator, not inside it.

## Frozen Recommendation

The most useful frozen recommendation after this re-audit is:

1. keep `TextStreamEvent` stable,
2. keep `ChatUiStreamChunk` intentionally smaller than the reference
   `UIMessageChunk`,
3. keep `ChatUiStreamAccumulator` pure,
4. keep `DefaultChatSession` as the full orchestration/session path,
5. evaluate only two additive maturity layers next:
   - a streamed multi-step runner above raw model streams,
   - a lightweight UI-stream reader/finish-hook helper above
     `ChatUiStreamChunk`.

## Recommended Next Slice

If we want the best cost/benefit alignment with `repo-ref/ai`, the next slice
should **not** be "add more event types".

It should be one of these two:

### Option A: Streamed runner maturity

Add a streamed run result layer above the current single-step `streamText(...)`
boundary.

This is the better choice if the main goal is model orchestration parity.

### Option B: Lightweight UI-stream helper maturity

Add a reusable helper in `llm_dart_chat` that does something like:

- consume `Stream<ChatUiStreamChunk>`,
- maintain a `ChatUiMessage` state snapshot,
- optionally emit projected message updates,
- optionally call `onStepFinish`,
- optionally call final `onFinish`,
- without forcing callers to adopt `DefaultChatSession`.

This is the better choice if the main goal is easier Flutter or custom-client
integration over remote UI streams.

## Current Recommendation

Between those two, the higher-value next architectural move is still:

- **streamed runner maturity first**

because that is the larger structural gap versus the reference.

But if product work starts to need low-ceremony remote UI-stream consumption
without a full chat session runtime, then the lightweight UI-stream helper is a
good next additive layer and still much better than expanding the event model.
