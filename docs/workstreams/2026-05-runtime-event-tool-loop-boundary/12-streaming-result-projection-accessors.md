# Streaming Result Projection Accessors

Date: 2026-05-13
Status: implemented

## What Landed

This slice adds a consistent projection surface across the current streaming
result types:

- `StreamTextRunResult.textStream`
- `StreamTextRunResult.chatUiStream(...)`
- `StreamTextCallResult.textStream`
- `StreamTextCallResult.chatUiStream(...)`
- `StreamOutputResult.chatUiStream(...)`

`StreamOutputResult` already exposed `textStream`; this slice gives it the
same chat UI projection method as the text streaming result facades.

The implementation is additive. Existing stream result types, result futures,
structured output side channels, and `StreamView<TextStreamEvent>` behavior are
unchanged.

## Why This Matters

Before this slice, app code had to know which streaming result facade it was
holding before it could project events into UI chunks. The new accessors make
the result surface more uniform without forcing the larger result foundation
refactor yet.

This follows the `repo-ref/ai` lesson: text streams, structured streams, and UI
streams are projections over the same runtime stream, not separate provider
concerns.

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart test packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart`

## Remaining Work

The result types still duplicate many future getter implementations. A later
M3 slice should extract a shared result foundation or private projection helper
so `StreamTextRunResult`, `StreamTextCallResult`, and `StreamOutputResult`
share more implementation rather than just public surface shape.
