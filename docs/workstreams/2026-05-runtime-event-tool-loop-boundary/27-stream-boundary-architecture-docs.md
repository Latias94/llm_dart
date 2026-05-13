# Stream Boundary Architecture Docs

Date: 2026-05-13

## Scope

This slice documents the three stream layers that now have separate ownership:

1. provider model-call streams
2. AI runtime full streams
3. chat/UI streams

The documentation is intentionally part of the architecture line because old
docs and examples historically used `TextStreamEvent` as if it were both the
provider boundary and the app runtime boundary.

## Layer 1: Provider Model-Call Stream

Owner: `llm_dart_provider` and concrete provider packages.

Primary type:

- `LanguageModelStreamEvent`

Semantics:

- one provider model invocation
- provider response metadata
- text, reasoning, files, sources, tool calls, tool input chunks, finish,
  errors, raw chunks, and provider-owned custom events
- no runtime run lifecycle
- no step lifecycle
- no chat/session/UI-only chunks

Provider packages must not depend on `llm_dart_ai`, `llm_dart_chat`, Flutter,
or the root package.

## Layer 2: AI Runtime Full Stream

Owner: `llm_dart_ai`.

Primary type:

- `TextStreamEvent`

Semantics:

- outer run lifecycle: `RunStartEvent`, `RunFinishEvent`
- step lifecycle: `StepStartEvent`, `StepFinishEvent`
- adapted provider model-call events
- runtime local tool execution results
- app-side tool denial and abort semantics
- runtime errors

`streamText(...)` and `streamTextRun(...)` own this full stream. Provider
model-call `StartEvent` and `FinishEvent` remain scoped to a provider
invocation; they are not run lifecycle events.

## Layer 3: Chat/UI Stream

Owners:

- `llm_dart_ai` for shared UI message/chunk models and projection
- `llm_dart_chat` for chat session, transport, persistence, and manual tool
  submission

Primary types:

- `ChatUiStreamChunk`
- `ChatUiMessage`

Semantics:

- persistent assistant message snapshots
- step observations for UI/session state
- transient and persistent data parts
- transport/session metadata patches
- chat status derivation

This layer sits above `TextStreamEvent`. It may carry UI-only data that should
not be pushed down into provider or runtime event vocabularies.

## App-Facing Entry Points

Recommended app-facing helpers:

- `generateText(...)`
- `streamText(...)`
- `generateTextCall(...)`
- `streamTextCall(...)`
- `generateObject(...)`
- `streamObject(...)`
- `DefaultChatSession` with `DirectChatTransport` or `HttpChatTransport`

Advanced/migration helpers:

- `runTextGeneration(...)`
- `streamTextRun(...)`
- `GenerateTextRunner`
- `StreamTextRunner`

Those advanced helpers remain useful for inspecting step streams and callback
telemetry, but the long-term public surface should keep moving toward fewer
primary entry points and one consistent result foundation.

## Migration Notes

If provider code still returns `TextStreamEvent`, migrate it to
`LanguageModelStreamEvent`.

If app code consumed provider streams directly to get chat state, route through
`streamText(...)` and project with `chatUiStream(...)`, or use
`DefaultChatSession` with `DirectChatTransport`.

If app code relied on `StartEvent` / `FinishEvent` as whole-run boundaries,
switch to `RunStartEvent` / `RunFinishEvent` for runtime runs. Keep
`StartEvent` / `FinishEvent` for provider model-call observations.

If cancellation was treated as a model error, migrate to
`FinishReason.aborted`, `AbortEvent`, `RunFinishEvent(finishReason: aborted)`,
or chat UI metadata `isAborted` / `abortReason` depending on the layer.
