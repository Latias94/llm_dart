# Provider Event Vocabulary First Slice

Date: 2026-05-13
Status: implemented

## What Landed

This slice adds the first concrete code seam for the M1 decision:

- `llm_dart_provider` now exports `LanguageModelStreamEvent`
- `LanguageModelStreamEvent` is currently a compatibility typedef over
  `TextStreamEvent`
- provider-facing validation rejects runtime-only events:
  - `StepStartEvent`
  - `StepFinishEvent`
  - `ToolOutputDeniedEvent`
  - `AbortEvent`
- `llm_dart_ai` now has an internal adapter that validates provider model-call
  events before treating them as runtime `TextStreamEvent` values
- `streamText(...)` and `StreamTextRunner` now use that adapter at their
  provider-call boundary
- `LanguageModel.doStream(...)` now advertises
  `Stream<LanguageModelStreamEvent>` at the provider interface while the typedef
  keeps existing focused providers source-compatible during this slice

This deliberately avoids migrating every focused provider in the same slice.
The point is to create the ownership seam and prove it with tests before the
large focused-provider codec migration begins.

## Files

- `packages/llm_dart_provider/lib/src/stream/language_model_stream_event.dart`
- `packages/llm_dart_provider/lib/src/model/language_model.dart`
- `packages/llm_dart_provider/lib/foundation.dart`
- `packages/llm_dart_ai/lib/src/model/language_model_stream_adapter.dart`
- `packages/llm_dart_ai/lib/src/model/language_model.dart`
- `packages/llm_dart_ai/lib/src/model/stream_text_runner.dart`
- `packages/llm_dart_ai/lib/internal.dart`
- `packages/llm_dart_provider/test/language_model_stream_event_test.dart`
- `packages/llm_dart_ai/test/language_model_stream_adapter_test.dart`
- `packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`

## Current Semantics

The provider model-call stream still uses the same underlying event classes
during the migration window. The new name and guard are intentional:

- new provider-facing code can start naming the model-call layer correctly
- runtime-only events can be rejected before they become provider contract
  assumptions
- `LanguageModel.doStream(...)` can advertise the provider-owned stream name
  before every implementation is mechanically renamed

Existing providers still compile because `LanguageModelStreamEvent` is a
transparent compatibility typedef for this slice.

Provider-allowed events in this first guard include current provider-emitted
events such as start, response metadata, text/reasoning chunks, files, sources,
tool input chunks, tool calls, provider tool results, provider approval
requests, finish, raw, custom, and error events.

Runtime-only events rejected by the guard are lifecycle/control events that
should be created by `llm_dart_ai`, not by provider packages.

## Validation

- `dart test packages/llm_dart_provider/test/language_model_stream_event_test.dart`
- `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`
- `dart test packages/llm_dart_ai/test/language_model_stream_adapter_test.dart`
- `dart test packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`
- `dart test packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart`
- `dart analyze packages/llm_dart_provider packages/llm_dart_ai`

## Next Slice

The next implementation slice should migrate focused provider implementations,
stream codecs, replay helpers, and tests to the `LanguageModelStreamEvent`
name where they are provider-facing. Runtime, chat, UI, and structured-output
code should continue using `TextStreamEvent`.

Do not remove `TextStreamEvent` from provider until replay helpers,
serialization, chat tests, and provider stream codecs have a reviewed
migration path.
