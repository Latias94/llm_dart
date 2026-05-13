# Primary Runtime Entrypoints

Date: 2026-05-13
Status: implemented

## What Landed

`generateText(...)` and `streamText(...)` now route through the AI runtime
runner path instead of calling `LanguageModel.doGenerate(...)` and
`LanguageModel.doStream(...)` directly.

The public return types stay unchanged:

- `generateText(...)` still returns `Future<GenerateTextResult>`
- `streamText(...)` still returns `Stream<TextStreamEvent>`

The difference is behavioral ownership. Both helpers can now use the runtime
tool loop settings:

- `functionToolExecutor`
- `maxSteps`
- step start / step finish callbacks
- finish callback
- error callback
- streaming chunk callback on `streamText(...)`

`generateText(...)` returns the last step's provider `GenerateTextResult`,
which keeps existing callers working while making the helper a true
multi-step runtime entrypoint. `streamText(...)` returns the event stream from
`StreamTextRunner`, preserving stream ergonomics while enabling multi-step
continuation.

## Why This Matters

The previous architecture still had two competing meanings:

- `runTextGeneration(...)` and `streamTextRun(...)` were the multi-step
  runtime helpers
- `generateText(...)` and `streamText(...)` looked like the primary API but
  were only single provider-call wrappers

This slice resolves that mismatch. App-facing helpers now mean AI runtime
execution, while provider single-call behavior remains available explicitly
through `LanguageModel.doGenerate(...)` and `LanguageModel.doStream(...)`.

## Compatibility Notes

The initial prompt validation behavior remains synchronous for `streamText(...)`
by validating the resolved prompt in `StreamTextRunner` construction before
returning the stream.

Structured helpers such as `generateTextCall(...)`, `streamTextCall(...)`,
`generateOutput(...)`, and `streamOutput(...)` keep their existing return
shapes and now inherit the same primary runtime path where they call
`generateText(...)` or `streamText(...)`.

## Validation

- `dart analyze`
- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart`
- `dart test packages/llm_dart_ai/test/prompt_normalization_test.dart packages/llm_dart_ai/test/prompt_validation_test.dart`
- `dart test packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart`
- `dart test packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`

## Remaining Work

`runTextGeneration(...)` and `streamTextRun(...)` are still useful explicit
result-surface helpers, but their naming now overlaps with the primary
helpers. A later slice should decide whether to keep them as advanced result
facades, rename them, or make them private implementation details after
callers have a stable migration path.
