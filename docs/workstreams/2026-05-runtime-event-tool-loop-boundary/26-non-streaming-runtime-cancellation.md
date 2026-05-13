# Non-Streaming Runtime Cancellation

Date: 2026-05-13

## Scope

`GenerateTextRunner` and `runTextGeneration(...)` now treat
`CallOptions.cancellation` as runtime cancellation instead of a provider/model
error.

When cancellation is observed, the runner returns a `GenerateTextRunResult`
whose active or final step has:

- `finishReason: FinishReason.aborted`
- `rawFinishReason` copied from the cancellation reason when present
- any already available content, usage, response metadata, and provider
  metadata preserved

## Semantics

Non-streaming cancellation now matches streaming cancellation:

- `onError` is not invoked for `ProviderCancelledException`
- `onStepFinish` is invoked with the aborted step
- `onFinish` is invoked with the aborted run result
- `generateText(...)` returns the aborted step result instead of throwing

Provider failures, validation errors, max-step errors, and callback failures
still use the normal error path.

## Current Limitation

`GenerateTextRunResult` currently derives run finish state from the last step.
That is sufficient for this migration slice, but the later result foundation
should split run finish state from step finish state explicitly. That will make
cases such as "a completed model step followed by run-level cancellation"
representable without mutating the final step reason.

## Provider Follow-Up

This slice does not add provider HTTP cancellation support. Providers should
still progressively wire `CallOptions.cancellation` into request clients so
non-streaming and streaming operations stop network work earlier.
