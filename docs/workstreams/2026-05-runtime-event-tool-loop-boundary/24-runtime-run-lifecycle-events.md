# Runtime Run Lifecycle Events

Date: 2026-05-13

## Scope

`llm_dart_ai` now owns explicit run lifecycle events in the full-stream
vocabulary:

- `RunStartEvent`
- `RunFinishEvent`

`streamText(...)` and `streamTextRun(...)` emit `RunStartEvent` before the
first step and `RunFinishEvent` after the final step. If the runtime loop fails,
it emits `ErrorEvent` and then `RunFinishEvent(finishReason: error)` before the
stream error is delivered.

## Semantics

`StartEvent` and `FinishEvent` remain model-call events adapted from provider
streams. They describe a single provider call.

`RunStartEvent` and `RunFinishEvent` describe the outer AI runtime run, which
may contain multiple model calls, local tool execution, and prompt
continuations.

The successful full-stream shape is:

1. `RunStartEvent`
2. zero or more step groups:
   - `StepStartEvent`
   - provider/model-call events
   - runtime local tool result events when applicable
   - `StepFinishEvent`
3. `RunFinishEvent`

## Payload Policy

Run lifecycle events intentionally do not carry prompt, request, response body,
or per-step payload snapshots. Those objects can be large and may contain
application data. Detailed step data remains available through
`StreamTextRunResult.stepStream` and `StreamTextRunResult.result`.

`RunFinishEvent` carries only aggregate finish data:

- `finishReason`
- optional `rawFinishReason`
- optional aggregate `usage`

## Boundary Rules

Provider packages cannot emit or serialize these events. The provider bridge
rejects them when converting AI runtime events back to provider
`LanguageModelStreamEvent` values.
