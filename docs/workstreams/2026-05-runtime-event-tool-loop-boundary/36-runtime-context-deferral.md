# Runtime Context Deferral

Date: 2026-05-14
Status: deferred

## Decision

Do not add a public runtime-context or tool-context API in this architecture
slice.

The first stable Dart surface already passes the useful execution context
through explicit values:

- `GenerateTextFunctionToolExecutionRequest.stepNumber`
- `GenerateTextFunctionToolExecutionRequest.step`
- `GenerateTextFunctionToolExecutionRequest.toolCall`
- `GenerateTextStepStartEvent.request`
- `GenerateTextStepStartEvent.previousSteps`
- `CallOptions.cancellation`
- `onStepStart`, `onStepFinish`, `onToolStart`, `onToolFinish`, `onFinish`,
  `onChunk`, and `onError`

That gives applications enough information to route, trace, authorize, and
execute local tools without freezing an untyped `Map<String, Object?>` context
bag.

## Reference Comparison

`repo-ref/ai` carries `runtimeContext` and `toolsContext` through
`generateText(...)`, `streamText(...)`, `prepareStep(...)`, tool approval, and
tool execution. That design is valuable in TypeScript because the tool set,
tool context schemas, runtime context, and callback events are tied together
through generic inference and schema validation.

Dart does not get the same ergonomic win from copying that shape directly. A
shared mutable context bag would create a second request-customization channel
beside typed provider options, `CallOptions`, and application-owned closures.
It would also make `HttpChatTransport` harder to keep serializable because
local context objects are usually process-local.

## Frozen Rule

Keep context explicit until a concrete shared API proves it is needed.

- If a tool needs credentials, clients should close over those credentials in
  `functionToolExecutor` or expose a typed app-owned registry.
- If a step needs routing or provider customization, use typed provider options
  or a future `prepareStep`-style API rather than mutating runtime context from
  inside callbacks.
- If chat needs backend-owned context, send serializable app metadata through
  `HttpChatTransport` and let the backend map it into provider/runtime options.

## Revisit Criteria

Add public context support only if at least two real consumers need the same
cross-cutting value to flow through step preparation, tool approval, tool
execution, and telemetry without being captured by closures.

When that happens, prefer a Dart-native design:

- immutable `runtimeContext` value on the run
- typed or validated per-tool context only when a tool abstraction owns a
  schema/validator
- explicit `prepareStep` result fields for context replacement
- no provider package dependency on `llm_dart_ai`
- no unstructured provider request customization through context

## Validation

This is a boundary decision. Existing runtime tests already prove that tool
execution receives the step, request, and tool call data needed by local
executors, while `CallOptions.cancellation` covers cancellation propagation.
