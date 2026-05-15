# Provider Architecture Completion Audit

## Objective Restated

Audit the provider architecture after the fearless codec-boundary refactors and
decide whether more high-value provider internals must be refactored now.

The concrete completion line is:

- OpenAI, Anthropic, Google, and Ollama request/result/stream codec boundaries
  have current-state evidence.
- Provider-private helpers stay inside provider packages and are not exposed
  through public barrels by accident.
- OpenAI, Anthropic, and Google fixture contracts protect the important request
  body, stream event, and replay behavior that was recently refactored.
- Remaining large files are classified as refactor-now, defer, or keep.
- Dependency direction, public API surface, focused tests, and dependency guards
  are verified against the current tree.
- Any large remaining work is recorded as a future workstream/goal instead of
  being expanded into this audit.

## Prompt-To-Artifact Checklist

| Requirement | Evidence |
| --- | --- |
| Do not change public API. | No changes to `packages/llm_dart_openai/lib/llm_dart_openai.dart`, `packages/llm_dart_anthropic/lib/llm_dart_anthropic.dart`, `packages/llm_dart_google/lib/llm_dart_google.dart`, `packages/llm_dart_ollama/lib/llm_dart_ollama.dart`, or provider `pubspec.yaml` files were needed for this audit. |
| Do not push. | Current work was local only on `refactor/architecture-foundation`. |
| Audit OpenAI request/result/stream codec boundaries. | Current OpenAI internals keep request encoding in `openai_responses_request_*` and `openai_chat_completions_request_*` helpers, stream state/event/tool/result projection in `openai_responses_stream_*` and `openai_chat_completions_stream_*`, and public provider facades in `openai_language_model.dart`. Remaining large OpenAI files are native lifecycle clients or product-specific surfaces rather than one mixed text codec. |
| Audit Anthropic request/result/stream codec boundaries. | `anthropic_messages_codec.dart` is a thin facade around `anthropic_content_encoder.dart`, `anthropic_prompt_blocks.dart`, `anthropic_tool_replay_encoder.dart`, `anthropic_request_options_encoder.dart`, and `anthropic_request_json.dart`. Stream projection is split across `anthropic_stream_state.dart`, `anthropic_stream_content_codec.dart`, `anthropic_stream_tool_codec.dart`, `anthropic_stream_result_codec.dart`, and `anthropic_stream_util.dart`. |
| Audit Google request/result/stream codec boundaries. | `google_generate_content_codec.dart` now delegates generation config, prompt-message encoding, content projection, tool configuration, replay JSON, and stream part projection to provider-private helpers. `google_stream_codec.dart` is a chunk facade and re-exports `GoogleGenerateContentStreamState` only to preserve the existing public entrypoint. |
| Audit Ollama request/result/stream codec boundaries. | Ollama is already split into `ollama_chat_request_codec.dart`, `ollama_chat_response_codec.dart`, `ollama_chat_stream_codec.dart`, and `ollama_tool_codec.dart`, with `ollama_language_model.dart` staying as the transport/model facade. The request codec is the only remaining larger codec file, but it is provider-local and covered by package tests. |
| Check provider-private helper leakage. | Provider barrels export only intentional public surfaces. OpenAI does not export its request/stream helper codecs. Anthropic exports the public Messages/result/stream codecs and public replay/file surfaces, but not the private encoders. Google exports public GenerateContent/result/stream/replay surfaces, but not `google_generation_config_encoder.dart`, `google_prompt_message_encoder.dart`, `google_replay_json.dart`, `google_stream_part_codec.dart`, or support helpers. Ollama exports no chat codec helpers. |
| Check OpenAI fixture contracts. | `packages/llm_dart_openai/test/fixtures/openai/` contains `responses_request_body_golden.json`, `chat_completions_request_body_golden.json`, `responses_stream_events_golden.json`, and `chat_completions_stream_events_golden.json`. `openai_fixture_contract_test.dart` passed in the current audit run. |
| Check Anthropic fixture contracts. | `packages/llm_dart_anthropic/test/fixtures/anthropic/` contains `messages_request_body_golden.json`, `messages_request_metadata_golden.json`, `messages_replay_request_body_golden.json`, and `messages_stream_events_golden.json`. `anthropic_fixture_contract_test.dart` passed in the current audit run. |
| Check Google fixture contracts. | `packages/llm_dart_google/test/fixtures/google/` contains `generate_content_request_body_golden.json` and `generate_content_stream_events_golden.json`. The request fixture includes function-call id replay, server-side tool replay, native tools, structured output, media, and tool-output files. `google_fixture_contract_test.dart` passed in the current audit run. |
| Scan remaining large files and classify them. | See "Remaining Refactor Classification" below. No refactor-now blocker was found. |
| Check dependency direction. | `dart run tool\check_workspace_dependency_guards.dart` passed in the current audit run. |
| Run necessary analyze and focused tests. | Four provider package analysis passed. OpenAI/Anthropic/Google fixture contracts passed. Ollama package tests passed. |
| Commit the audit artifact. | This document and the workstream README index are the only planned audit artifacts. |

## Current Validation Evidence

Commands run from the repository root during this audit:

