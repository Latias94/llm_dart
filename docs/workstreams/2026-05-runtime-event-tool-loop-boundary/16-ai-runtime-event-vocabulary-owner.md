# AI Runtime Event Vocabulary Owner

Date: 2026-05-13
Status: implemented

## What Landed

`llm_dart_ai` now owns concrete full-stream event classes instead of exposing
compatibility typedefs over provider stream classes.

The migration keeps the provider/runtime seam explicit:

- provider model calls still emit `LanguageModelStreamEvent`
- `adaptLanguageModelStreamEvents(...)` validates provider events and maps
  them into AI-owned `TextStreamEvent` values
- `TextStreamEventJsonCodec` keeps the existing wire shape by bridging to the
  legacy provider codec internally
- runtime, UI projection, chat, and structured-output code now operate on the
  AI event vocabulary

Tests and examples that implement `LanguageModel` now return provider-owned
`LanguageModelStreamEvent` streams explicitly. Tests that need AI runtime
events keep using `TextStreamEvent`.

## Why This Matters

This is the first real ownership split after the naming and codec guards.
Provider code can continue to focus on single model-call parts, while
`llm_dart_ai` can evolve full generation-run events without forcing provider
packages to understand runtime lifecycle events.

The bridge is intentionally temporary. Once provider compatibility exports are
narrowed, the AI codec can stop round-tripping through the legacy provider
full-stream codec and own serialization directly.

## Validation

- `dart analyze`
- `dart analyze packages/llm_dart_ai`
- `dart analyze packages/llm_dart_core packages/llm_dart_chat packages/llm_dart_flutter`
- `dart test packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/language_model_stream_adapter_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`
- `dart test packages/llm_dart_core/test/text_stream_event_json_codec_test.dart`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`

## Remaining Work

Provider still exposes legacy full-stream class names during the migration
window. The next cleanup should narrow provider `TextStreamEvent` exports to a
compatibility layer, then replace the AI codec bridge with native AI
serialization.
