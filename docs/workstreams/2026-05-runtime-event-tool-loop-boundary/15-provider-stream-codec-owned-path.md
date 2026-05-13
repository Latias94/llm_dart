# Provider Stream Codec Owned Path

Date: 2026-05-13
Status: implemented

## What Landed

`LanguageModelStreamEventJsonCodec` now owns its provider model-call event
serialization path directly instead of delegating through the legacy full
`TextStreamEventJsonCodec`.

The codec keeps the existing envelope kind and wire shape for supported
model-call events, but it rejects runtime-only event wire types during decode:

- tool output denial
- step start
- step finish
- abort

Encoding still validates the event stream before producing the envelope, so
provider packages cannot accidentally serialize AI runtime lifecycle state.

## Why This Matters

The provider layer should not need a codec that understands full runtime,
chat, or UI lifecycle events. Keeping the provider codec vocabulary small makes
the next breaking step clearer: `llm_dart_provider` can keep model-call stream
classes, while `llm_dart_ai` can become the sole owner of full
`TextStreamEvent` classes and runtime serialization.

This mirrors the useful boundary in `repo-ref/ai`: model providers emit
language-model call stream parts; the AI runtime turns those parts into a full
generation run stream with step and tool-loop lifecycle events.

## Validation

- `dart analyze packages/llm_dart_provider packages/llm_dart_ai`
- `dart test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart`
- `dart test test/provider_stream_naming_guard_test.dart`

## Remaining Work

The full event class implementation still temporarily lives in provider
compatibility code. The next M2/M3 boundary step should move full-stream
runtime event classes and codec ownership into `llm_dart_ai`, then keep
provider exports as migration aliases only where necessary.
