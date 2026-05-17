# Stream Text Result Cancellation Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` stream text layers,
especially:

- `repo-ref/ai/packages/ai/src/generate-text/stream-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text.ts`
- `repo-ref/ai/packages/ai/src/generate-text/language-model-events.ts`
- `repo-ref/ai/packages/ai/src/generate-text/generate-text-events.ts`

The reference keeps stream result accessors and stream run orchestration as
separate concerns. The Dart implementation keeps the existing
`StreamTextRunResult`, `StreamTextRunner`, and `streamTextRun` public seam while
moving result facade and cancellation support out of the run loop module.

## Problem

`packages/llm_dart_ai/lib/src/model/stream_text_runner.dart` mixed three
responsibilities:

- stream text result facade accessors and chat UI projection
- stream cancellation wrapping and provider cancellation reason extraction
- the multi-step stream run loop, tool continuation, lifecycle events, and
  aborted-run finalization

This made the module shallow in the architecture sense: the public interface
was small, but a maintainer had to read result projection and cancellation
plumbing before reaching the run loop. The deletion test showed that
`StreamTextRunResult` is a real seam because its accessors are the user-facing
leverage over a replayable stream and final run result. The problem was its
implementation locality, not the existence of the seam.

## Decision

Keep `stream_text_runner.dart` as the public facade for stream text running and
split the implementation:

- `stream_text_run_result.dart`
  - `StreamTextRunResult`
  - result future accessors
  - text stream and chat UI projection accessors
  - internal `createStreamTextRunResult(...)` construction helper
- `stream_text_cancellation.dart`
  - provider cancellation stream wrapper
  - cancellation detection
  - cancellation reason extraction
- `stream_text_runner.dart`
  - `StreamTextRunner`
  - `streamTextRun(...)`
  - run loop, step lifecycle, tool continuation, abort finalization, and event
    dispatch

`stream_text_runner.dart` re-exports only `StreamTextRunResult` from the result
module. The construction helper and cancellation helpers remain internal
implementation details.

## Behavior Contract

The refactor preserves these contracts:

- `StreamTextRunResult`, `StreamTextRunner`, and `streamTextRun` remain
  available from `package:llm_dart_ai/llm_dart_ai.dart`.
- `llm_dart_core` compatibility exports continue to resolve the same names.
- stream event ordering for run start, step start, provider events, tool result
  events, step finish, abort, error, and run finish is unchanged.
- `StreamTextRunResult` still exposes replayable event stream access,
  `stepStream`, final `result`, result accessors, `textStream`, and
  `chatUiStream(...)`.
- provider cancellation still produces an aborted run result instead of an
  error lifecycle.

## Benefits

Locality improves because result facade changes now live in
`stream_text_run_result.dart`, cancellation mechanics live in
`stream_text_cancellation.dart`, and stream run-loop work remains in
`stream_text_runner.dart`.

Leverage improves because callers still use the same public seam while future
stream run loop changes can be made without touching result projection or
cancellation plumbing.

This also sets up the next deepening opportunity: extracting step lifecycle
state from the stream run loop itself, after the result and cancellation
concerns are no longer mixed into that file.
