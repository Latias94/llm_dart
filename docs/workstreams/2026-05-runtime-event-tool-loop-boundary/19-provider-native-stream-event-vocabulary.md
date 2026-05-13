# Provider Native Stream Event Vocabulary

Date: 2026-05-13
Status: implemented

## What Landed

`llm_dart_provider` now owns a real provider-only
`LanguageModelStreamEvent` sealed class and provider model-call event classes
extend that base directly.

The provider package no longer contains the internal legacy full-stream event
file or codec:

- removed `src/stream/text_stream_event.dart`
- removed `src/serialization/text_stream_event_json_codec.dart`
- removed provider runtime-only event classes for step start, step finish,
  tool-output denial, and abort

`LanguageModelStreamEventJsonCodec` remains the only provider stream codec.
It can still decode the existing wire envelope for model-call events, but it
rejects runtime-only event type strings at the provider boundary.

## Why This Matters

The previous slice hid legacy full-stream names from the public provider
entrypoint. This slice removes the hidden compatibility implementation itself.
That makes the provider package structurally model-call scoped instead of
only API-scoped.

AI runtime full-stream events remain in `llm_dart_ai`. The bridge from
provider to AI is now a pure model-call to runtime mapping, and the reverse
bridge rejects AI runtime-only events before they can become provider events.

## Validation

- `dart analyze`
- `dart test packages/llm_dart_provider/test/language_model_stream_event_test.dart packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart`
- `dart test packages/llm_dart_ai/test/language_model_stream_adapter_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart`
- `dart test test/provider_stream_naming_guard_test.dart`

## Remaining Work

Focused provider event classes still share user-facing names such as
`TextDeltaEvent` and `ToolCallEvent` with AI runtime events. That is acceptable
while package prefixes or `llm_dart_ai` hides keep the boundary explicit. A
future breaking slice can decide whether provider event class names need a
`LanguageModel*` prefix, but that should be weighed against verbosity and
provider implementation ergonomics.
