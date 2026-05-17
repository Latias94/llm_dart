# Stream Text Runner Lifecycle Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` stream runner lifecycle
layers, especially:

- `repo-ref/ai/packages/ai/src/generate-text/stream-text.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-language-model-call.ts`
- `repo-ref/ai/packages/ai/src/generate-text/execute-tools-from-stream.ts`
- `repo-ref/ai/packages/ai/src/generate-text/generate-text-events.ts`

The reference keeps stream production, result access, model-call streaming,
tool execution, and lifecycle callbacks as separate concerns. The Dart
implementation keeps the public `StreamTextRunner` seam while moving event
emission and run lifecycle closure behind smaller internal modules.

## Problem

`packages/llm_dart_ai/lib/src/model/stream_text_runner.dart` still owned too
many lifecycle responsibilities:

- public runner construction and convenience `streamTextRun` dispatch
- prompt validation and per-step request construction
- provider stream adaptation and result accumulation
- stream event emission plus `onChunk` dispatch
- active request, active accumulator, active step number, and open-step state
- step finish callback dispatch and step stream replay
- successful run closure
- cancellation/abort closure
- error event projection and result failure closure

That made the runner loop shallow. The `StreamTextRunner` public seam is
valuable because callers get one stable stream runtime, but internal changes to
event emission, cancellation, or finalization all required editing the same
large loop.

## Decision

Keep `stream_text_runner.dart` as the public runner facade and split lifecycle
support:

- `stream_text_event_emitter.dart`
  - stream result event insertion
  - `onChunk` callback dispatch
- `stream_text_run_state.dart`
  - previous step ledger
  - active request, accumulator, step number, and open-step state
  - add-or-replace step behavior shared by normal and abort paths
- `stream_text_run_lifecycle.dart`
  - step finish callback and step stream replay
  - successful run finish event and result completion
  - cancellation/abort finish event and result completion
  - error event projection and result failure
- `stream_text_runner.dart`
  - public runner configuration
  - prompt/request construction
  - provider stream iteration
  - tool execution decision and continuation prompt replay

This keeps the event order and public result shape stable while improving
locality for lifecycle changes.

## Behavior Contract

The refactor preserves these contracts:

- `StreamTextRunner`, `streamTextRun`, and `streamText` keep their public
  surfaces.
- stream event order is unchanged for single-step, tool continuation, abort,
  and error paths.
- `onChunk` still observes every emitted `TextStreamEvent` in emitted order.
- `onStepFinish` still fires before the corresponding `StepFinishEvent`.
- `onFinish` still fires before the final `RunFinishEvent`.
- cancellation after a step has opened still emits `AbortEvent`,
  `StepFinishEvent`, and `RunFinishEvent` with an aborted step.
- cancellation before provider streaming still avoids provider calls and
  produces an aborted active step.
- stream result, step stream, and compatibility accessors keep the same
  behavior.

## Benefits

Locality improves because event emission, run state, and finish/error/abort
closure now live outside the main runner loop.

Leverage improves because future changes to cancellation semantics, stream
event callbacks, or result completion can happen behind small lifecycle modules
without expanding `stream_text_runner.dart`.

This leaves a clearer next step: the non-streaming `GenerateTextRunner` can use
the same architecture idea for step lifecycle state, or the object runner can be
deepened against the reference object generation lifecycle.