```powershell
dart analyze packages\llm_dart_openai packages\llm_dart_anthropic packages\llm_dart_google packages\llm_dart_ollama
dart test packages\llm_dart_openai\test\openai_fixture_contract_test.dart packages\llm_dart_anthropic\test\anthropic_fixture_contract_test.dart packages\llm_dart_google\test\google_fixture_contract_test.dart
dart test packages\llm_dart_ollama
dart run tool\check_workspace_dependency_guards.dart
```

Results:

- Provider package analysis: passed with no issues.
- OpenAI/Anthropic/Google fixture contracts: passed, 10 tests.
- Ollama package tests: passed, 24 tests.
- Workspace dependency guard: passed.

## Boundary Evidence

### OpenAI

The OpenAI package now has separate provider-local modules for:

- Responses request body assembly, prompt item projection, tools, request
  options, response format, file/media handling, and replay references.
- Chat Completions prompt/tool/options request encoding.
- Responses stream state, event dispatch, tool-call projection, result/finish
  mapping, and metadata helpers.
- Chat Completions stream state, event dispatch, tool-call projection,
  finish/usage mapping, and compatible-provider metadata helpers.

The remaining largest OpenAI files are not one mixed chat codec:

- `openai_assistants.dart`
- `openai_files.dart`
- `openai_responses_lifecycle.dart`
- `openai_moderation.dart`
- `openai_image_model.dart`

Those are provider-native product/lifecycle clients or non-text model surfaces.
They should not be forced into the text-codec workstream unless a focused
client-specific fixture or lifecycle boundary goal is opened.

### Anthropic

Anthropic Messages request encoding now has a thin facade and provider-private
components:

- `anthropic_messages_codec.dart`
- `anthropic_content_encoder.dart`
- `anthropic_prompt_blocks.dart`
- `anthropic_tool_replay_encoder.dart`
- `anthropic_request_options_encoder.dart`
- `anthropic_request_json.dart`

Anthropic stream projection is already split by state/content/tool/result
responsibilities. `anthropic_result_codec.dart` and
`anthropic_code_execution_replay.dart` remain larger because they own public
result/replay semantics. They are candidates for future fixture expansion, not
mandatory architecture blockers.

### Google

Google GenerateContent has reached the same facade-plus-provider-private-helper
shape:

- `google_generate_content_codec.dart` is the request-body facade.
- `google_generation_config_encoder.dart` owns generation config and thinking
  config mapping.
- `google_content_projection.dart` owns prompt-level projection and Gemma
  system folding.
- `google_prompt_message_encoder.dart` owns message/part encoding.
- `google_function_response_replay.dart` stays as public replay data, while
  `google_function_response_replay_support.dart` owns function-response file
  and tool-output encoding details.
- `google_server_tool_replay.dart` stays as public replay data, while
  `google_server_tool_replay_support.dart` and `google_replay_json.dart` own
  replay JSON validation and metadata support.
- `google_stream_codec.dart` is the stream chunk facade.
- `google_stream_part_codec.dart` owns stream part projection.
- `google_stream_state.dart` owns stream state.

The remaining larger Google files are image/speech/model/custom-part surfaces
or result/replay modules with public semantics. They do not require immediate
breaking refactor work.

### Ollama

Ollama has a smaller provider surface and no public codec exports. It is split
into:

- `ollama_chat_request_codec.dart`
- `ollama_chat_response_codec.dart`
- `ollama_chat_stream_codec.dart`
- `ollama_tool_codec.dart`
- `ollama_language_model.dart`

`ollama_chat_request_codec.dart` is the largest remaining text-codec file in
the audited provider set. Current tests cover prompt/tool/response-format
encoding, reasoning options, streaming, raw chunks, provider-option rejection,
image resolution, and binary resolver behavior. A fixture contract would make
future refactors easier, but the audit does not find enough risk to force a
split before the next architecture goal.

## Remaining Refactor Classification

### Refactor Now

None.

The current provider architecture has enough boundary separation and fixture
coverage to stop broad fearless refactoring here. Continuing to split files
without a new focused product or risk signal would add churn more than clarity.

### Defer

- Add Ollama fixture contracts for chat request body and stream events if the
  next workstream wants all main text providers to have golden fixtures.
- Consider Anthropic result/replay fixtures if future Anthropic code execution
  or server-tool replay changes resume.
- Consider OpenAI native lifecycle client fixtures if assistants/files/raw
  Responses lifecycle APIs become the next release risk.
- Consider Google result-codec fixture coverage if GenerateContent response
  projection changes again.

### Keep

- Keep provider utility helpers provider-local. The extracted helper contracts
  still differ by provider semantics, especially around tool choice, native
  tool replay, stream state, file references, and metadata.
- Keep provider-native lifecycle clients provider-owned instead of widening the
  shared model contract.
- Keep public barrels narrow and intentional. Do not export helper/support
  modules merely for test or implementation convenience.

## Recommended Next Goal

Do not start another broad provider-codec refactor immediately.

The best next goal is one of these focused options:

1. Ollama fixture contracts: add golden request and stream event fixtures for
   the remaining main text provider without changing Ollama public API.
2. Release-readiness audit: run the full release readiness script and update
   release-hardening docs if the branch is intended to become the next alpha.
3. Provider-native lifecycle fixture audit: pick one native lifecycle area
   such as OpenAI files/assistants/raw Responses lifecycle and add focused
   fixture or mock transport contracts.

The default recommendation is option 1 only if the team wants fixture parity
across all primary text providers. Otherwise, move to release readiness.
