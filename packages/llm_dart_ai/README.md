# llm_dart_ai

Framework-neutral AI runtime helpers for `llm_dart`.

This package owns app-facing orchestration built on top of provider contracts:

- runtime helpers such as `generateText(...)`, `streamText(...)`,
  `generateTextCall(...)`, `streamTextCall(...)`, `embed(...)`,
  `generateImage(...)`, `generateSpeech(...)`, `transcribe(...)`,
  `generateObject(...)`, and `streamObject(...)`
- multi-step text runners and tool execution continuation
- callback-style runner telemetry (`onStepStart`, `onStepFinish`, `onFinish`,
  `onChunk`, and `onError`)
- text stream result accumulation
- runtime full-stream JSON serialization
- runtime stream projection from text results to chat UI chunks
- structured output specs and streaming structured output helpers
  - object-first convenience wrappers for common JSON-schema workflows
- shared chat UI message, mapping, and stream JSON helpers

## Stream Boundaries

`llm_dart_ai` owns the app-facing full stream, `TextStreamEvent`.
Provider packages own the lower-level model-call stream,
`LanguageModelStreamEvent`.

The distinction matters:

- provider model-call events describe one provider invocation
- runtime full-stream events add `RunStartEvent`, `RunFinishEvent`,
  `StepStartEvent`, `StepFinishEvent`, local tool execution results, aborts,
  and runtime errors around provider events
- chat UI streams are a higher layer built from `TextStreamEvent` and expose
  `ChatUiStreamChunk` / `ChatUiMessage`

Use `streamText(...)` when you want the runtime full stream. Use
`LanguageModel.doStream(...)` only when implementing or testing provider-level
model-call behavior.

## Prompt And Result Surfaces

Use `messages:` with `ModelMessage` for app-facing prompt construction.
Use `prompt:` with `PromptMessage` only when working at the provider-contract
layer or replaying already-normalized provider prompts.

Use `generateText(...)` and `streamText(...)` for the primary text runtime.
For structured output, `generateTextCall(...)` and `streamTextCall(...)` are
the combined text and parsed-output result facades. `generateObject(...)` and
`streamObject(...)` remain convenience wrappers for common JSON-schema
workflows.

Use `runTextGeneration(...)`, `streamTextRun(...)`, `GenerateTextRunner`, and
`StreamTextRunner` when you need step streams or callback telemetry directly.
They are advanced runtime result facades, not the primary teaching path for
normal text generation.

Use `stopWhen` with `isStepCount(...)`, `isLoopFinished()`,
`hasToolCall(...)`, or a custom `GenerateTextStopCondition` when a tool loop
needs application-level stop policy. Keep `maxSteps` as the hard safety guard.

Provider-specific input behavior should stay in typed provider options or
provider-owned prompt part options. Provider metadata is response-side
observation and replay data, not ordinary request customization.

It intentionally depends on `llm_dart_provider` only. Provider packages should
implement the provider contracts without depending on this runtime package.

Use `llm_dart_ai` when you want framework-neutral generation utilities. Use
`llm_dart_chat` for chat session state and transport orchestration.

The shared chat UI layer also lives here:

- `ChatUiMessage`
- `ChatUiPart`
- `ChatMessageMapper`
- `ChatUiStreamReader`
- `ChatUiJsonCodec`
- `TextStreamEvent`
- `TextStreamEventJsonCodec`

`llm_dart_chat` and `llm_dart_flutter` re-export those types for chat-oriented
imports, but `llm_dart_ai` is the owning package.
