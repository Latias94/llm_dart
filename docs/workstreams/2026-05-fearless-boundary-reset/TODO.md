# Fearless Boundary Reset — TODO

Status: Closed
Last updated: 2026-05-21

## M0 — Scope And Evidence Freeze

- [x] FBR-010 [owner=planner] [deps=none] [scope=docs/workstreams/2026-05-fearless-boundary-reset]
  Goal: Create the durable workstream, freeze target seams, and choose the
  first vertical proof.
  Validation: DESIGN.md, TODO.md, MILESTONES.md, EVIDENCE_AND_GATES.md,
  WORKSTREAM.json, and HANDOFF.md exist and agree.
  Evidence: `docs/workstreams/2026-05-fearless-boundary-reset/DESIGN.md`
  Handoff: Planner owns this before code tasks start.

## M1 — OpenAI Route Adapter Proof

- [x] FBR-020 [owner=codex] [deps=FBR-010] [scope=packages/llm_dart_openai/lib/src/language,packages/llm_dart_openai/lib/src/responses,packages/llm_dart_openai/lib/src/chat_completions,packages/llm_dart_openai/test]
  Goal: Split the current heavy OpenAI language model module into
  route-specific deep adapters while preserving provider-owned OpenAI features.
  Validation: `dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_lifecycle_client_test.dart`
  Review: Run review-workstream before accepting completion.
  Evidence: `packages/llm_dart_openai/lib/src/language/openai_language_model_route_adapter.dart`;
  `packages/llm_dart_openai/lib/src/responses/openai_responses_language_model_route_adapter.dart`;
  `packages/llm_dart_openai/lib/src/chat_completions/openai_chat_completions_language_model_route_adapter.dart`;
  fresh FBR-020 targeted test, package test, analyze, guards, and `git diff --check`
  evidence recorded in `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — route-specific adapters now own request encoding, generate
  response decoding, stream decoding, and route URI selection; provider
  transport execution remains ready for FBR-040.

- [x] FBR-030 [owner=codex] [deps=FBR-020] [scope=packages/llm_dart_openai/lib/src/provider,packages/llm_dart_openai/lib/src/language,packages/llm_dart_openai/test]
  Goal: Move OpenAI-compatible provider family routing and option rejection
  policy behind profile-owned route adapter seams instead of one central
  conditional chain.
  Validation: `dart --suppress-analytics test packages/llm_dart_openai/test/openai_model_describer_test.dart packages/llm_dart_openai/test/openai_tool_options_test.dart packages/llm_dart_openai/test/openai_responses_request_body_projection_test.dart`
  Review: review-workstream.
  Evidence: `packages/llm_dart_openai/lib/src/provider/openai_family_profile.dart`;
  `packages/llm_dart_openai/lib/src/provider/openai_family_route_policy.dart`;
  profile-owned option/capability/request-policy tests; full OpenAI package
  tests; analyzer; workspace/root/transport guards; and `git diff --check`
  evidence recorded in `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — route choice, option resolution, capability policy,
  Chat Completions request policy, and OpenAI tool-option acceptance are now
  profile-owned. Custom compatible endpoints use `OpenAICompatibleProfile`
  instead of mutating `OpenAIProfile`.

## M2 — Provider Transport Kit

- [x] FBR-040 [owner=codex] [deps=FBR-020] [scope=packages/llm_dart_provider_utils,packages/llm_dart_transport,packages/llm_dart_openai,packages/llm_dart_google,packages/llm_dart_anthropic]
  Goal: Deepen the provider call execution module so send, stream,
  cancellation, raw chunk forwarding, and transport-to-model error projection
  have one tested locality.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider_utils/test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_google/test/google_language_model_test.dart packages/llm_dart_anthropic/test/anthropic_language_model_test.dart`
  Review: review-workstream.
  Evidence: `packages/llm_dart_provider_utils/lib/src/http/provider_transport_call.dart`;
  `packages/llm_dart_provider_utils/test/provider_transport_call_test.dart`;
  FBR-040 provider-utils tests; OpenAI, Google, Anthropic language model
  regressions; package tests/analyze for touched providers; dependency/root
  guards; and `git diff --check` evidence recorded in
  `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — provider send/stream/cancellation/error choreography now
  lives behind `sendProviderModelRequest` and
  `sendProviderLanguageModelStreamRequest`. The public provider-utils package
  name remains acceptable for now because the seam is now real and shared.

