# Completion Audit

Date: 2026-05-12

This audit checks the active objective against the current workspace state. It
does not treat implementation effort, passing proxy tests, or prior notes as
completion by themselves.

## Objective Restated As Deliverables

The workstream must deliver these concrete outcomes:

1. Provider model contracts use implementation-facing `do*` methods.
2. User-facing non-text helpers remain in `llm_dart_ai`.
3. Prompt input provider customization moves from `ProviderMetadata` to typed
   provider options or typed prompt part options.
4. `ProviderMetadata` is reserved for output observations, replay details, and
   UI inspection data.
5. Root legacy compatibility no longer shapes new contracts and is frozen by
   policy and guards.
6. The change is proven by guards, migration docs, examples, package tests,
   root tests, and consumer smoke.

## Prompt-To-Artifact Checklist

| Requirement | Evidence | Status |
| --- | --- | --- |
| `EmbeddingModel` provider contract uses `doEmbed` | `packages/llm_dart_provider/lib/src/model/embedding_model.dart`; OpenAI, Google, Ollama implementations; workspace guard rejects `Future<EmbedResult> embed(` in package `lib/` | Done |
| `ImageModel`, `SpeechModel`, and `TranscriptionModel` provider contracts use `doGenerate` | `packages/llm_dart_provider/lib/src/model/image_model.dart`, `speech_model.dart`, `transcription_model.dart`; OpenAI, Google, ElevenLabs implementations; compatibility bridges call `doGenerate` | Done |
| User-facing helper names remain in `llm_dart_ai` | `packages/llm_dart_ai/lib/src/model/embed.dart`, `generate_image.dart`, `generate_speech.dart`, `transcribe.dart` call provider `do*` methods | Done |
| Runtime helper tests call user helpers instead of provider methods | `packages/llm_dart_ai/test/capability_helpers_test.dart`; `packages/llm_dart_core/test/capability_helpers_test.dart` | Done |
| Guards reject old provider contract names | `tool/check_workspace_dependency_guards.dart`; `test/tool/check_workspace_dependency_guards_test.dart` | Done |
| Prompt parts carry input-side provider options | `packages/llm_dart_provider/lib/src/common/provider_options.dart`; `packages/llm_dart_provider/lib/src/prompt/prompt_message.dart`; `packages/llm_dart_provider/lib/src/tool/tool_output.dart` | Done |
| Prompt JSON preserves typed part options and fails fast without registered codecs | `packages/llm_dart_provider/lib/src/serialization/prompt_json_codec.dart`; `packages/llm_dart_core/test/message_json_codec_test.dart` | Done |
| Anthropic cache control moved off `ProviderMetadata` | `packages/llm_dart_anthropic/lib/src/anthropic_options.dart`; `packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart`; `packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart` includes `does not use ProviderMetadata as Anthropic request configuration` | Done |
| OpenAI image `detail` moved off `ProviderMetadata` | `packages/llm_dart_openai/lib/src/openai_options.dart`; `openai_chat_completions_codec.dart`; `openai_responses_codec.dart`; OpenAI tests cover image detail through prompt part options | Done |
| Google metadata reads remain replay-oriented | `packages/llm_dart_google/lib/src/google_generate_content_codec.dart`; Google tests cover thought signatures, function response replay, and server-tool replay | Done |
| Output metadata remains available for results, stream events, replay, and UI | Provider/core/chat tests cover `ProviderMetadata`, stream codecs, UI accumulators, and chat snapshots | Done |
| Legacy cache markers are translated at compatibility boundary | `lib/src/compatibility/providers/anthropic_compat_support.dart`; `test/legacy_compatibility_test.dart` | Done |
| Default examples avoid teaching legacy APIs | `tool/check_example_api_guards.dart`; `example/02_core_features/message_builder_cache.dart` uses typed Anthropic prompt part options | Done |
| Root legacy is frozen instead of shaping new contracts | `tool/check_root_package_boundary_guards.dart`; `tool/check_test_legacy_import_guards.dart`; `docs/workstreams/2026-05-provider-contract-and-prompt-boundary-refactor/04-legacy-exit-plan.md` | Done |
| Migration docs exist under the workstream | `GOAL.md`, `01-reference-gap-audit.md`, `02-target-contracts.md`, `03-prompt-boundary-plan.md`, `04-legacy-exit-plan.md`, `MILESTONES.md`, `TODO.md` | Done |
| Direct package-config consumer smoke proves import/runtime boundaries | `tool/run_consumer_smoke.dart --direct-package-config`; 7 Dart consumer cases passed with `--packages=.dart_tool/package_config.json` | Done |
| Clean consumer smoke proves dependency resolution and Flutter coverage | `dart tool/run_consumer_smoke.dart`; 24 clean Dart/provider/split/Flutter consumer steps passed | Done |
| Publish dry-run proves package metadata | `dart tool/run_workspace_publish_dry_run.dart`; 12 packages passed with 0 warnings and only expected workspace override hints | Done |
| Package analysis proves analyzer cleanliness | `dart analyze lib test example tool`; no issues found | Done |
| Flutter tests prove Flutter adapter coverage | `dart tool/run_workspace_package_tests.dart`; `llm_dart_flutter` `flutter test` passed as part of the 11-package suite | Done |

## Verification Run

Commands run with:

```powershell
F:\SDKs\dart-sdk-3.11.6\bin\dart.exe
```

Passed:

- `dart tool/release_readiness.dart`
- `dart tool/run_workspace_package_tests.dart`
- `dart tool/run_consumer_smoke.dart`
- `dart tool/run_workspace_publish_dry_run.dart`
- `dart analyze lib test example tool`
- `dart test test/tool/run_consumer_smoke_test.dart test/tool/run_workspace_package_tests_test.dart test/tool/run_workspace_publish_dry_run_test.dart test/tool/release_readiness_test.dart`
- `git diff --check`

The full release readiness gate passed in 4m 22s. It included all guards,
workspace analysis, root tests, focused workspace package tests, clean consumer
smoke, workspace publish dry-run, and pub.dev version availability checks.

`git diff --check` only reported line-ending warnings for working-copy LF/CRLF
normalization; it reported no whitespace errors.

## Tooling Startup Resolution

The earlier blocked verification was caused by unstable tool child-process
routing: repository tools launched bare `dart` commands, while this Windows
environment's `PATH` resolves `dart` to `F:\SDKs\flutter_old\bin\dart.bat`.
The tools now resolve Dart child processes through `Platform.resolvedExecutable`
and keep Flutter commands on `flutter.bat` on Windows.

The temporary `llm_dart_ai` package-test failure after freeing disk space was a
corrupted generated test cache from the previous disk-full run. Removing only
`packages/llm_dart_ai/.dart_tool/test` and
`packages/llm_dart_ai/.dart_tool/pub/bin/test` forced the test runner to
rebuild the cache; package-level tests then passed.

## Audit Result

Implementation, documentation, release-readiness tooling, package analysis,
workspace package tests, clean consumer smoke, publish dry-run, and pub.dev
version availability checks are complete against the inspected source state.
