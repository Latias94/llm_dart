# Runtime-Only Provider Event Guard

Date: 2026-05-13
Status: implemented

## What Landed

This slice marks the runtime-only events that still physically live in
`llm_dart_provider` during the compatibility window:

- `StepStartEvent`
- `StepFinishEvent`
- `ToolOutputDeniedEvent`
- `AbortEvent`

The comments make the ownership rule explicit in code: provider model streams
must not emit these events. They remain in the provider package only until the
runtime full-stream event classes move to `llm_dart_ai`.

The provider stream guard now also scans focused provider package libs and
`llm_dart_test` fakes for those runtime-only event names. This prevents
provider implementations from accidentally depending on multi-step runtime
events while the compatibility aliases still exist.

## Validation

- `dart analyze packages/llm_dart_provider test/provider_stream_naming_guard_test.dart`
- `dart test test/provider_stream_naming_guard_test.dart packages/llm_dart_provider/test/language_model_stream_event_test.dart packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart`

## Remaining Work

The event classes still need to move out of `llm_dart_provider`. Once that
happens, this guard can become stricter and reject provider exports of these
runtime-only classes entirely.
