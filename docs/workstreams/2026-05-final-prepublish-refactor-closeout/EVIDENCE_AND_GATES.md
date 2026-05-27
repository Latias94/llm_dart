# Final Prepublish Refactor Closeout — Evidence And Gates

Status: Complete
Last updated: 2026-05-27

## Gate Set

### Targeted Gates

Run the validation command from the active task in `TODO.md`.

### Release Gates

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
dart --suppress-analytics run tool/check_release_ledger.dart
dart --suppress-analytics run tool/check_app_facade_exports.dart
git diff --check
```

All commands passed on 2026-05-27. `git diff --check` emitted only Git
line-ending conversion warnings and returned exit code 0.

## Evidence Log

### 2026-05-27 — FPC-010 Open lane

Evidence:

- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/DESIGN.md`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/TODO.md`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/MILESTONES.md`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/EVIDENCE_AND_GATES.md`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/WORKSTREAM.json`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/HANDOFF.md`

Result: completed.

### 2026-05-27 — FPC-020 Context and ADR index

Evidence:

- `CONTEXT.md`
- `docs/adr/README.md`
- `docs/adr/0001-root-app-runtime-provider-seams.md`
- `docs/adr/0002-provider-native-features-stay-provider-owned.md`
- `docs/adr/0003-release-state-is-ledger-guarded.md`
- `docs/adr/0004-registries-require-repeated-adapters.md`
- `docs/release/release_ledger.json`

Result: completed.

Validation:

```powershell
dart --suppress-analytics run tool/check_release_ledger.dart
```

The command passed on 2026-05-27 after adding the final prepublish closeout
workstream to the release ledger.

### 2026-05-27 — FPC-030 Runtime event/tool-loop closeout

Evidence:

- `docs/workstreams/2026-05-runtime-event-tool-loop-boundary/40-release-closeout-reconciliation.md`
- `docs/workstreams/2026-05-runtime-event-tool-loop-boundary/README.md`
- `docs/workstreams/README.md`
- `docs/release/release_ledger.json`

Result: completed.

Validation:

```powershell
dart --suppress-analytics run tool/check_release_ledger.dart
```

The command passed on 2026-05-27.

### 2026-05-27 — FPC-040 Provider test-only implementation kit

Evidence:

- `packages/llm_dart_test/lib/src/provider_transport_contract_projector.dart`
- `packages/llm_dart_test/lib/llm_dart_test.dart`
- `packages/llm_dart_test/test/fake_support_test.dart`
- `packages/llm_dart_elevenlabs/test/elevenlabs_fixture_contract_test.dart`

Result: completed.

Design decision:

- The projector lives in non-publishable `llm_dart_test`.
- Provider packages still own request construction and provider-native behavior.
- The helper only turns transport requests into deterministic fixture JSON,
  including semantic multipart fields that hide random boundaries.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_elevenlabs/test/elevenlabs_fixture_contract_test.dart packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart packages/llm_dart_test/test/fake_support_test.dart
```

The command passed on 2026-05-27.

### 2026-05-27 — FPC-050 Scenario-family test split

Evidence:

- `packages/llm_dart_chat/test/direct_chat_transport_test.dart`
- `packages/llm_dart_chat/test/default_chat_session_test.dart`

Result: completed.

Design decision:

- Split the DirectChatTransport scenario family from the giant default chat
  session bucket.
- Kept production code unchanged.
- Kept OpenAI Responses tests in place for this release because their
  projection family index already documents ownership and the targeted tests
  remain green.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_chat/test/direct_chat_transport_test.dart packages/llm_dart_chat/test/default_chat_session_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart
```

The command passed on 2026-05-27 with 94 tests.

### 2026-05-27 — FPC-060 Closeout

Evidence:

- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/TODO.md`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/MILESTONES.md`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/WORKSTREAM.json`
- `docs/workstreams/2026-05-final-prepublish-refactor-closeout/HANDOFF.md`
- `docs/release/release_ledger.json`

Result: completed.

Validation:

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
dart --suppress-analytics run tool/check_release_ledger.dart
dart --suppress-analytics run tool/check_app_facade_exports.dart
git diff --check
```
