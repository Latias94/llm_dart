# Evidence And Gates

Status: Closed
Last updated: 2026-05-23

## Initial Gates

```powershell
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test/provider_contracts_test.dart
dart test packages/llm_dart_provider/test/prompt_part_provider_options_json_codec_test.dart
git diff --check
```

## Full Gates

```powershell
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_provider_replay_metadata_guards.dart
dart run tool/check_provider_metadata_namespace_guards.dart
git diff --check
```

## Evidence Anchors

- `packages/llm_dart_provider/lib/src/common/provider_options.dart`
- `packages/llm_dart_provider/lib/foundation.dart`
- `packages/llm_dart_provider/test/provider_contracts_test.dart`
- `packages/llm_dart_provider/test/prompt_part_provider_options_json_codec_test.dart`
- `tool/check_provider_replay_metadata_guards.dart`
- `tool/check_provider_metadata_namespace_guards.dart`

## Evidence Log

### 2026-05-23 - POS-010 Provider option symbol ownership audit

Evidence:

- `docs/workstreams/2026-05-provider-options-seam-deepening/01-provider-option-symbol-audit.md`

Result: completed.

Notes:

- The audit classified the existing `provider_options.dart` public symbols into
  bag transport, typed invocation, prompt-part replay, tool options, and
  internal JSON support before implementation split work started.

### 2026-05-23 - POS-020..POS-040 Facade-preserving provider options split

Changed files:

- `packages/llm_dart_provider/lib/src/common/provider_options.dart`
- `packages/llm_dart_provider/lib/src/common/provider_options_bag.dart`
- `packages/llm_dart_provider/lib/src/common/provider_invocation_options.dart`
- `packages/llm_dart_provider/lib/src/common/provider_prompt_part_options.dart`
- `packages/llm_dart_provider/lib/src/common/provider_replay_prompt_part_options.dart`
- `packages/llm_dart_provider/lib/src/common/provider_tool_options.dart`
- `tool/check_provider_replay_metadata_guards.dart`
- `test/tool/check_provider_replay_metadata_guards_test.dart`

Commands:

```powershell
dart format packages\llm_dart_provider\lib\src\common\provider_options.dart packages\llm_dart_provider\lib\src\common\provider_options_bag.dart packages\llm_dart_provider\lib\src\common\provider_invocation_options.dart packages\llm_dart_provider\lib\src\common\provider_prompt_part_options.dart packages\llm_dart_provider\lib\src\common\provider_replay_prompt_part_options.dart packages\llm_dart_provider\lib\src\common\provider_tool_options.dart
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test/provider_contracts_test.dart
dart test packages/llm_dart_provider/test/prompt_part_provider_options_json_codec_test.dart
dart analyze tool/check_provider_replay_metadata_guards.dart test/tool/check_provider_replay_metadata_guards_test.dart
dart test test/tool/check_provider_replay_metadata_guards_test.dart
dart run tool/check_provider_replay_metadata_guards.dart
```

Result: passed.

Notes:

- `provider_options.dart` is now a stable library facade with `part` files for
  bag transport, typed invocation, prompt-part options, replay prompt-part
  options, and tool options.
- `foundation.dart` still exports the same provider option entrypoint.
- `ProviderOptionsBag` construction, validation, deep merge, equality, hashing,
  and `toJsonMap` behavior stayed covered by unchanged provider contract tests.
- The replay metadata guard now scans the provider options library facade and
  its `part` files, so the guard remains meaningful after the split.

### 2026-05-23 - POS-050 Full verification and closeout

Commands:

```powershell
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_provider_replay_metadata_guards.dart
dart run tool/check_provider_metadata_namespace_guards.dart
dart test test/tool/check_provider_replay_metadata_guards_test.dart
git diff --check
```

Result: passed.

Notes:

- Provider package analysis reported no issues.
- Provider package tests passed.
- Workspace dependency, provider replay metadata, and provider metadata
  namespace guards passed.
- `git diff --check` exited successfully and only printed the existing
  LF/CRLF working-copy warnings for edited files.

## Closeout

Status: closed on 2026-05-23. The workstream target state is met: the public
provider options seam remains stable while the implementation no longer mixes
bag transport, typed invocation, prompt-part, tool, replay, resolver, and JSON
helper ownership in one file.
