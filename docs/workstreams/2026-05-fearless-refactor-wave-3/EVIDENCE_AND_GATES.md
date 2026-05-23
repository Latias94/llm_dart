# Fearless Refactor Wave 3 — Evidence And Gates

Status: Closed
Last updated: 2026-05-23

## Smallest Current Repro

```powershell
dart analyze packages/llm_dart_chat
dart test packages/llm_dart_chat/test/default_chat_session_test.dart
```

These commands were the final slice gate for FR3-060.

## Gate Set

### FR3-020 Chat Session Turn Lifecycle

```powershell
dart analyze packages/llm_dart_chat
dart test packages/llm_dart_chat/test/default_chat_session_test.dart
```

### FR3-030 OpenAI-Family Options

```powershell
dart analyze packages/llm_dart_openai
dart test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart
```

### FR3-040 Provider Fixture Parity

Use provider-specific fixture tests added or changed by the slice, plus package
analysis for touched provider packages.

### FR3-050 Serialization Protocol Families

```powershell
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test
```

### FR3-060 Root Legacy Classification

Run relevant guard scripts and workspace analysis smoke selected by the files
changed in the slice.

### Broader Closeout Gate

```powershell
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_provider_replay_metadata_guards.dart
dart run tool/check_provider_metadata_namespace_guards.dart
git diff --check
```

Run a fuller release-readiness smoke if public exports, package metadata, or
consumer-facing examples change.

## Evidence Anchors

- `docs/workstreams/2026-05-fearless-refactor-wave-3/DESIGN.md`
- `docs/workstreams/2026-05-fearless-refactor-wave-3/TODO.md`
- `docs/workstreams/2026-05-fearless-refactor-wave-3/MILESTONES.md`
- Task-specific code and test paths recorded under each slice.

## FR3-010 Evidence

Status: done on 2026-05-23.

Evidence:

- New workstream docs created.
- Five refactor candidates ordered from the architecture report.
- No existing active workstream was found before opening this lane.

## FR3-020 Evidence

Status: done on 2026-05-23.

Changed implementation:

- Added `packages/llm_dart_chat/lib/src/default_chat_session_turn_lifecycle.dart`.
- Reduced `packages/llm_dart_chat/lib/src/default_chat_session.dart` to a
  public chat-session adapter that delegates turn commands to the lifecycle
  module.

Verification:

```powershell
dart analyze packages/llm_dart_chat
dart test packages/llm_dart_chat/test/default_chat_session_test.dart
dart test packages/llm_dart_chat/test
git diff --check
```

Result:

- `dart analyze packages/llm_dart_chat` passed with no issues.
- `default_chat_session_test.dart` passed 43 tests.
- Full `llm_dart_chat` package test suite passed 129 tests.
- `git diff --check` passed; Git only reported LF-to-CRLF working-copy
  warnings.

## FR3-030 Evidence

Status: done on 2026-05-23.

Changed implementation:

- Moved OpenAI-family typed/bag invocation merge into
  `packages/llm_dart_openai/lib/src/provider/openai_family_invocation_options.dart`.
- Kept `openai_provider_options_bag_generate_text.dart` and
  `openai_provider_options_bag_non_text.dart` focused on compatibility bag
  parse/encode transport.
- Updated embedding, image, speech, and transcription request modules to
  resolve invocation options through the typed invocation module instead of the
  bag transport module.

Verification:

```powershell
dart analyze packages/llm_dart_openai
dart test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart
dart test packages/llm_dart_openai/test/openai_embedding_model_body_test.dart packages/llm_dart_openai/test/openai_image_generation_body_test.dart packages/llm_dart_openai/test/openai_speech_model_body_test.dart packages/llm_dart_openai/test/openai_transcription_model_body_test.dart
dart test packages/llm_dart_openai/test
git diff --check
```

Result:

- `dart analyze packages/llm_dart_openai` passed with no issues.
- `openai_family_option_resolver_test.dart` passed 8 tests.
- Focused non-text option tests passed 15 tests.
- Full `llm_dart_openai` package test suite passed 354 tests.
- `git diff --check` passed; Git only reported LF-to-CRLF working-copy
  warnings.

## FR3-040 Evidence

Status: done on 2026-05-23.

Changed implementation:

- Added `packages/llm_dart_ollama/test/ollama_fixture_contract_test.dart`.
- Added provider-local Ollama fixtures under
  `packages/llm_dart_ollama/test/fixtures/ollama/` for chat request body,
  compatibility warnings, and stream events.
