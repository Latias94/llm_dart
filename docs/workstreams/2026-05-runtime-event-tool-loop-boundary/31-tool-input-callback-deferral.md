# Tool Input Callback Deferral

Date: 2026-05-13
Status: deferred

## Decision

Do not add dedicated tool-input streaming callbacks in this architecture slice.

Tool input streaming is already represented in the runtime full stream:

- `ToolInputStartEvent`
- `ToolInputDeltaEvent`
- `ToolInputEndEvent`
- `ToolInputErrorEvent`

Callers that need to observe tool input chunks should use:

- `streamText(...)` / `streamTextRun(...)` event streams
- `StreamTextOnChunk` / `onChunk`
- `chatUiStream(...)` or chat UI projection when rendering tool input state

## Why This Is Deferred

Adding `onToolInputStart`, `onToolInputDelta`, `onToolInputEnd`, and
`onToolInputError` now would duplicate the existing full-stream event surface.
It would also freeze another callback vocabulary before the runtime context,
tool context, dynamic tool, and approval continuation semantics are settled.

The current callback layer is intentionally scoped to local runtime execution:

- `onToolStart`
- `onToolFinish`

Those callbacks observe work done by the Dart runtime. Tool input streaming is
provider/model-call output that already flows through `TextStreamEvent`.

## Revisit Criteria

Dedicated tool-input callbacks can be reconsidered if real users need callback
ergonomics that cannot be served by `onChunk` without fragile event filtering.
If they are added later, they should be derived from the full stream rather
than implemented as a separate provider or chat path.

## Validation

Existing runtime and UI code already consumes tool input stream events:

- result accumulation turns tool input chunks into tool calls
- chat UI projection updates tool parts from tool input events
- stream JSON serialization covers tool input events

No code change is needed for this decision.
