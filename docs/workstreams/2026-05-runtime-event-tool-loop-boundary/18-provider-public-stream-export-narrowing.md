# Provider Public Stream Export Narrowing

Date: 2026-05-13
Status: implemented

## What Landed

`llm_dart_provider` no longer exports the legacy full-stream runtime surface
from its public entrypoint:

- `TextStreamEvent`
- `TextStreamEventJsonCodec`
- `StepStartEvent`
- `StepFinishEvent`
- `ToolOutputDeniedEvent`
- `AbortEvent`

Provider users still get the model-call event classes that a single
`LanguageModel.doStream(...)` call can legally emit, plus the provider-owned
`LanguageModelStreamEvent` type name and
`LanguageModelStreamEventJsonCodec`.

AI runtime code keeps the full-stream event vocabulary in `llm_dart_ai`.
The provider-to-AI bridge now accepts and returns
`LanguageModelStreamEvent`, and it rejects runtime-only AI events when callers
try to convert them back into provider model-call streams.

## Why This Matters

This is the first public API break that makes the provider package visibly
model-call scoped. It prevents new provider implementations from depending on
runtime lifecycle events by accident, while preserving provider-specific
model-call features such as provider metadata, tool calls, approval requests,
sources, files, raw chunks, and typed provider options.

The code still keeps internal legacy event classes while the split is being
completed. Tests that intentionally exercise the old runtime-only provider
classes import the internal legacy file explicitly, making the compatibility
debt visible instead of public.

## Validation

- `dart analyze packages/llm_dart_provider packages/llm_dart_ai`
- `dart test packages/llm_dart_provider/test/language_model_stream_event_test.dart packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart`
- `dart test packages/llm_dart_ai/test/language_model_stream_adapter_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart`
- `dart test test/provider_stream_naming_guard_test.dart`

## Remaining Work

The internal provider compatibility event file should eventually be split into
a provider-only event vocabulary or removed once no package needs it for
migration tests. That can happen after focused provider codecs and public docs
no longer rely on the old file shape.
