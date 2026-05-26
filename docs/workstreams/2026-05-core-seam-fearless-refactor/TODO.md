# Core Seam Fearless Refactor — TODO

Status: Closed
Last updated: 2026-05-27

## M0 — Scope And Evidence Freeze

- [x] CSR-010 [owner=planner] [deps=none] [scope=docs/workstreams/2026-05-core-seam-fearless-refactor]
  Goal: Freeze the six core seam refactor candidates, dependency order,
  non-goals, and evidence anchors.
  Validation: DESIGN.md, TODO.md, MILESTONES.md, EVIDENCE_AND_GATES.md,
  WORKSTREAM.json, and HANDOFF.md exist and agree.
  Evidence: `docs/workstreams/2026-05-core-seam-fearless-refactor/DESIGN.md`
  Handoff: Start with app-facing text generation request because the internal
  runtime request already proves the deep module shape.

## M1 — App-Facing Text Generation Request

- [x] CSR-020 [owner=codex] [deps=CSR-010] [scope=packages/llm_dart_ai/lib/src/model,packages/llm_dart_ai/test,lib,README.md,docs/migration]
  Goal: Add a public app-facing text generation request module and make
  `generateText`, `streamText`, text-call, and structured-output helpers thin
  adapters over it where practical.
  Validation: `dart --suppress-analytics test packages/llm_dart_ai/test/text_generation_request_test.dart packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/output_spec_test.dart packages/llm_dart_ai/test/text_call_test.dart`
  Review: Check that the new public interface is deep and does not merely
  duplicate the old named-parameter surface.
  Evidence: `packages/llm_dart_ai/lib/src/model/text_generation_request.dart`
  Handoff: DONE. `TextGenerationRequest` is the app-facing request seam;
  existing helpers now route through request-based runner/output/text-call
  entrypoints.

## M2 — Error Module

