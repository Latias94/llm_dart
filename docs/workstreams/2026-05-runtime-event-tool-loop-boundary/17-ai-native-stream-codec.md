# AI Native Stream Codec

Date: 2026-05-13
Status: implemented

## What Landed

`TextStreamEventJsonCodec` now encodes and decodes AI-owned
`TextStreamEvent` classes directly. It no longer delegates through
`provider.TextStreamEventJsonCodec`.

The codec still uses provider-owned shared primitives and JSON helpers for
stable cross-package values:

- `ProviderMetadata`
- `UsageStats`
- `ModelError`
- generated files and sources
- tool call/result content and tool output encoding

The full-stream event vocabulary and event JSON switch now live in
`llm_dart_ai`.

## Why This Matters

This removes the last full-stream serialization dependency on provider event
classes. Provider stream serialization can keep shrinking toward
`LanguageModelStreamEventJsonCodec`, while AI runtime serialization can evolve
full generation-run events, step lifecycle, aborts, and app-side tool events
without changing provider contracts.

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart test packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart`
- `dart test packages/llm_dart_core/test/text_stream_event_json_codec_test.dart`
- `dart test test/provider_stream_naming_guard_test.dart`

## Remaining Work

The provider package still exposes legacy full-stream event class names during
the migration window. The next boundary cleanup should make provider
`TextStreamEvent` compatibility exports private or deprecated, then update
provider docs so new provider implementations only use
`LanguageModelStreamEvent`.