- [x] FBR-050 [owner=codex] [deps=FBR-040] [scope=tool/check_workspace_dependency_guards.dart,packages/*/pubspec.yaml]
  Goal: Update dependency guards so provider utility ownership and transport
  ownership cannot drift back together accidentally.
  Validation: `dart --suppress-analytics run tool/check_workspace_dependency_guards.dart`
  Review: review-workstream.
  Evidence: `tool/check_workspace_dependency_guards.dart`;
  `test/tool/check_workspace_dependency_guards_test.dart`; guard failure test;
  direct guard output; analyzer; root boundary guard; and `git diff --check`
  evidence recorded in `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — provider package implementation files are now guarded
  against direct `transport.send` / `transport.sendStream` choreography.

## M3 — Breaking Compatibility Exit And Provider Spec Freeze

- [x] FBR-060 [owner=codex] [deps=FBR-010] [scope=packages/llm_dart_core,lib,pubspec.yaml,melos.yaml,tool]
  Goal: Remove `llm_dart_core` from the main package graph or reduce it to a
  deprecated migration stub with no implementation ownership.
  Validation: `dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart`
  Review: review-workstream.
  Evidence: Deleted `packages/llm_dart_core/**`; removed
  `tool/check_core_compatibility_shell_guard.dart`; updated root/dev
  dependencies, bootstrap/release/smoke/package-test tooling, migration docs,
  and focused tests; fresh analyze, targeted tests, root/workspace/transport
  guards, `test/test_all.dart`, and `git diff --check` evidence recorded in
  `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — this is intentionally breaking; redundant core aliases are
  gone instead of preserved as a migration stub.

- [x] FBR-070 [owner=codex] [deps=FBR-020] [scope=packages/llm_dart_provider/lib/src/provider,packages/llm_dart_provider/lib/src/model,packages/llm_dart_provider/test]
  Goal: Freeze a provider specification seam with explicit versioning,
  optional facets, capability descriptors, and supported input shape discovery.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test/provider_contracts_test.dart packages/llm_dart_provider/test/provider_registry_test.dart packages/llm_dart_provider/test/provider_model_facet_support_test.dart`
  Review: review-workstream.
  Evidence: `packages/llm_dart_provider/lib/src/provider/provider_specification.dart`;
  provider registry/facet resolver tests; concrete provider facade
  specifications for OpenAI-family, Google, Anthropic, Ollama, and ElevenLabs;
  provider package tests/analyze; root/workspace guards; and `git diff
  --check` evidence recorded in `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — `Provider` now requires a versioned
  `ProviderSpecification`; typed provider options remain the Dart-first
  extension path.

## M4 — Stream Vocabulary And Runtime Surface

- [x] FBR-080 [owner=codex] [deps=FBR-070] [scope=packages/llm_dart_provider/lib/src/stream,packages/llm_dart_ai/lib/src/stream,packages/llm_dart_ai/lib/src/serialization,packages/llm_dart_provider/lib/src/serialization]
  Goal: Make AI runtime stream events compose model-call event vocabulary
  instead of copying provider event implementation and codec logic.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`
  Review: review-workstream.
  Evidence: `packages/llm_dart_ai/lib/src/serialization/text_stream_event_json_codec.dart`;
  deleted duplicate AI content/tool stream codec files; added AI/provider
  codec-composition tests; fresh provider/AI stream codec tests, AI/provider
  package tests/analyze, root/workspace guards, and `git diff --check`
  evidence recorded in `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — runtime lifecycle events remain AI-owned while model-call
  event JSON vocabulary is composed from the provider codec.

- [x] FBR-090 [owner=codex] [deps=FBR-080] [scope=packages/llm_dart_ai/lib/src/model,packages/llm_dart_ai/test]
  Goal: Collapse repeated runtime helper option surfaces behind one deep text
  generation runtime module.
  Validation: `dart --suppress-analytics test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/output_spec_test.dart packages/llm_dart_ai/test/text_call_test.dart`
  Review: review-workstream.
  Evidence: `packages/llm_dart_ai/lib/src/model/text_generation_runtime_request.dart`;
  `packages/llm_dart_ai/test/text_generation_runtime_request_test.dart`;
  FBR-090 targeted runtime/helper tests, full AI package tests, analyzer,
  boundary guards, and `git diff --check` evidence recorded in
  `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — public helper ergonomics remain intact while prompt
  normalization, immutable tools/stop conditions, planner/continuation setup,
  cancellation helpers, and structured-output option derivation now pass
  through one internal runtime request seam.

## M5 — Migration Docs And Closeout

- [x] FBR-100 [owner=codex] [deps=FBR-060,FBR-070,FBR-090] [scope=README.md,CHANGELOG.md,docs/migration,example]
  Goal: Update migration docs and examples for the breaking architecture line.
  Validation: `dart --suppress-analytics analyze .`
  Review: review-workstream.
  Evidence: `README.md`, `CHANGELOG.md`,
  `docs/migration/0.11-sdk-aligned.md`, `packages/llm_dart_ai/README.md`,
  and example README updates; fresh `dart --suppress-analytics analyze .`,
  workspace/root/transport guards, and `git diff --check` evidence recorded in
  `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — obsolete `llm_dart_core`, root legacy, root provider/model,
  and builder paths are now documented only as removed/migration-warning
  surfaces, while direct provider packages and focused runtime facades are the
  recommended path.

- [x] FBR-110 [owner=planner] [deps=FBR-100] [scope=docs/workstreams/2026-05-fearless-boundary-reset]
  Goal: Verify final gates, close the lane, or split remaining scope into
  smaller follow-on workstreams.
  Validation: `dart --suppress-analytics run tool/check_workspace_dependency_guards.dart && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && git diff --check`
  Review: review-workstream and verify-rust-workstream adapted to Dart gates.
  Evidence: `EVIDENCE_AND_GATES.md`, `WORKSTREAM.json`, `HANDOFF.md`;
  final analyzer, OpenAI package tests, guards, and `git diff --check`
  evidence recorded in `EVIDENCE_AND_GATES.md`.
  Handoff: DONE — lane closed; suggested follow-ons are tracked as residual
  risks rather than blockers.
