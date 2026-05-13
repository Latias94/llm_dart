# TODO

## Setup

- [x] Create the workstream scaffold
- [x] Define the canonical goal text
- [x] Record the initial scope and gap audit
- [ ] Link implementation PRs or commits as they land

## Decision Freeze

- [x] Decide whether root legacy is deleted directly or moved to a separate
  compatibility package
- [x] Freeze the final public import story for modern root and focused package
  users
- [x] Freeze whether runtime helpers keep `prompt:` provider-prompt inputs or
  move them behind advanced helper names
- [x] Freeze the typed provider options bag shape and raw escape hatch policy
- [x] Freeze the structured text/object result surface direction

Decision notes:

- root legacy will be deleted directly by default
- no separate compatibility package will be created unless concrete user demand
  appears after the modern migration recipes are in place
- root remains a modern facade and migration-documentation package
- focused provider packages remain the home for provider-native behavior
- `messages:` with `ModelMessage` is the default app-facing prompt path
- `prompt:` with `PromptMessage` remains available only as an advanced
  provider-contract path
- `CallOptions.providerOptions` remains typed; raw request escape hatches must
  be provider-owned fields on concrete provider option types, not a shared map
- `generateTextCall` and `streamTextCall` are the long-term combined text and
  structured-output result facade; `generateObject` and `streamObject` remain
  thin convenience wrappers or migration helpers

## Root Legacy Exit

- [x] Update root boundary guard intent for direct root legacy deletion
- [x] Remove consumer smoke dependency on `package:llm_dart/legacy.dart`
- [x] Add strict test guard mode for root legacy subpath imports
- [x] Expand legacy import guards to reject root legacy subpath imports
- [x] Switch strict legacy subpath import guard to the default mode after test
  migration
- [x] Shrink example guard allowlists for legacy imports
- [x] Migrate or delete root legacy tests before source deletion
  - 2026-05-13: deleted `test/core/error_test.dart`; modern error coverage is
    `packages/llm_dart_core/test/model_error_test.dart`
  - 2026-05-13: deleted `test/core/cancellation_test.dart`; modern
    cancellation coverage is in `llm_dart_provider` and `llm_dart_transport`
  - 2026-05-13: deleted `test/core/capability_test.dart`,
    `test/core/config_test.dart`, and `test/core/registry_test.dart`; these
    covered the legacy builder/provider registry model that is being removed
  - 2026-05-13: deleted `test/core/tool_validator_test.dart`,
    `test/core/tool_call_aggregator_test.dart`,
    `test/core/tool_execution_test.dart`,
    `test/core/tool_parameter_validation_test.dart`, and
    `test/core/tool_streaming_test.dart`; modern tool coverage is in
    `llm_dart_provider`, `llm_dart_ai`, and `llm_dart_chat`
  - 2026-05-13: deleted `test/core/dio_error_handler_test.dart`; transport
    error mapping coverage is in `llm_dart_transport`
  - 2026-05-13: deleted `test/models/chat_models_test.dart` and
    `test/models/tool_models_test.dart`; modern prompt/tool contract coverage
    is in `llm_dart_provider`, `llm_dart_ai`, and `llm_dart_chat`
  - 2026-05-13: deleted `test/models/audio_models_test.dart`,
    `test/models/file_models_test.dart`, `test/models/image_models_test.dart`,
    `test/models/chat_models_builder_test.dart`, and
    `test/models/enhanced_array_tools_test.dart`; modern coverage is in focused
    provider packages plus `llm_dart_ai` capability helpers
  - 2026-05-13: deleted `test/builder/http_config_test.dart` and
    `test/builder/llm_builder_test.dart`; `LLMBuilder` and builder-owned
    `HttpConfig` are root legacy ownership, with modern coverage in
    `llm_dart_transport`, `llm_dart_provider`, and typed provider option tests
  - 2026-05-13: deleted root legacy HTTP utility and integration tests under
    `test/utils/dio`, `test/utils/http_config_utils_test.dart`,
    `test/utils/timeout_priority_test.dart`, `test/test_dio_comprehensive.dart`,
    `test/integration/dio_end_to_end_test.dart`, and
    `test/integration/http_configuration_integration_test.dart`; modern HTTP
    coverage is transport-owned
  - 2026-05-13: deleted root OpenAI-family compatibility provider tests under
    `test/providers/deepseek`, `test/providers/groq`,
    `test/providers/phind`, `test/providers/xai`, and
    `test/providers/openrouter`; modern coverage is in `llm_dart_openai`
    profiles, entrypoints, model describers, chat-completions codecs, and typed
    provider options
  - 2026-05-13: deleted root ElevenLabs provider tests under
    `test/providers/elevenlabs`; modern coverage is in `llm_dart_elevenlabs`
    entrypoint, capability profile, model describer, speech, transcription,
    and voice catalog tests
  - 2026-05-13: deleted root Anthropic provider tests under
    `test/providers/anthropic`; modern coverage is in `llm_dart_anthropic`
    entrypoint, capability profile, model describer, language model,
    messages/stream/result codecs, files, MCP, and code-execution replay tests
  - 2026-05-13: deleted root Google provider tests under
    `test/providers/google`; modern coverage is in `llm_dart_google`
    entrypoint, capability profile, model describer, language model,
    generate-content/stream/result codecs, function response replay, server
    tool replay, image, speech, embedding, and custom part tests
  - 2026-05-13: deleted root Ollama provider tests under
    `test/providers/ollama`; modern coverage is in `llm_dart_ollama`
    entrypoint, capability profile, model describer, language model, embedding,
    and model catalog tests
