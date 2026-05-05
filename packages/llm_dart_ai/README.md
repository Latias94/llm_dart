# llm_dart_ai

Framework-neutral AI runtime helpers for `llm_dart`.

This package owns app-facing orchestration built on top of provider contracts:

- one-shot helpers such as `generateText(...)`, `streamText(...)`, `embed(...)`,
  `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`
- multi-step text runners and tool execution continuation
- text stream result accumulation
- structured output specs and streaming structured output helpers

It intentionally depends on `llm_dart_provider` only. Provider packages should
implement the provider contracts without depending on this runtime package.

Use `llm_dart_ai` when you want framework-neutral generation utilities. Use
`llm_dart_chat` for chat session state and transport orchestration.
