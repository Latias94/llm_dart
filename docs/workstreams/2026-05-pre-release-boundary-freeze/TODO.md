# Pre-Release Boundary Freeze — TODO

Status: Complete
Last updated: 2026-05-27

## M0 — Scope And Evidence Freeze

- [x] PRF-010 [owner=planner] [deps=none] [scope=docs/workstreams/2026-05-pre-release-boundary-freeze]
  Goal: Open the durable lane, freeze the five requested deliverables, and
  define evidence gates.
  Validation: Workstream docs exist and agree.
  Review: Keep this lane release-freezing oriented; do not reopen broad
  provider/runtime rewrites.
  Evidence: workstream docs.
  Handoff: Start with release ledger because it gives the remaining tasks one
  publish-facing home.

## M1 — Release Ledger

- [x] PRF-020 [owner=codex] [deps=PRF-010] [scope=docs/release,tool,docs/workstreams]
  Goal: Add a release ledger and a status guard so publish readiness does not
  depend on reading many workstream files manually.
  Validation: `dart --suppress-analytics run tool/check_release_ledger.dart`
  Review: The guard should catch stale workstream status without requiring
  network access or pub credentials.
  Evidence: Added `docs/release/release_ledger.json`,
  `docs/release/README.md`, and `tool/check_release_ledger.dart`. The guard
  validates package pubspec names, workstream status, gate tool existence, and
  known deferral fields.
  Handoff: Provider fixture coverage should add its evidence to the ledger if
  it becomes a release gate.

## M2 — Provider Fixture Coverage

- [x] PRF-030 [owner=codex] [deps=PRF-010] [scope=packages/llm_dart_test,packages/llm_dart_elevenlabs/test,packages/*/test/fixtures]
  Goal: Extend provider fixture coverage to release-committed non-text/provider
  surfaces where the contract is stable enough to golden-test.
  Validation: `dart --suppress-analytics test packages/llm_dart_elevenlabs/test packages/llm_dart_test/test/fake_support_test.dart`
  Review: Add goldens only for stable request/metadata contracts; do not turn
  live provider behavior or unstable provider-native payloads into fixtures.
  Evidence: Added ElevenLabs speech request transport and transcription
  multipart semantic-field golden fixtures plus
  `elevenlabs_fixture_contract_test.dart`.
  Handoff: Broader fixture expansion is a follow-on; the missing release-facing
  non-text surface now has a stable provider-local golden contract.

## M3 — App Facade Export Contract Freeze

- [x] PRF-040 [owner=codex] [deps=PRF-020] [scope=docs/release,tool,lib,packages/llm_dart_ai/lib]
  Goal: Freeze the root/app export contract as an explicit manifest and guard
  before alpha without removing symbols late in the release cycle.
  Validation: `dart --suppress-analytics run tool/check_app_facade_exports.dart`
  Review: Classify symbols instead of deleting them; removals need a later
  breaking line with migration notes.
  Evidence: Added `docs/release/app_facade_exports.json` and
  `tool/check_app_facade_exports.dart`; the release ledger now requires the
  guard.
  Handoff: HTTP transport policy can reference the same release ledger.

## M4 — HTTP Chat Transport Protocol Freeze

- [x] PRF-050 [owner=codex] [deps=PRF-020] [scope=packages/llm_dart_chat/lib/src,packages/llm_dart_chat/test,docs/release]
  Goal: Freeze HTTP chat transport v1/v2 protocol policy as a release-facing
  contract with tests for compatibility and reconnect guarantees.
  Validation: `dart --suppress-analytics test packages/llm_dart_chat/test/http_chat_transport_protocol_test.dart packages/llm_dart_chat/test/http_chat_transport_server_adapter_test.dart packages/llm_dart_chat/test/http_chat_transport_stream_session_test.dart`
  Review: Prefer policy documentation and focused guards over reshaping the
  already-deep transport session.
  Evidence: Added `HttpChatTransportProtocolPolicy`,
  `docs/release/http_chat_transport_protocol_policy.md`, and protocol tests.
  Handoff: OpenAI Responses projection index remains provider-internal.

## M5 — OpenAI Responses Projection Family Index

- [x] PRF-060 [owner=codex] [deps=PRF-010] [scope=packages/llm_dart_openai/lib/src/responses,packages/llm_dart_openai/test]
  Goal: Add a package-private ownership index for OpenAI Responses native
  projection families without introducing a runtime registry.
  Validation: `dart --suppress-analytics analyze packages/llm_dart_openai && dart --suppress-analytics test packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart`
  Review: The index is navigation and ownership documentation; it must not hide
  provider-native dispatch behind a generic shared abstraction.
  Evidence: Added `openai_responses_projection_family_index.dart` and
  `openai_responses_projection_family_index_test.dart`; release ledger now
  tracks this gate.
  Handoff: Closeout should decide whether any item is a required release
  blocker or follow-on.

## M6 — Closeout

- [x] PRF-070 [owner=planner] [deps=PRF-020,PRF-030,PRF-040,PRF-050,PRF-060] [scope=docs/workstreams/2026-05-pre-release-boundary-freeze,docs/release,tool]
  Goal: Run final gates, update evidence, and commit the lane.
  Validation: `dart --suppress-analytics analyze . && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && dart --suppress-analytics run tool/check_example_api_guards.dart && dart --suppress-analytics run tool/check_release_ledger.dart && dart --suppress-analytics run tool/check_app_facade_exports.dart && git diff --check`
  Review: No broad rewrites, no registry overreach, no release-state drift.
  Evidence: Final gates passed on 2026-05-27 and are recorded in
  EVIDENCE_AND_GATES.md. WORKSTREAM.json, HANDOFF.md, MILESTONES.md, and the
  release ledger now agree that this lane is complete.
  Handoff: No release-blocking architecture refactor remains in this lane;
  actual `pub publish` remains maintainer-approved.
