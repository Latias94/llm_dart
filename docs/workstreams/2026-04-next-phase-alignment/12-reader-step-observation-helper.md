# Reader Step Observation Helper

## Goal

Add a small reader-level observation improvement above `ChatUiStreamChunk`
without reopening any of the already-frozen boundaries around:

- shared event expansion
- callback-heavy `readChatUiStream(...)` facades
- session-level lifecycle growth

## Why This Is Worth Adding

The current repository already had:

- persistent message snapshots through `ChatUiStreamReadResult` itself
- `stepFinishStream`
- `transientDataParts`
- final-message access through `result`

That was enough for minimal direct consumption, but it still left one small
ergonomics gap:

- there was no single reader-level stream for both `StepStartEvent` and
  `StepFinishEvent`
- code that wanted both boundaries had to combine raw message snapshots with
  `stepFinishStream` manually

This is a real but narrow gap.

It does **not** justify:

- a new shared event family
- a session/controller lifecycle API
- a callback-first wrapper

## Implemented Shape

`ChatUiStreamReader` and `ChatUiStreamReadResult` now also expose:

- `stepEvents`

The new side stream emits `ChatUiStepObservation`, which carries:

- `phase`
  - `start`
  - `finish`
- `stepId`
- the projected `ChatUiMessage` snapshot at that boundary

The existing `stepFinishStream` remains unchanged for callers that only want
the old finish-only convenience path.

## Why This Does Not Reopen The Old Facade Decision

The earlier freeze rejected two specific directions:

1. callback-heavy lifecycle APIs on `readChatUiStream(...)`
2. a broad typed final-summary facade

This helper does neither.

It keeps the same result-object direction:

- the main message stream remains the primary projection channel
- side streams remain side streams
- no callback ordering contract is introduced
- no new final-summary object is frozen

So this is still an additive stream-based helper, not a second facade layer.

## Why This Stays Below `ChatSession`

The current repository still does not show evidence that `ChatSession` or
`ChatController` need a new step lifecycle API.

That boundary should remain:

- reader helper
  - direct chunk-stream consumption
  - direct step-boundary observation
- session/controller
  - full app lifecycle and state management

If a future product need appears for session-level step observation, that
should be evaluated separately and explicitly.

## Why This Still Keeps Step Metadata Narrow

The new helper does not widen step metadata.

It only projects the already-existing shared boundary events:

- `StepStartEvent(stepId?)`
- `StepFinishEvent(stepId?)`

Richer per-step payloads still belong elsewhere:

- streamed runner callbacks and step results
- transport-owned diagnostics
- additive metadata or data-part channels

## Bottom Line

This is the right size for the next additive runtime helper:

- no shared event growth
- no session growth
- no callback facade
- slightly better direct reader ergonomics for UI code that wants both step
  boundaries
