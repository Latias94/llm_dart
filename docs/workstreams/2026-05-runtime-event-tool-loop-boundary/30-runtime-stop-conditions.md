# Runtime Stop Conditions

Date: 2026-05-13
Status: implemented

## What Landed

The AI runtime now supports composable stop conditions for tool loops:

- `GenerateTextStopCondition`
- `GenerateTextStopConditionContext`
- `isStepCount(int stepCount)`
- `isLoopFinished()`
- `hasToolCall(String toolName, [Iterable<String> additionalToolNames])`
- `isStopConditionMet(...)`

The public text runtime helpers and result facades accept `stopWhen`:

- `generateText(...)`
- `streamText(...)`
- `runTextGeneration(...)`
- `streamTextRun(...)`
- `GenerateTextRunner`
- `StreamTextRunner`
- `generateTextCall(...)`
- `streamTextCall(...)`
- `generateOutput(...)`
- `streamOutput(...)`
- `generateObject(...)`
- `streamObject(...)`

`llm_dart_core` re-exports the stop-condition API for compatibility imports.

## Semantics

`maxSteps` remains the hard safety guard. `stopWhen` is the normal business
policy for deciding whether a tool loop should continue after a completed
tool-call step.

The runtime evaluates stop conditions only after a completed step can otherwise
continue through local tool execution. It does not interrupt ordinary model
responses that finish with `stop`, `length`, `contentFilter`, `error`, or
`aborted`.

For streaming runs, local tool results are first folded into the current
`GenerateTextStepResult`; then `stopWhen` is evaluated. This means
`hasToolCall(...)` and custom conditions can inspect the latest step with local
tool results included.

## Why This Matters

Before this slice, `maxSteps` was doing two jobs:

- hard runaway-loop protection
- application-level stop policy

That made the runtime less expressive than the reference SDK and forced callers
to encode normal loop policy as a safety limit. `stopWhen` separates those
concerns while preserving `maxSteps` as a defensive bound.

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart analyze packages/llm_dart_core`
- `dart test packages/llm_dart_ai/test/generate_text_stop_condition_test.dart packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart`

## Remaining Work

The non-streaming runner still needs a deeper tool-loop result slice so local
tool execution results are represented in the same step result as the
streaming path. Stop conditions are in place, but richer runtime contexts,
approval continuation, and dynamic tool semantics remain separate Tool Loop
items.