- Covered image binary resolution, tool-call replay shape, tool definitions,
  response format projection, provider options, warnings, raw stream chunks,
  reasoning parts, text parts, tool calls, finish metadata, and usage metadata.

Verification:

```powershell
dart format packages\llm_dart_ollama\test\ollama_fixture_contract_test.dart
dart test packages/llm_dart_ollama/test/ollama_fixture_contract_test.dart
dart analyze packages/llm_dart_ollama
dart test packages/llm_dart_ollama/test
git diff --check
```

Result:

- Focused `ollama_fixture_contract_test.dart` passed 2 tests.
- `dart analyze packages/llm_dart_ollama` passed with no issues.
- Full `llm_dart_ollama` package test suite passed 37 tests.
- `git diff --check` passed; Git only reported LF-to-CRLF working-copy
  warnings.

## FR3-050 Evidence

Status: done on 2026-05-23.

Changed implementation:

- Added `serialization_metadata_support.dart`,
  `serialization_media_support.dart`, and `serialization_tool_support.dart`.
- Kept `SerializationJsonSupport` source-compatible as the public compatibility
  facade over those narrower protocol-family supports.
- Updated provider stream and prompt JSON codecs to depend on the narrower
  support modules instead of the wide facade.
- Added `serialization_support_boundary_test.dart` to prevent provider internal
  JSON codecs from reintroducing a dependency on `SerializationJsonSupport`.

Verification:

```powershell
dart format packages\llm_dart_provider\lib\src\serialization\serialization_json_support.dart packages\llm_dart_provider\lib\src\serialization\serialization_metadata_support.dart packages\llm_dart_provider\lib\src\serialization\serialization_media_support.dart packages\llm_dart_provider\lib\src\serialization\serialization_tool_support.dart packages\llm_dart_provider\lib\src\serialization\language_model_stream_core_event_json_codec.dart packages\llm_dart_provider\lib\src\serialization\language_model_stream_content_event_json_codec.dart packages\llm_dart_provider\lib\src\serialization\language_model_stream_tool_input_event_json_codec.dart packages\llm_dart_provider\lib\src\serialization\language_model_stream_tool_lifecycle_event_json_codec.dart packages\llm_dart_provider\lib\src\serialization\prompt_content_part_json_codec.dart packages\llm_dart_provider\lib\src\serialization\prompt_tool_part_json_codec.dart
dart format packages\llm_dart_provider\test\serialization_support_boundary_test.dart
dart test packages/llm_dart_provider/test/serialization_support_boundary_test.dart
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test
git diff --check
```

Result:

- Boundary test passed.
- `dart analyze packages/llm_dart_provider` passed with no issues.
- Full `llm_dart_provider` package test suite passed 94 tests.
- `git diff --check` passed; Git only reported LF-to-CRLF working-copy
  warnings.

## FR3-060 Evidence

Status: done on 2026-05-23.

Changed implementation:

- Added `tool/root_legacy_classification.dart` as the current root legacy
  decision table for keep/remove/document classification.
- Updated `tool/check_root_package_boundary_guards.dart` to derive its
  allowlists from that classification table.
- Added
  `docs/workstreams/2026-05-fearless-refactor-wave-3/06-root-legacy-classification.md`
  as the human-readable classification anchor.
- Added a classification test that asserts the current keep/remove/document
  surface set.
- Updated the historical April legacy-deprecation planning docs with a
  superseded note that points to the current classification anchor.

Verification:

```powershell
dart analyze tool/check_root_package_boundary_guards.dart tool/root_legacy_classification.dart test/tool/check_root_package_boundary_guards_test.dart
dart test test/tool/check_root_package_boundary_guards_test.dart
dart test test/tool/check_root_package_boundary_guards_test.dart test/tool/check_example_api_guards_test.dart test/tool/check_test_legacy_import_guards_test.dart
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_root_package_boundary_guards.dart
dart run tool/check_example_api_guards.dart
dart run tool/check_test_legacy_import_guards.dart
git diff --check
```

Result:

- The classification test passed and confirmed the keep/remove/document set.
- `dart analyze` over the touched tool and test files passed with no issues.
- Root, example, test legacy, and workspace dependency guards all passed.
- `git diff --check` passed; Git only reported LF-to-CRLF working-copy
  warnings.

## Notes

Fresh verification is required before marking a task, Codex goal, or lane
complete.
