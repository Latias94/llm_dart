# llm_dart_ai

Framework-neutral AI runtime helpers for `llm_dart`.

This package owns app-facing orchestration built on top of provider contracts:

- one-shot helpers such as `generateText(...)`, `streamText(...)`, `embed(...)`,
  `generateImage(...)`, `generateSpeech(...)`, `transcribe(...)`,
  `generateObject(...)`, and `streamObject(...)`
- multi-step text runners and tool execution continuation
- callback-style runner telemetry (`onStepStart`, `onStepFinish`, `onFinish`,
  `onChunk`, and `onError`)
- text stream result accumulation
- structured output specs and streaming structured output helpers
  - object-first convenience wrappers for common JSON-schema workflows
- shared chat UI message, mapping, and stream JSON helpers

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

`llm_dart_chat` and `llm_dart_flutter` re-export those types for chat-oriented
imports, but `llm_dart_ai` is the owning package.
