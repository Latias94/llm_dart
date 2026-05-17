# Generate Text Runner Support Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` tool execution and
prompt replay layers, especially:

- `repo-ref/ai/packages/ai/src/generate-text/execute-tool-call.ts`
- `repo-ref/ai/packages/ai/src/generate-text/execute-tools-from-stream.ts`
- `repo-ref/ai/packages/ai/src/generate-text/tool-execution-events.ts`
- `repo-ref/ai/packages/ai/src/generate-text/to-response-messages.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text.ts`
- `repo-ref/ai/packages/ai/src/generate-text/generate-text.ts`

The reference keeps tool execution, stream event projection, and prompt replay
as distinct implementation concerns. The Dart implementation keeps the existing
`GenerateTextRunnerSupport` public seam while moving those implementation
concerns behind smaller internal modules.

## Problem

`packages/llm_dart_ai/lib/src/model/generate_text_runner_support.dart` had
grown into a mixed module:

- public callback typedefs and tool execution event/value types
- function tool execution selection and lifecycle callback dispatch
- tool execution result projection into step content and stream events
- provider replay metadata lookup
- step-to-prompt replay for continuation turns

That made the module shallow. `GenerateTextRunnerSupport` is a real seam
because both `GenerateTextRunner` and `StreamTextRunner` depend on the same
tool-loop semantics, but the implementation bundled several independent
reasons to change.

## Decision

Keep `generate_text_runner_support.dart` as the public facade and split the
implementation:

- `generate_text_runner_tool_execution.dart`
  - function tool executor typedefs
  - tool execution request/start/finish/result/execution types
  - local tool execution selection
  - tool execution lifecycle callback dispatch
  - tool result projection into step content and stream events
- `generate_text_runner_prompt_replay.dart`
  - provider replay metadata lookup
  - provider replay prompt options
  - step-to-prompt message replay for continuation turns
- `generate_text_runner_support.dart`
  - callback typedefs shared by runners
  - `GenerateTextRunnerSupport` facade methods that preserve existing call
    sites
  - re-export of the existing public tool execution types

This keeps the user-facing `llm_dart_ai` export surface unchanged while giving
tool execution and prompt replay separate locality.

## Behavior Contract

The refactor preserves these contracts:

- `GenerateTextRunnerSupport` remains publicly exported from `llm_dart_ai`.
- public tool execution typedefs and event/result types remain publicly
  exported from the same package entrypoint.
- `GenerateTextRunner` and `StreamTextRunner` keep identical local tool
  execution behavior.
- provider-executed tool calls are not executed locally.
- existing tool result content prevents duplicate local execution.
- approval requests stop continuation before client tool execution.
- provider metadata is still replayed into tool-call and tool-result prompt
  parts.
- dynamic tool flags are preserved in step content, stream events, and prompt
  replay.

## Benefits

Locality improves because local tool execution policy now lives in
`generate_text_runner_tool_execution.dart`, while prompt replay lives in
`generate_text_runner_prompt_replay.dart`.

Leverage improves because both non-streaming and streaming runners keep using
one public support seam, but future changes to tool execution or prompt replay
can be made without editing a mixed support file.

This leaves a clearer next step: the result accumulator can be deepened by event
family once tool execution and replay are no longer mixed into the same support
module.
