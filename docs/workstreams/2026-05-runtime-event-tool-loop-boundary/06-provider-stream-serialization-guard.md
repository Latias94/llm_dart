# Provider Stream Serialization Guard

Date: 2026-05-13
Status: implemented

## What Landed

This slice introduces `LanguageModelStreamEventJsonCodec` in
`llm_dart_provider`.

The codec keeps the current `text-stream-events` envelope wire shape so
existing transport/persistence data does not churn during the compatibility
window, but it enforces the new provider boundary:

- provider model-call stream serialization uses a provider-owned name
- encoding rejects runtime-only events before writing JSON
- decoding rejects runtime-only events before handing values to provider code
- focused provider package libs are guarded against reintroducing
  `TextStreamEvent` / `TextStreamEventJsonCodec` names

The old `TextStreamEventJsonCodec` remains available for runtime/chat
compatibility until full-stream event ownership moves to `llm_dart_ai`.

## Reference Lesson

`repo-ref/ai` keeps provider stream parts (`LanguageModelV4StreamPart`) and AI
runtime full stream parts (`TextStreamPart`) as different semantic surfaces.
This slice applies the same ownership rule in Dart without changing the wire
format yet.

## Validation

- `packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart`
  verifies provider event round-tripping and runtime-only event rejection.
- `test/provider_stream_naming_guard_test.dart` scans focused provider package
  libs and fails if provider implementations use the runtime stream names.
- `dart test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_provider/test/language_model_stream_event_test.dart test/provider_stream_naming_guard_test.dart`
- `dart test packages/llm_dart_core/test/text_stream_event_json_codec_test.dart packages/llm_dart_chat/test/http_chat_transport_protocol_test.dart packages/llm_dart_chat/test/http_chat_transport_server_adapter_test.dart`
- `dart analyze packages/llm_dart_provider packages/llm_dart_ai packages/llm_dart_chat test/provider_stream_naming_guard_test.dart`

## Remaining Work

This is still a compatibility layer over the old event classes. The next
structural split should move runtime-only event classes and full-stream
serialization ownership into `llm_dart_ai`, then leave `llm_dart_provider`
with only model-call stream event classes.

A broader `dart analyze packages/llm_dart_core ...` still reports older
`llm_dart_core` tests that reference removed prompt-side `providerMetadata`.
That is a separate cleanup from this provider stream serialization guard.
