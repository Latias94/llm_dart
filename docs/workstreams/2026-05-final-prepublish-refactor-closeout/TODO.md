# Final Prepublish Refactor Closeout — TODO

Status: Complete
Last updated: 2026-05-27

## M0 — Open Lane

- [x] FPC-010 [owner=planner] [deps=none] [scope=docs/workstreams/2026-05-final-prepublish-refactor-closeout,docs/workstreams/README.md]
  Goal: Open a durable lane for the four final prepublish refactors.
  Validation: Workstream docs exist and agree.
  Review: Keep this as a release closeout lane, not a broad architecture reset.
  Evidence: Workstream docs.
  Handoff: Start with context and ADR index because later tasks need stable
  vocabulary.

## M1 — Context And ADR Index

- [x] FPC-020 [owner=codex] [deps=FPC-010] [scope=CONTEXT.md,docs/adr,docs/workstreams]
  Goal: Add project context and an ADR index for frozen seams so future
  refactors do not reopen rejected architecture directions.
  Validation: `dart --suppress-analytics run tool/check_release_ledger.dart`
  Review: ADRs should record decisions already proven by code/workstreams, not
  invent new design.
  Evidence: Added CONTEXT.md, docs/adr/README.md, and ADR-0001 through
  ADR-0004 for root/app/provider seams, provider-native ownership, release
  ledger posture, and registry criteria.
  Handoff: Runtime closeout should reference the new vocabulary.

## M2 — Runtime Event / Tool Loop Closeout

- [x] FPC-030 [owner=codex] [deps=FPC-020] [scope=docs/workstreams/2026-05-runtime-event-tool-loop-boundary,docs/workstreams/README.md,docs/release]
  Goal: Reconcile runtime event/tool-loop workstream state with the release
  ledger and freeze remaining follow-ons.
  Validation: `dart --suppress-analytics run tool/check_release_ledger.dart`
  Review: Do not redesign runtime events; close or split documented follow-ons.
  Evidence: Added runtime release closeout reconciliation, updated the
  top-level workstream index from active to closed, and recorded runtime
  context/agent follow-ons as non-blocking release ledger deferrals.
  Handoff: Provider test-only kit remains implementation/test support.

## M3 — Provider Test-Only Implementation Kit

- [x] FPC-040 [owner=codex] [deps=FPC-020] [scope=packages/llm_dart_test,packages/*/test]
  Goal: Extract repeated provider fixture assertions into test-only support
  without publishing a provider implementation kit.
  Validation: `dart --suppress-analytics test packages/llm_dart_elevenlabs/test/elevenlabs_fixture_contract_test.dart packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart packages/llm_dart_test/test/fake_support_test.dart`
  Review: The helper must not hide provider-native behavior behind a generic
  runtime registry.
  Evidence: Added `ProviderTransportContractProjector` to `llm_dart_test`,
  exported it from the test support barrel, moved ElevenLabs transport request
  and multipart projection out of provider-local test code, and covered the
  projector in `fake_support_test.dart`.
  Handoff: Scenario-family test split can reuse the helper only when it improves
  locality.

## M4 — Scenario-Family Test Split

- [x] FPC-050 [owner=codex] [deps=FPC-040] [scope=packages/llm_dart_chat/test,packages/llm_dart_openai/test]
  Goal: Split the highest-risk giant tests by scenario family without changing
  production behavior.
  Validation: `dart --suppress-analytics test packages/llm_dart_chat/test/direct_chat_transport_test.dart packages/llm_dart_chat/test/default_chat_session_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart`
  Review: Prefer moving coherent groups over broad rewrites.
  Evidence: Split `DirectChatTransport` tests out of
  `default_chat_session_test.dart` into `direct_chat_transport_test.dart`;
  targeted chat/OpenAI scenario tests passed.
  Handoff: Closeout runs release gates.

## M5 — Closeout

- [x] FPC-060 [owner=planner] [deps=FPC-020,FPC-030,FPC-040,FPC-050] [scope=docs/workstreams/2026-05-final-prepublish-refactor-closeout,docs/release,tool]
  Goal: Run final release gates, close the lane, and commit.
  Validation: `dart --suppress-analytics analyze . && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && dart --suppress-analytics run tool/check_example_api_guards.dart && dart --suppress-analytics run tool/check_release_ledger.dart && dart --suppress-analytics run tool/check_app_facade_exports.dart && git diff --check`
  Review: No public-surface expansion and no release-state drift.
  Evidence: Final release gates passed on 2026-05-27 and are recorded in
  EVIDENCE_AND_GATES.md. WORKSTREAM.json, HANDOFF.md, and the release ledger
  agree that the lane is complete and release-ready.
  Handoff: Maintainer can proceed to publish dry-run/publish.
