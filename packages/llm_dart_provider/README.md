# llm_dart_provider

Shared provider contracts and provider-neutral data structures for `llm_dart`.

Most applications should use the root `llm_dart` package instead. Depend on
`llm_dart_provider` directly when you are writing a provider package, a custom
model implementation, or an integration that needs the shared prompt/result
types without also depending on runtime helpers, HTTP clients, chat sessions, or
Flutter adapters.

## What It Provides

- prompt messages and content parts
- tool definitions and tool outputs
- language, embedding, image, speech, and transcription model interfaces
- model results, warnings, errors, usage, metadata, and finish reasons
- model capability profiles for UI gating and provider discovery
- shared chat UI message/projection types
- JSON codecs for prompts, text stream events, and chat UI transport

## When To Use It

Use this package directly when you need to:

- implement a custom `LanguageModel` or other shared model interface
- build a provider package that should stay independent from the root facade
- serialize shared prompt, stream, or chat UI payloads
- inspect capability profiles without taking a dependency on app runtimes

## When Not To Use It

This package does not include:

- generation helper functions such as `generateTextCall(...)`
- Dio/HTTP transport clients
- provider-specific request codecs or options
- chat session orchestration
- Flutter controller adapters

For those layers, use `llm_dart_ai`, `llm_dart_transport`, provider packages,
`llm_dart_chat`, or `llm_dart_flutter`.
