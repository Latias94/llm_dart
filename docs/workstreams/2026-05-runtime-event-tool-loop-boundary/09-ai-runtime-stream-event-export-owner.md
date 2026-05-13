# AI Runtime Stream Event Export Owner

Date: 2026-05-13
Status: implemented

## What Landed

This slice makes the `llm_dart_ai` entrypoint the app-facing owner of
full-stream event names.

The event implementations are still compatibility aliases to the legacy
provider classes, but the public import boundary has moved:

- `llm_dart_ai` hides provider-exported `TextStreamEvent` event class names
- `llm_dart_ai` exports AI-owned compatibility aliases from
  `src/stream/text_stream_event.dart`
- `llm_dart_core` re-exports stream event names through `llm_dart_ai`
- `TextStreamEventJsonCodec` now uses the AI-owned stream event aliases in its
  public method signatures

This preserves source compatibility for app/runtime consumers while preventing
new runtime code from depending on provider as the semantic owner of
`TextStreamEvent`, `StepStartEvent`, `AbortEvent`, and related full-stream
events.

## Validation

- `dart analyze`
- `dart test packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/generate_text_result_accumulator_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_core/test/text_stream_event_json_codec_test.dart test/ai_entrypoint_test.dart`

## Remaining Work

The aliases still point at provider implementations. The next hard split is to
move the event class definitions and runtime-only event serialization branches
into `llm_dart_ai`, then remove or narrow the legacy provider export.