- [x] Classify OpenAI residual root provider tests:
  - [x] Keep modern chat completions, Responses generation/streaming, files,
    images, moderation, speech, transcription, embeddings, built-in tools, and
    OpenAI-family profile behavior in `llm_dart_openai`
  - [x] Migrate retained Assistants lifecycle helpers to `llm_dart_openai`
  - [x] Migrate retained raw Responses lifecycle helpers to `llm_dart_openai`
  - [x] Delete root-only OpenAI builder, factory, provider bridge, message
    conversion, completion, and config layering tests
- [x] Delete or relocate root `lib/providers`
- [x] Delete or relocate root `lib/models`
- [x] Delete or relocate root `lib/builder`
- [x] Delete or relocate root compatibility implementation internals
- [x] Keep only explicitly documented migration hooks if required
- [x] Update root boundary guards to reject legacy implementation ownership
- [x] Update migration docs for removed or moved APIs

## User Prompt And Runtime Surface

- [x] Make `ModelMessage` and text shorthand inputs the default app-facing
  prompt path
- [x] Reclassify provider-facing `PromptMessage` inputs as advanced or
  provider-contract use
- [x] Centralize prompt normalization and validation in `llm_dart_ai`
- [x] Ensure provider codecs receive only normalized provider prompts
- [x] Update root README, getting-started examples, and linked core examples
  to use `messages:` / `ModelMessage`
- [x] Update remaining core examples that are common app code to avoid
  provider-facing prompt construction
  - 2026-05-13: migrated `assistants.dart`, `enhanced_tool_calling.dart`, and
    `message_builder_cache.dart`; remaining `prompt:` inventory in core
    examples is image-generation input or local helper parameter naming, not
    provider-facing `PromptMessage` construction

## Metadata And Options Boundary

- [x] Remove ordinary request-side `ProviderMetadata` from prompt parts
- [x] Remove ordinary request-side `ProviderMetadata` from tool output content
  parts
- [x] Keep output metadata on generated content, stream events, results, UI
  projection, and replay observations
- [x] Route replay metadata through `ProviderReplayPromptPartOptions` or
  provider-owned typed replay helpers
- [x] Add guards against request codecs reading metadata except through
  approved replay paths

## Provider Options

- [x] Evaluate whether `CallOptions.providerOptions` should become a typed
  provider options bag
- [x] Preserve typed provider invocation options for discoverability
- [x] Preserve provider-owned prompt part options
- [x] Document the raw provider option escape hatch policy
- [x] Add tests for missing and incompatible typed provider options
- [x] Add tests for shared/provider option merge behavior
- [x] Confirm no provider-owned raw request field is exposed yet; add
  provider-owned raw escape hatch tests with the first concrete raw request
  field

