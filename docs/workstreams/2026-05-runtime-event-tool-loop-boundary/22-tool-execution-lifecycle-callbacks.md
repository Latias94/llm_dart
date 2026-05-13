# Tool Execution Lifecycle Callbacks

Date: 2026-05-13
Status: implemented

## What Landed

The AI runtime now exposes lifecycle callbacks around local function tool
execution:

- `GenerateTextOnToolStart`
- `GenerateTextOnToolFinish`
- `GenerateTextToolExecutionStartEvent`
- `GenerateTextToolExecutionFinishEvent`

The callbacks are available on:

- `generateText(...)`
- `streamText(...)`
- `runTextGeneration(...)`
- `streamTextRun(...)`
- `GenerateTextRunner`
- `StreamTextRunner`

Both non-streaming and streaming paths use the same implementation in
`GenerateTextRunnerSupport.buildFunctionToolContinuation(...)`, so callback
ordering and error wrapping stay consistent.

## Callback Semantics

`onToolStart` runs after the runtime has validated that the tool call is a
client-executed declared function tool and before the user-provided
`functionToolExecutor` is called.

`onToolFinish` runs after execution completes or after executor failure is
wrapped as a `GenerateTextToolExecutionResult.error(...)`. This means callers
can observe failed local tool execution without relying only on final prompt
continuation state.

Provider-executed tools are not reported through these callbacks because they
are not local function tool executions.

## Why This Matters

This is the first tool-loop lifecycle surface beyond step callbacks. It gives
apps a stable place to trace, log, meter, or display local tool execution while
keeping provider packages unaware of runtime tool orchestration.

## Validation

- `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart`

## Remaining Work

The runtime still needs a richer full-stream event vocabulary for tool
execution parts and a decision on whether chat automatic tool execution should
delegate directly to these runtime lifecycle hooks.
