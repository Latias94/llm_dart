# AI Runtime Stream Serialization Owner

Date: 2026-05-13
Status: implemented

## What Landed

This slice makes `llm_dart_ai` the app-facing owner of
`TextStreamEventJsonCodec`.

The new codec is a compatibility wrapper over the legacy provider
implementation, so the existing `text-stream-events` envelope and chunk shape
stay stable. The important architectural move is the import boundary:

- `package:llm_dart_ai/llm_dart_ai.dart` hides the provider-owned legacy
  `TextStreamEventJsonCodec`
- `llm_dart_ai` exports its own `TextStreamEventJsonCodec`
- `llm_dart_core/serialization.dart` now re-exports the AI-owned codec
- `llm_dart_chat` continues to compile against the runtime-facing name through
  its existing `llm_dart_ai` dependency

This prepares the next structural move where full-stream event classes can
leave `llm_dart_provider` without changing app-facing serialization imports.

## Reference Lesson

`repo-ref/ai` separates provider stream parts from runtime full-stream parts.
This slice applies that same ownership rule to serialization names first:
provider serialization uses `LanguageModelStreamEventJsonCodec`, while
runtime/app serialization uses `TextStreamEventJsonCodec`.

## Validation

- `packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart` verifies
  that the runtime entrypoint owns the codec name and still supports
  full-stream runtime-only events.

## Remaining Work

The codec still delegates to the legacy provider implementation. The next
runtime ownership slice should move the actual full-stream event classes and
implementation into `llm_dart_ai`, then remove `TextStreamEventJsonCodec` from
the provider surface.