## Structured Output And Result Facades

- [x] Decide whether `generateTextCall` / `streamTextCall` become the long-term
  main result layer
- [x] Decide whether `generateObject` / `streamObject` stay aliases, wrappers,
  or migration helpers
- [x] Update documentation to show one primary structured-output path
- [x] Preserve partial-output and element-stream behavior for streaming object
  generation

## Validation

- [x] Run workspace dependency guards
- [x] Run root boundary guards
- [x] Run core compatibility shell guard
- [x] Run transport boundary guard
- [x] Run focused provider package tests
- [x] Run focused `llm_dart_ai` tests
- [x] Run chat and provider-focused tests for the metadata boundary slice
- [x] Run chat tests if runtime/chat contracts change; Flutter source was not
  changed in this slice
- [x] Run root compatibility tests that remain in scope
- [x] Run package analysis for affected packages
- [x] Run consumer smoke tests
- [x] Run publish dry-runs for affected packages
- [x] Run `git diff --check`

Latest targeted validation:

- 2026-05-13: `dart run tool/check_workspace_dependency_guards.dart`
- 2026-05-13: `dart run tool/check_core_compatibility_shell_guard.dart`
- 2026-05-13: `dart run tool/check_transport_boundary_guards.dart`
- 2026-05-13: `dart run tool/check_provider_replay_metadata_guards.dart`
- 2026-05-13: `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`
- 2026-05-13: `dart test packages/llm_dart_ai/test/prompt_normalization_test.dart packages/llm_dart_ai/test/prompt_validation_test.dart packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart`
- 2026-05-13: `dart test test/tool/check_provider_replay_metadata_guards_test.dart test/tool/check_root_package_boundary_guards_test.dart test/tool/check_example_api_guards_test.dart test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart analyze example/01_getting_started/quick_start.dart example/01_getting_started/basic_configuration.dart example/01_getting_started/provider_comparison.dart`
- 2026-05-13: `dart analyze example/02_core_features/streaming_chat.dart example/02_core_features/structured_output.dart example/02_core_features/tool_calling.dart`
- 2026-05-13: `dart run tool/check_example_api_guards.dart`
- 2026-05-13: `dart run tool/check_root_package_boundary_guards.dart`
- 2026-05-13: `dart test test/tool/check_root_package_boundary_guards_test.dart`
- 2026-05-13: `dart run tool/check_example_api_guards.dart`
- 2026-05-13: `dart test test/tool/check_example_api_guards_test.dart`
- 2026-05-13: `dart run tool/check_test_legacy_import_guards.dart --strict-root-legacy-subpaths`
- 2026-05-13: `dart test test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart analyze example/02_core_features/assistants.dart example/02_core_features/cancellation_demo.dart example/02_core_features/capability_detection.dart example/02_core_features/capability_factory_methods.dart example/02_core_features/model_listing.dart example/02_core_features/provider_specific_builders.dart example/03_advanced_features/realtime_audio.dart example/04_providers/elevenlabs/audio_capabilities.dart example/04_providers/google/google_tts_example.dart example/04_providers/openai/responses_api.dart example/04_providers/openai/build_openai_responses_demo.dart`
- 2026-05-13: `dart run tool/check_root_package_boundary_guards.dart`
- 2026-05-13: `dart test test/tool/check_root_package_boundary_guards_test.dart`
- 2026-05-13: `dart test test/tool/run_consumer_smoke_test.dart`
- 2026-05-13: `dart run tool/run_consumer_smoke.dart --direct-package-config`
- 2026-05-13: `dart run tool/check_test_legacy_import_guards.dart`
- 2026-05-13: `dart test test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart run tool/check_example_api_guards.dart`
- 2026-05-13: `dart test test/tool/check_example_api_guards_test.dart`
- 2026-05-13: `dart test test/test_minimal.dart`
- 2026-05-13: `dart test test/test_working.dart`
- 2026-05-13: `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`
- 2026-05-13: `dart test packages/llm_dart_ai/test/prompt_validation_test.dart packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart`
- 2026-05-13: `dart test packages/llm_dart_ai/test/capability_helpers_test.dart`
- 2026-05-13: `dart test packages/llm_dart_chat/test/tool_execution_registry_test.dart`
- 2026-05-13: `dart test packages/llm_dart_transport/test/transport_model_error_test.dart`
- 2026-05-13: `dart test packages/llm_dart_openai/test/openai_speech_model_test.dart packages/llm_dart_openai/test/openai_transcription_model_test.dart`
- 2026-05-13: `dart test packages/llm_dart_elevenlabs/test/elevenlabs_speech_model_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_transcription_model_test.dart`
- 2026-05-13: `dart test packages/llm_dart_google/test/google_image_model_test.dart packages/llm_dart_google/test/google_speech_model_test.dart`
- 2026-05-13: `dart test packages/llm_dart_transport/test/dio_http_client_factory_test.dart packages/llm_dart_transport/test/dio_cancellation_adapter_test.dart packages/llm_dart_transport/test/transport_retry_test.dart packages/llm_dart_transport/test/transport_model_error_test.dart`
- 2026-05-13: `dart test packages/llm_dart_transport/test/dio_http_client_factory_test.dart packages/llm_dart_transport/test/provider_dio_client_factory_test.dart packages/llm_dart_transport/test/dio_transport_client_test.dart packages/llm_dart_transport/test/dio_cancellation_adapter_test.dart packages/llm_dart_transport/test/transport_retry_test.dart packages/llm_dart_transport/test/transport_model_error_test.dart`
- 2026-05-13: `dart test packages/llm_dart_openai/test/openai_chat_completions_mainline_test.dart --name "provider options"`
- 2026-05-13: `dart test packages/llm_dart_google/test/google_language_model_test.dart --name "provider options"`
- 2026-05-13: `dart test test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart test test/test_all.dart --name "Utf8StreamDecoder"`
- 2026-05-13: `git diff --check`
- 2026-05-13: `dart test packages/llm_dart_openai/test/openai_entrypoint_test.dart packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_openai/test/openai_model_describer_test.dart packages/llm_dart_openai/test/openai_capability_profile_integration_test.dart`
- 2026-05-13: `dart test packages/llm_dart_openai/test/openai_chat_completions_mainline_test.dart --name "DeepSeek|xAI|provider options"`
- 2026-05-13: `dart test packages/llm_dart_elevenlabs/test/elevenlabs_entrypoint_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_capability_profile_integration_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_model_describer_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_speech_model_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_transcription_model_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_voice_catalog_test.dart`
- 2026-05-13: `dart test packages/llm_dart_anthropic/test/anthropic_entrypoint_test.dart packages/llm_dart_anthropic/test/anthropic_capability_profile_integration_test.dart packages/llm_dart_anthropic/test/anthropic_model_describer_test.dart packages/llm_dart_anthropic/test/anthropic_language_model_test.dart packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart packages/llm_dart_anthropic/test/anthropic_stream_codec_test.dart packages/llm_dart_anthropic/test/anthropic_result_codec_test.dart packages/llm_dart_anthropic/test/anthropic_files_test.dart packages/llm_dart_anthropic/test/anthropic_mcp_models_test.dart packages/llm_dart_anthropic/test/anthropic_code_execution_replay_test.dart`
- 2026-05-13: `dart test packages/llm_dart_google/test/google_entrypoint_test.dart packages/llm_dart_google/test/google_capability_profile_integration_test.dart packages/llm_dart_google/test/google_model_describer_test.dart packages/llm_dart_google/test/google_language_model_test.dart packages/llm_dart_google/test/google_generate_content_codec_test.dart packages/llm_dart_google/test/google_stream_codec_test.dart packages/llm_dart_google/test/google_result_codec_test.dart packages/llm_dart_google/test/google_function_response_replay_test.dart packages/llm_dart_google/test/google_server_tool_replay_test.dart packages/llm_dart_google/test/google_image_model_test.dart packages/llm_dart_google/test/google_image_editing_test.dart packages/llm_dart_google/test/google_speech_model_test.dart packages/llm_dart_google/test/google_embedding_model_test.dart packages/llm_dart_google/test/google_custom_part_test.dart packages/llm_dart_google/test/google_custom_part_summary_test.dart`
- 2026-05-13: `dart test packages/llm_dart_ollama/test/ollama_entrypoint_test.dart packages/llm_dart_ollama/test/ollama_capability_profile_integration_test.dart packages/llm_dart_ollama/test/ollama_model_describer_test.dart packages/llm_dart_ollama/test/ollama_language_model_test.dart packages/llm_dart_ollama/test/ollama_embedding_model_test.dart packages/llm_dart_ollama/test/ollama_model_catalog_test.dart`
- 2026-05-13: `dart test test/test_all.dart --name "Tool Tests"`
- 2026-05-13: `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`
- 2026-05-13: `dart test packages/llm_dart_anthropic/test/anthropic_code_execution_replay_test.dart packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart`
- 2026-05-13: `dart test packages/llm_dart_google/test/google_generate_content_codec_test.dart`
- 2026-05-13: `dart test packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_chat_completions_mainline_test.dart`
- 2026-05-13: `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`
- 2026-05-13: `dart analyze packages/llm_dart_provider packages/llm_dart_chat packages/llm_dart_google packages/llm_dart_openai packages/llm_dart_anthropic test tool`
- 2026-05-13: `dart analyze example/02_core_features/assistants.dart example/02_core_features/enhanced_tool_calling.dart example/02_core_features/message_builder_cache.dart`
- 2026-05-13: `dart run tool/check_example_api_guards.dart`
- 2026-05-13: `dart run tool/check_workspace_dependency_guards.dart`
- 2026-05-13: `dart run tool/check_root_package_boundary_guards.dart`
- 2026-05-13: `dart run tool/check_provider_replay_metadata_guards.dart`
- 2026-05-13: `dart analyze example/02_core_features`
- 2026-05-13: `dart run tool/check_core_compatibility_shell_guard.dart`
- 2026-05-13: `dart run tool/check_transport_boundary_guards.dart`
- 2026-05-13: `dart test test/tool/check_provider_replay_metadata_guards_test.dart test/tool/check_root_package_boundary_guards_test.dart test/tool/check_example_api_guards_test.dart test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`
- 2026-05-13: `dart test packages/llm_dart_ai/test/prompt_normalization_test.dart packages/llm_dart_ai/test/prompt_validation_test.dart packages/llm_dart_ai/test/text_call_test.dart packages/llm_dart_ai/test/output_spec_test.dart`
- 2026-05-13: `dart test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart`
- 2026-05-13: `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`
- 2026-05-13: `dart test packages/llm_dart_anthropic/test/anthropic_code_execution_replay_test.dart packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart packages/llm_dart_google/test/google_generate_content_codec_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_chat_completions_mainline_test.dart`
- 2026-05-13: `dart test test/tool/run_consumer_smoke_test.dart`
- 2026-05-13: `dart run tool/run_consumer_smoke.dart --direct-package-config`
- 2026-05-13: `dart analyze packages/llm_dart_provider packages/llm_dart_chat packages/llm_dart_google packages/llm_dart_openai packages/llm_dart_anthropic packages/llm_dart_ai test tool example/01_getting_started example/02_core_features`
- 2026-05-13: `dart run tool/check_test_legacy_import_guards.dart --strict-root-legacy-subpaths`
- 2026-05-13: `dart run tool/check_test_legacy_import_guards.dart`
- 2026-05-13: `dart test test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart analyze tool/check_test_legacy_import_guards.dart test/tool/check_test_legacy_import_guards_test.dart`
- 2026-05-13: `dart test test/test_working.dart`
- 2026-05-13: `dart test test/prompt_normalization_test.dart test/provider_prompt_normalization_integration_test.dart test/llm_dart_test.dart`
- 2026-05-13: `dart test test/test_all.dart --name "Tool Tests"`
- 2026-05-13: `dart run tool/run_workspace_publish_dry_run.dart`
- 2026-05-13: `git diff --check`

Latest migration inventory:

- 2026-05-13: `dart run tool/check_test_legacy_import_guards.dart --strict-root-legacy-subpaths`
  now passes for guarded test scopes. The previous inventory count of 81 root
  legacy subpath import violations has been burned down by deleting or
  migrating the legacy test files.
