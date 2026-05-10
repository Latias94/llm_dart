# Stream Event And Custom Part Audit

## Decision

The current stream and custom-part design is sufficient for the `0.11.0-alpha`
release candidate. No new shared stream event family is required before the
preview release.

The design should stay split into three layers:

- model stream events in `llm_dart_provider`
- app and chat UI projection in `llm_dart_ai` and `llm_dart_chat`
- provider-owned custom part parsers in provider packages

This keeps the modern API aligned with the useful AI SDK pattern of structured
stream parts without copying its JavaScript-specific UI store and transport
callback shape.

## Shared Model Stream

`LanguageModel.stream(...)` returns `Stream<TextStreamEvent>`. The shared model
stream already carries the provider-agnostic events that application code needs
to build a stable assistant response:

- text start, delta, and end
- reasoning start, delta, and end
- tool call and tool result events
- source and generated file events
- custom provider events
- warnings, errors, aborts, and finish metadata

The shared contract should not grow provider-specific event classes for every
native API item. Provider-native data should use `CustomEvent` with a stable
`kind`, provider-owned `data`, and `ProviderMetadata`.

## App And UI Stream

The app-facing UI layer uses `ChatUiStreamChunk` rather than widening the raw
model stream:

- `ChatUiMessageStartChunk` and `ChatUiMessageFinishChunk` delimit UI messages
- `ChatUiMessageMetadataChunk` carries message-level metadata
- `ChatUiEventChunk` bridges model events
- `ChatUiDataPartChunk` persists app data parts
- `ChatUiTransientDataPartChunk` carries non-persisted app data

The accumulated UI state uses `ChatUiPart` variants for text, reasoning, tools,
sources, files, custom parts, step boundaries, and typed data parts.

This is the correct boundary for resumable and replayable UI streams. Transport
and chat-session code can serialize UI chunks without forcing provider codecs to
know about UI state.

## Provider-Native Custom Parts

Provider-native data remains typed at provider boundaries:

- shared core parts keep `CustomPromptPart`, `CustomContentPart`,
  `CustomEvent`, and `CustomUiPart`
- OpenAI parses provider-native custom data through `OpenAICustomPart`
- Google parses provider-native replay data through `GoogleCustomPart`
- provider summaries are provider-owned helpers rather than shared core types

This gives UI code a stable shared escape hatch while preserving discoverable
typed helpers for advanced provider features such as OpenAI image generation
events, OpenAI MCP tool-list events, and Google function/tool replay payloads.

## Structured Object Streaming Boundary

Structured object generation is now handled by `generateObject(...)` and
`streamObject(...)` over the shared structured-output runtime.

Object streaming should remain a task-runner concern instead of being encoded
as fake text events or UI-only data chunks. Apps that want persisted UI data can
project parsed object state into `DataUiPart` explicitly.

## What We Are Not Copying

The reference SDK's broader UI stream vocabulary remains a useful comparison,
but these pieces are intentionally not promoted into the shared provider
contract for `0.11.0-alpha`:

- React-style local message-store mutation callbacks
- provider-specific native event classes in the shared model contract
- automatic conversion of every transient `data-*` item into persisted UI state
- a single untyped request-options bag for provider-specific settings

Those would make the Dart packages harder to consume independently and would
weaken the typed provider-options design.

## Evidence

The release readiness gate passed with:

```bash
dart run tool/release_readiness.dart --proxy=http://127.0.0.1:10809
```

Relevant coverage is present in:

- `packages/llm_dart_ai/test/stream_text_runner_test.dart`
- `packages/llm_dart_ai/test/output_spec_test.dart`
- `packages/llm_dart_core/test/chat_ui_stream_accumulator_test.dart`
- `packages/llm_dart_core/test/chat_ui_stream_projection_test.dart`
- `packages/llm_dart_chat/test/chat_ui_stream_reader_test.dart`
- `packages/llm_dart_chat/test/http_chat_transport_protocol_test.dart`
- `packages/llm_dart_chat/test/http_chat_transport_test.dart`
- `packages/llm_dart_openai/test/openai_custom_part_test.dart`
- `packages/llm_dart_google/test/google_custom_part_test.dart`

## Release Conclusion

For the preview release, stream and provider-native custom-part support is
closed as a design gap. Future work should add provider-owned custom parsers or
UI helpers only when a concrete provider feature needs them.
