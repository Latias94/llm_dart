# Stream Result Foundation

Date: 2026-05-13
Status: implemented

## What Landed

`llm_dart_ai` now has an internal streaming result foundation:

- `StreamResultHandle<TEvent, TResult>`
- `StreamResultController<TEvent, TResult>`
- `StreamSideChannel<T>`

This foundation owns the shared mechanics that were previously repeated across
streaming runtime result facades:

- replayable event stream exposure
- final result future completion
- error completion and replay-stream error propagation
- side-channel error and close propagation

The public result types keep their existing names and user-facing semantics:

- `StreamTextRunResult`
- `StreamTextCallResult<T>`
- `StreamOutputResult<T>`

`StreamTextCallResult<T>` still supports both raw text calls and structured
output calls. `StreamOutputResult<T>` still preserves `partialOutputStream` and
`elementStream<TElement>()`.

## Boundary Decision

The foundation is intentionally internal to `llm_dart_ai`. It is not exported
from `ai.dart` because it is implementation scaffolding, not a stable user API.

This gives the runtime one place for stream/result lifecycle behavior while
allowing the public facades to stay domain-specific:

- runtime runs expose steps and final run metadata
- text calls expose the final text result plus optional parsed output
- structured output exposes partial output and element side channels

## Why This Matters

Before this slice, `StreamTextRunResult`, `StreamTextCallResult`, and
`StreamOutputResult` each owned similar replay channel, completer, close, and
error handling code. That duplicated plumbing made it too easy for one result
surface to diverge from another during future changes.

The new foundation keeps the public API conservative while reducing the
internal coupling that made the runtime feel monolithic.

## Validation

- `dart test packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart`

## Remaining Work

This does not yet merge `GenerateTextRunner` and `StreamTextRunner` into one
tool-loop engine. It only consolidates result lifecycle plumbing. The next
runtime consolidation step should decide whether the non-streaming and
streaming runners share a lower-level step executor or stay separate with a
shared support layer.
