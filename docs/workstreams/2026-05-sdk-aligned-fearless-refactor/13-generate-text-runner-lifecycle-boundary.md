# Generate Text Runner Lifecycle Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` generate text lifecycle
layers, especially:

- `repo-ref/ai/packages/ai/src/generate-text/generate-text.ts`
- `repo-ref/ai/packages/ai/src/generate-text/generate-text-events.ts`
- `repo-ref/ai/packages/ai/src/generate-text/prepare-step.ts`
- `repo-ref/ai/packages/ai/src/generate-text/execute-tool-call.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stop-condition.ts`

The reference keeps step preparation, tool execution, stop policy, callbacks,
and result construction as distinct concerns. The Dart implementation keeps the
public `GenerateTextRunner` seam while moving active run state and lifecycle
closure out of the main loop.

## Problem

`packages/llm_dart_ai/lib/src/model/generate_text_runner.dart` still owned too
many responsibilities:

- public runner construction and `runTextGeneration` dispatch
- prompt validation and per-step request construction
- active request, active result, and active step number state
- step finish callback dispatch and step ledger mutation
- successful run result construction and `onFinish` dispatch
- cancellation/abort result construction
- `onError` callback wrapping and replacement-error behavior
- tool execution decision and continuation prompt replay

That made the runner loop harder to reason about than necessary. The
`GenerateTextRunner` public seam is valuable, but the implementation bundled
state bookkeeping and lifecycle closure with the actual generation/tool-loop
policy.

## Decision

Keep `generate_text_runner.dart` as the public runner facade and split lifecycle
support:

- `generate_text_run_state.dart`
  - previous step ledger
  - active request, active result, and active step number
  - add-or-replace step behavior shared by normal and abort paths
- `generate_text_run_lifecycle.dart`
  - step finish callback and ledger mutation
  - successful run result construction and `onFinish`
  - cancellation/abort result construction and `onFinish`
  - `onError` callback wrapping and replacement-error behavior
- `generate_text_runner.dart`
  - public runner configuration
  - prompt/request construction
  - provider generation call
  - tool execution decision and continuation prompt replay
  - stop policy

This mirrors the stream runner lifecycle split without forcing a shared base
class across streaming and non-streaming runners.

## Behavior Contract

The refactor preserves these contracts:

- `GenerateTextRunner`, `runTextGeneration`, and `generateText` keep their
  public surfaces.
- `onStepStart`, `onStepFinish`, `onFinish`, `onToolStart`, `onToolFinish`, and
  `onError` keep their ordering and replacement-error behavior.
- cancellation after a provider result still returns an aborted result that
  preserves partial content, response metadata, usage, provider metadata, and
  warnings.
- cancellation before provider generation still avoids the provider call and
  returns an empty aborted active step.
- provider-thrown cancellation still returns an empty aborted active step.
- tool continuation, provider-executed tool skipping, tool input error replay,
  approval waiting, max-step failure, and stop policy behavior are unchanged.
- `llm_dart_core` compatibility exports continue to resolve the same runner
  names.

## Benefits

Locality improves because active run state and finish/error/abort closure now
live outside the main runner loop.

Leverage improves because both streaming and non-streaming runners now share
the same architectural shape: public runner facade, run state module, lifecycle
module, and shared runner support for tool execution and prompt replay.

This leaves object generation as the highest-value remaining runtime seam if
the workstream continues.
