# Dynamic Tool Step Result Alignment

## Decision

Declared dynamic function tools are executable by the AI runtime. `isDynamic`
is a tool-call/result classification, not an automatic runtime error.

The runtime still does not execute:

- provider-executed tools
- dynamic tools that are not declared in `tools`
- tool calls waiting for provider approval responses

Those cases stop the runtime loop and leave the call/result state for chat,
provider replay, or a future explicit approval protocol.

## Runtime Alignment

`GenerateTextRunner` now mirrors `StreamTextRunner` for locally executed tools:

- local function tool results are folded into the current
  `GenerateTextStepResult`
- `onStepFinish` observes the same step shape returned in the final
  `GenerateTextRunResult`
- `stopWhen` evaluates after the locally executed tool results are visible
- continuation prompt replay is derived from the enriched step through
  `GenerateTextRunnerSupport.stepToPromptMessages(...)`

Before this slice, the streaming path folded local `ToolResultEvent` values into
the step result, while the non-streaming path only appended tool results to the
next request prompt. That made callbacks, stop conditions, and final run results
observe different step shapes.

## Reference

The Vercel AI SDK treats dynamic tools as executable when a matching tool
definition exists, preserves a dynamic flag on results, ignores
provider-executed tools for local execution, and lets provider-executed dynamic
tools pass through as provider-owned state.

This Dart slice follows the same boundary without copying TypeScript generics
or tool-set typing mechanics.

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart analyze packages/llm_dart_core`
- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/generate_text_stop_condition_test.dart packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart`
- `dart test packages/llm_dart_core/test/generate_text_runner_test.dart packages/llm_dart_core/test/stream_text_runner_test.dart`
