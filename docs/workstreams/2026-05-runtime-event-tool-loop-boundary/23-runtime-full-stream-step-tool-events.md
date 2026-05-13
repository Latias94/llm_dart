# Runtime Full Stream Step And Tool Events

Date: 2026-05-13

## Scope

`streamText(...)` and `streamTextRun(...)` now emit runtime-owned full-stream
events around provider model-call events:

- `StepStartEvent` before each provider model call
- provider model-call events adapted into AI-owned `TextStreamEvent` values
- runtime-owned `ToolResultEvent` values for locally executed client tools
- `StepFinishEvent` after model-call output and local tool execution finish
- `ErrorEvent` before the stream error when the runtime loop fails before a
  clean close

This makes the streaming result a true full generation-run stream instead of a
provider model-call passthrough.

## Important Semantics

Provider `FinishEvent(finishReason: toolCalls)` still means the model call
ended with tool calls. `StepFinishEvent` now means the runtime step ended after
the runtime had a chance to execute local client tools and append normalized
tool results.

For tool-call steps with a local function executor, the event order is:

1. `StepStartEvent`
2. provider `ToolCallEvent`
3. provider `FinishEvent(finishReason: toolCalls)`
4. runtime `ToolResultEvent`
5. `StepFinishEvent`

The same normalized tool result is used for:

- the full stream `ToolResultEvent`
- the step result exposed through `stepStream`
- prompt replay for the continuation request

This keeps stream accumulation, step accumulation, and replay semantics aligned.

## API Notes

`GenerateTextRunnerSupport.executeFunctionTools(...)` returns
`GenerateTextToolExecution` values for advanced runtime code that needs both
prompt replay messages and runtime stream events from the same normalized local
tool execution.

`buildFunctionToolContinuation(...)` remains available for the non-streaming
runner and compatibility callers that only need continuation prompt messages.

## Follow-Up

Run-level start/finish events are still not added in this slice. The current
public stream has existing `StartEvent` / `FinishEvent` provider model-call
semantics, so run-level lifecycle names should be introduced deliberately to
avoid overloading those existing model-call events.
