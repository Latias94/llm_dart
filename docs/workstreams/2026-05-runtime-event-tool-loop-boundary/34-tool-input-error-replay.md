# Tool Input Error Replay

## Decision

`ToolInputErrorEvent` is replayable runtime state. It is no longer only a UI
projection detail.

When a provider emits a tool input error, the AI runtime now records:

- a `ToolCallContentPart` for the attempted call, preserving input,
  `providerExecuted`, `isDynamic`, title, and provider metadata
- a `ToolResultContentPart` with `isError: true`, using the input error text as
  the tool error output

This makes invalid tool input visible to:

- `GenerateTextResultAccumulator`
- `GenerateTextStepResult.toolCalls`
- `GenerateTextStepResult.toolResults`
- `StreamTextRunner` step streams
- continuation prompt replay

## Runtime Loop Semantics

The runtime executor skips tool calls that already have a tool result in the
same step. This prevents a malformed input from being executed locally after it
has already been represented as a tool error result.

If all client tool calls in a `toolCalls` step already have results, the runner
continues by replaying the enriched step back to the model. If unresolved
provider-executed tool calls or approval requests remain, the runner still
stops and leaves continuation to chat/provider-specific handling.

## Why

Without this rule, tool input errors were observable in the raw stream and UI,
but disappeared from step/run results. That made callbacks, `stopWhen`, replay,
and final inspection weaker than the stream itself.

The normalized tool-error representation keeps one tool-output model for:

- local tool execution failures
- denied tool outputs
- provider-emitted input errors

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart test packages/llm_dart_ai/test/generate_text_result_accumulator_test.dart --plain-name "tool input errors"`
- `dart test packages/llm_dart_ai/test/stream_text_runner_test.dart --plain-name "tool input error"`
- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart --plain-name "already contain tool error results"`
- `dart test packages/llm_dart_ai/test/generate_text_result_accumulator_test.dart packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart`
