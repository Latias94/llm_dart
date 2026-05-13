# Runtime Abort Lifecycle Events

Date: 2026-05-13

## Scope

`streamText(...)` and `streamTextRun(...)` now translate
`CallOptions.cancellation` into runtime full-stream abort semantics:

1. `AbortEvent(reason: ...)`
2. `StepFinishEvent` for the active step when one has started
3. `RunFinishEvent(finishReason: FinishReason.aborted, rawFinishReason: ...)`

The provider model-call contract still receives the same `CallOptions`
object. This slice does not require every provider to implement HTTP-level
cancellation immediately; the AI runtime now owns the observable app-facing
abort lifecycle even while provider implementations catch up.

## Semantics

Cancellation is not a model/provider error. When runtime cancellation is
observed:

- no `ErrorEvent` is emitted
- `onError` is not invoked
- `StreamTextRunResult.result` completes with a partial
  `GenerateTextRunResult`
- the active `GenerateTextStepResult` has `finishReason.aborted`
- `onStepFinish` and `onFinish` are still called with aborted results

This keeps user-initiated stop distinct from provider failures, while still
preserving the partial content that was already streamed.

## Result Accumulation

`GenerateTextResultAccumulator` can now use `RunFinishEvent` as a terminal
finish signal when a provider `FinishEvent` is absent because the run was
aborted. Provider model-call `FinishEvent` remains the normal step-scoped
finish source.

The run finish signal carries only aggregate finish data and does not include
request, prompt, or response payload snapshots.

## UI Projection

`RunFinishEvent(finishReason: aborted)` marks chat UI metadata as aborted and
copies `rawFinishReason` into `abortReason` when present. This lets direct
runtime streams and chat transport projections expose the same aborted-message
state.

## Remaining Follow-Ups

Provider packages should progressively wire `CallOptions.cancellation` into
their HTTP/SSE clients so cancellation stops network work earlier. That is a
provider implementation follow-up, not a runtime event vocabulary blocker.
