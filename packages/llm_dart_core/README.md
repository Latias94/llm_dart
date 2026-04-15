# llm_dart_core

Shared model contracts, output/running primitives, stream events, UI message
models, and serialization codecs for `llm_dart`.

This package is the shared foundation layer for the modern workspace.

## What This Package Owns

`llm_dart_core` owns five related shared areas:

- common contracts such as warnings, errors, usage, provider metadata/options,
  request cancellation, and JSON schema
- prompt, content, and tool definitions
- model specifications and shared capability helpers such as `LanguageModel`,
  `EmbeddingModel`, `generateText(...)`, `embed(...)`, and `generateImage(...)`
- shared multi-step runners such as `GenerateTextRunner` and
  `StreamTextRunner`
- shared stream/UI projection and serialization types such as
  `TextStreamEvent`, `ChatUiMessage`, `ChatUiStreamChunk`, `ChatMessageMapper`,
  and the JSON codecs for prompt/UI/event transport

## What This Package Does Not Own

This package does not own:

- HTTP and Dio transport mechanics
- chat/session persistence and controller orchestration
- Flutter widget/controller adapters
- provider-specific request codecs, custom parts, or provider-native feature
  policy

Use the higher packages for those responsibilities:

- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_flutter`
- provider packages such as `llm_dart_openai`, `llm_dart_google`, and
  `llm_dart_anthropic`

## Internal Ownership Map

The package is intentionally broader than a pure specification package, but it
should be read as these internal groups:

- **Foundation contracts** - warnings, errors, usage, metadata, options,
  cancellation, JSON schema
- **Model and capability layer** - model interfaces plus one-shot shared
  helpers such as `generateText(...)`, `embed(...)`, `generateSpeech(...)`,
  and `transcribe(...)`
- **Runner layer** - multi-step orchestration through `GenerateTextRunner` and
  `StreamTextRunner`
- **Stream/UI layer** - `TextStreamEvent`, `ChatUiMessage`,
  `ChatUiStreamChunk`, and `ChatMessageMapper`
- **Serialization layer** - prompt/UI/event codecs and protocol markers

## When To Use This Package Directly

Use `llm_dart_core` directly when you are building:

- provider implementations
- framework-neutral generation utilities
- shared output/structured-output helpers
- server or CLI code that wants prompt/result/stream contracts without a chat
  runtime
- transport or protocol helpers that need the shared JSON/event codecs

If you need chat/session orchestration, prefer `llm_dart_chat`.

If you need Flutter state/controller adapters, prefer `llm_dart_flutter`.

## Design Rule

`llm_dart_core` is still intentionally one package for now.

It should not be split further unless real package pressure appears, such as:

- external provider ecosystems needing a narrower public spec package
- repeated coupling between UI/serialization and runner/capability changes
- a proven need for shared provider-implementation utilities outside the whole
  core barrel