- [x] CSR-030 [owner=codex] [deps=CSR-020] [scope=packages/llm_dart_provider/lib/src/common,packages/llm_dart_ai/lib/src/error,packages/llm_dart_provider_utils/lib/src/common,packages/llm_dart_transport/lib/src/common,packages/*/test]
  Goal: Concentrate runtime, provider, and transport failure semantics behind
  one coherent error module with typed errors, `ModelError` projection, stream
  error projection, JSON, and tests.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test packages/llm_dart_provider_utils/test packages/llm_dart_ai/test`
  Review: Verify error types are part of the interface and callers no longer
  need to infer failure categories from raw Dart exception classes.
  Evidence: `packages/llm_dart_provider/lib/src/common/model_error.dart`
  Handoff: DONE. Provider now has typed `ModelException` plus the
  `modelErrorFrom` projection seam; provider-utils, structured output, stream
  failure, and chat UI stream errors route through that seam while preserving
  the serializable `ModelError` value object.

## M3 — Stream Vocabulary Composition

- [x] CSR-040 [owner=codex] [deps=CSR-030] [scope=packages/llm_dart_provider/lib/src/stream,packages/llm_dart_ai/lib/src/stream,packages/llm_dart_ai/lib/src/serialization,packages/llm_dart_provider/lib/src/serialization,packages/llm_dart_ai/test,packages/llm_dart_provider/test]
  Goal: Reduce provider/AI model-call stream vocabulary duplication without
  collapsing the provider model-call seam into the AI runtime lifecycle seam.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`
  Review: Preserve provider/runtime ownership split; compose values or helpers
  only where deletion test shows duplicated complexity.
  Evidence: stream vocabulary bridge and codec tests.
  Handoff: DONE. Provider-call stream vocabulary remains provider-owned;
  runtime-only events remain AI-owned. The duplicated bridge switches were
  consolidated into `text_stream_event_provider_bridge.dart`, and the old
  conversion modules are compatibility exports.

## M4 — Provider Descriptor Modules

- [x] CSR-050 [owner=codex] [deps=CSR-030] [scope=packages/llm_dart_openai/lib/src/provider,packages/llm_dart_google/lib/src,packages/llm_dart_anthropic/lib/src,packages/llm_dart_ollama/lib/src,packages/llm_dart_elevenlabs/lib/src,packages/llm_dart_provider/test]
  Goal: Make provider facades thin over provider-owned descriptor modules that
  own specification, model facets, supported input shapes, and provider-family
  policy description.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test/provider_registry_test.dart packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_google/test/google_entrypoint_test.dart packages/llm_dart_anthropic/test/anthropic_entrypoint_test.dart packages/llm_dart_ollama/test/ollama_entrypoint_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_entrypoint_test.dart`
  Review: Provider-native product clients remain provider-owned and are not
  flattened into shared abstractions.
  Evidence: provider descriptor files and provider registry tests.
  Handoff: DONE. Provider facades now delegate provider specification to
  provider-owned descriptor modules for OpenAI-family, Google, Anthropic,
  Ollama, and ElevenLabs; native product clients remain provider-owned.

## M5 — Provider Call Kit

- [x] CSR-060 [owner=codex] [deps=CSR-030] [scope=packages/llm_dart_provider_utils,packages/llm_dart_openai/lib/src,packages/llm_dart_google/lib/src,packages/llm_dart_anthropic/lib/src,packages/llm_dart_ollama/lib/src,packages/llm_dart_elevenlabs/lib/src,tool]
  Goal: Harden `llm_dart_provider_utils` as a provider call kit with explicit
  request, response, stream, cancellation, and error policy modules.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider_utils/test && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart`
  Review: Keep provider-specific codecs provider-local; provider-utils owns
  repeated call execution only.
  Evidence: `packages/llm_dart_provider_utils/lib/src/http/provider_transport_call.dart`
  Handoff: DONE. `llm_dart_provider_utils` now exposes an explicit
  `ProviderCallKit` object and `provider_call_kit.dart` aggregate while
  preserving existing function adapters and provider-local codecs.

## M6 — App And Provider-Authoring Entrypoints

- [x] CSR-070 [owner=codex] [deps=CSR-020,CSR-040,CSR-050,CSR-060] [scope=lib,packages/llm_dart_ai/lib,packages/llm_dart_provider/lib,README.md,docs/migration,example,tool]
  Goal: Make app-facing and provider-authoring entrypoints explicit, narrow
  root convenience exports where needed, and update docs/examples for the
  breaking surface.
  Validation: `dart --suppress-analytics analyze . && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && dart --suppress-analytics run tool/check_example_api_guards.dart`
  Review: Root remains a facade; provider-facing prompt contracts remain
  reachable for provider authors and advanced users without dominating app
  examples.
  Evidence: root and package entrypoint diffs plus migration docs.
  Handoff: DONE. Root `core.dart` now exports the narrow app facade
  `llm_dart_ai/app.dart`; provider-authoring contracts are explicit through
  `package:llm_dart/provider_authoring.dart`,
  `package:llm_dart_ai/provider_authoring.dart`, and
  `package:llm_dart_provider/provider_authoring.dart`. App examples use
  `ModelMessage`; provider-contract examples import the authoring facade.
  Provider call kit remains imported directly from
  `package:llm_dart_provider_utils/provider_call_kit.dart` so root does not
  grow a provider-utils runtime dependency.

## M7 — Closeout

- [x] CSR-080 [owner=planner] [deps=CSR-070] [scope=docs/workstreams/2026-05-core-seam-fearless-refactor]
  Goal: Review, verify, close the lane, or split any incomplete candidate into
  a narrower follow-on.
  Validation: `dart --suppress-analytics analyze . && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && git diff --check`
  Review: Workstream compliance and code-quality review before closeout.
  Evidence: `EVIDENCE_AND_GATES.md`, `WORKSTREAM.json`, `HANDOFF.md`
  Handoff: DONE. Fresh analysis, package tests, root/example/workspace guards,
  provider contract tests, provider descriptor tests, and `git diff --check`
  passed. No follow-on is required for the six scoped seams.
