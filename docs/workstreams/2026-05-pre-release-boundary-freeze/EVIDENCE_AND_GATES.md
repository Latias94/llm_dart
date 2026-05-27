# Pre-Release Boundary Freeze — Evidence And Gates

Status: Complete
Last updated: 2026-05-27

## Gate Set

### Targeted Iteration Gate

Run the validation command from the active task in `TODO.md`.

### Release Boundary Gates

```powershell
dart --suppress-analytics run tool/check_release_ledger.dart
dart --suppress-analytics run tool/check_app_facade_exports.dart
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
```

### Closeout Gate

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
dart --suppress-analytics run tool/check_release_ledger.dart
dart --suppress-analytics run tool/check_app_facade_exports.dart
git diff --check
```

## Evidence Log

### 2026-05-27 — PRF-010 Scope and evidence freeze

Evidence:

- `docs/workstreams/2026-05-pre-release-boundary-freeze/DESIGN.md`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/TODO.md`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/MILESTONES.md`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/EVIDENCE_AND_GATES.md`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/WORKSTREAM.json`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/HANDOFF.md`

Result: completed.

Validation:

```powershell
git status --short
```

The worktree was clean before opening the lane.

### 2026-05-27 — PRF-020 Release ledger

Evidence:

- `docs/release/README.md`
- `docs/release/release_ledger.json`
- `tool/check_release_ledger.dart`
- `docs/workstreams/README.md`

Result: completed.

Design decision:

- The release ledger is JSON-backed so guard tooling can validate it without a
  Markdown parser.
- It records publish posture, publishable package order, non-publishable test
  support packages, release-facing workstreams, required local gates, and known
  non-blocking deferrals.
- The guard checks package pubspec names, generated-from paths, workstream
  slug/status alignment, gate tool existence, and deferral fields.

Validation:

```powershell
dart --suppress-analytics run tool/check_release_ledger.dart
```

The command passed on 2026-05-27.

### 2026-05-27 — PRF-060 OpenAI Responses projection family index

Evidence:

- `packages/llm_dart_openai/lib/src/responses/openai_responses_projection_family_index.dart`
- `packages/llm_dart_openai/test/openai_responses_projection_family_index_test.dart`
- `docs/release/release_ledger.json`

Result: completed.

Design decision:

- Added a package-private ownership index for OpenAI Responses projection
  families.
- The index maps family ids to owned implementation modules and tests.
- It is deliberately not a runtime registry. Concrete provider-owned Modules
  still own dispatch, parsing, replay, and provider-native behavior.

Validation:

```powershell
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics test packages/llm_dart_openai/test/openai_responses_projection_family_index_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart
```

Both commands passed on 2026-05-27.

### 2026-05-27 — PRF-070 Closeout

Evidence:

- `docs/workstreams/2026-05-pre-release-boundary-freeze/TODO.md`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/MILESTONES.md`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/WORKSTREAM.json`
- `docs/workstreams/2026-05-pre-release-boundary-freeze/HANDOFF.md`
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

All commands passed on 2026-05-27. `git diff --check` emitted only line-ending
conversion warnings and returned exit code 0.

### 2026-05-27 — PRF-030 Provider fixture coverage

Evidence:

- `packages/llm_dart_elevenlabs/test/elevenlabs_fixture_contract_test.dart`
- `packages/llm_dart_elevenlabs/test/fixtures/elevenlabs/speech_request_contract_golden.json`
- `packages/llm_dart_elevenlabs/test/fixtures/elevenlabs/transcription_request_contract_golden.json`
- `docs/release/release_ledger.json`

Result: completed.

Design decision:

- ElevenLabs speech and transcription were the missing release-facing non-text
  provider surfaces without provider-local golden coverage.
- Speech locks the stable JSON transport request contract.
- Transcription locks a stable multipart semantic-field summary instead of the
  random multipart boundary bytes.
- The existing `ProviderCodecContractRunner` remains test-only; no public
  provider utility package was introduced.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_elevenlabs/test/elevenlabs_fixture_contract_test.dart packages/llm_dart_test/test/fake_support_test.dart
dart --suppress-analytics test packages/llm_dart_elevenlabs/test packages/llm_dart_test/test/fake_support_test.dart
```

Both commands passed on 2026-05-27.

### 2026-05-27 — PRF-050 HTTP chat transport protocol freeze

Evidence:

- `packages/llm_dart_chat/lib/src/http_chat_transport_protocol_policy.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_protocol.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_request_payload.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_request_json_codec.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_server_adapter.dart`
- `packages/llm_dart_chat/test/http_chat_transport_protocol_test.dart`
- `docs/release/http_chat_transport_protocol_policy.md`
- `docs/release/release_ledger.json`

Result: completed.

Design decision:

- Added a narrow `HttpChatTransportProtocolPolicy` Module for release-frozen
  version posture only.
- New send and reconnect payloads default to `uiMessageStreamV2`.
- Legacy request and reconnect payloads that omit `streamProtocol` decode as
  `eventStreamV1`.
- Projection, SSE framing, replay mutation, and stream error recovery remain
  in the existing deeper transport Modules.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_chat/test/http_chat_transport_protocol_test.dart packages/llm_dart_chat/test/http_chat_transport_server_adapter_test.dart packages/llm_dart_chat/test/http_chat_transport_stream_session_test.dart
```

The command passed on 2026-05-27.

### 2026-05-27 — PRF-040 App facade export contract freeze

Evidence:

- `docs/release/app_facade_exports.json`
- `tool/check_app_facade_exports.dart`
- `docs/release/release_ledger.json`

Result: completed.

Design decision:

- The alpha freeze does not remove app/root facade symbols. It classifies and
  freezes the current export contract so accidental drift is caught.
- Root entrypoint directives are validated from the manifest.
- `llm_dart_ai/app.dart` provider-foundation re-exports are grouped by release
  role, including invocation controls, capability discovery, model contracts,
  content/files, tool contracts, diagnostics, and provider options/metadata.

Validation:

```powershell
dart --suppress-analytics run tool/check_app_facade_exports.dart
dart --suppress-analytics run tool/check_release_ledger.dart
```

Both commands passed on 2026-05-27.
