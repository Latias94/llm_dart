# Examples And Release Readiness

Date: 2026-05-14
Status: complete

## Example Migration

The MCP examples now teach the primary runtime helpers:

- `example/06_mcp_integration/stdio_examples/llm_client.dart` uses
  `core.generateText(...)` for non-streaming MCP tool continuation.
- `example/06_mcp_integration/http_examples/llm_client.dart` uses
  `core.generateText(...)` for HTTP MCP tool continuation.
- `example/06_mcp_integration/http_examples/simple_stream_client.dart` uses
  `core.streamText(...)` and a public `GenerateTextResultAccumulator` to render
  runtime events and build the final result.

Runner-named helpers remain available as advanced facades when callers need
`GenerateTextRunResult`, `StreamTextRunResult`, `stepStream`, or direct runner
construction. They are no longer the default teaching path in MCP examples.

## Migration Documentation

Release-facing migration guidance now uses this split:

- `generateTextCall(...)` / `streamTextCall(...)`: normal app text/result
  facades
- `generateText(...)` / `streamText(...)`: primary raw runtime helpers
- `runTextGeneration(...)` / `streamTextRun(...)`: advanced runtime result
  facades for explicit run/step inspection
- `LanguageModel.doGenerate(...)` / `doStream(...)`: provider contract only

## Validation

Fresh validation for this closure slice:

- `dart analyze example/06_mcp_integration`
  - passed
- `dart analyze packages/llm_dart_ai`
  - passed
- `dart analyze packages/llm_dart_chat`
  - passed
- `dart analyze packages/llm_dart_provider`
  - passed
- `dart analyze example packages/llm_dart_chat/example`
  - passed
- `dart test test/language_model_stream_event_test.dart
  test/language_model_stream_event_json_codec_test.dart
  test/provider_contracts_test.dart`
  - passed in `packages/llm_dart_provider`
- `dart test test/openai_chat_completions_stream_codec_test.dart
  test/openai_responses_stream_codec_test.dart`
  - passed in `packages/llm_dart_openai`
- `dart test test/anthropic_stream_codec_test.dart`
  - passed in `packages/llm_dart_anthropic`
- `dart test test/google_stream_codec_test.dart`
  - passed in `packages/llm_dart_google`
- `dart test test/generate_text_runner_test.dart test/stream_text_runner_test.dart
  test/generate_text_result_accumulator_test.dart
  test/text_stream_event_json_codec_test.dart
  test/language_model_stream_boundary_test.dart test/text_call_test.dart`
  - passed in `packages/llm_dart_ai`
- `dart test test/generate_text_runner_test.dart test/stream_text_runner_test.dart
  test/text_call_test.dart test/output_spec_test.dart test/tool_definition_test.dart`
  - passed in `packages/llm_dart_core`
- `dart test test/default_chat_session_test.dart test/http_chat_transport_test.dart
  test/http_chat_transport_server_adapter_test.dart`
  - passed in `packages/llm_dart_chat`
- `dart run tool/check_workspace_dependency_guards.dart`
  - passed
- `dart run tool/check_root_package_boundary_guards.dart`
  - passed
- `dart test test/tool/check_provider_replay_metadata_guards_test.dart`
  - passed
- `dart run tool/check_provider_replay_metadata_guards.dart`
  - passed
- `dart test test/tool/run_consumer_smoke_test.dart
  test/tool/run_workspace_publish_dry_run_test.dart`
  - passed
- `dart run tool/run_consumer_smoke.dart --direct-package-config`
  - passed 7 direct consumer smoke programs
- `dart run tool/run_workspace_publish_dry_run.dart`
  - passed for 12 publishable packages with 0 warnings; workspace override
    hints were expected and suppressed by the script
- `git diff --check`
  - passed

One attempted chat command included a nonexistent
`test/direct_chat_transport_test.dart` path and failed during test loading.
That was a command selection error, not a product test failure; the existing
direct transport coverage lives in `test/default_chat_session_test.dart`, which
passed in the corrected chat test run above.
