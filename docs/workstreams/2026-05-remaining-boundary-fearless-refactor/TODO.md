# Remaining Boundary Fearless Refactor — TODO

Status: Complete
Last updated: 2026-05-27

## M0 — Scope And Evidence Freeze

- [x] RBF-010 [owner=planner] [deps=none] [scope=docs/workstreams/2026-05-remaining-boundary-fearless-refactor]
  Goal: Open the durable lane, freeze candidate order, record non-goals, and
  define evidence gates.
  Validation: DESIGN.md, TODO.md, MILESTONES.md, EVIDENCE_AND_GATES.md,
  WORKSTREAM.json, and HANDOFF.md exist and agree.
  Review: Check that this lane does not reopen the closed core seam refactor.
  Evidence: workstream docs.
  Handoff: Start with provider codec contract because it has the highest
  locality/leverage ratio and aligns with existing fixture workstreams.

## M1 — Provider Codec Contract

- [x] RBF-020 [owner=codex] [deps=RBF-010] [scope=packages/llm_dart_test,packages/llm_dart_provider_utils,packages/llm_dart_provider,packages/llm_dart_openai/test,packages/llm_dart_anthropic/test,packages/llm_dart_google/test,docs/workstreams]
  Goal: Define or reject a reusable provider codec contract runner for request
  encoding, stream projection, replay metadata, warnings, and error projection.
  Validation: `dart --suppress-analytics test packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart`
  Review: Keep provider-specific codecs provider-owned; shared contract runner
  may own only repeated golden-test policy.
  Evidence: `ProviderCodecContractRunner` in `llm_dart_test`; OpenAI,
  Anthropic, Google, and Ollama fixture contracts now use it for JSON fixtures
  and provider stream-event projection. Error-projection sharing is rejected
  for this slice until repeated provider golden fixtures exist.
  Handoff: Use this runner as the template for subsequent provider fixture
  lanes; keep concrete codecs, native replay, and warning generation
  provider-owned.

## M2 — Capability Descriptor Enforcement

- [x] RBF-030 [owner=codex] [deps=RBF-020] [scope=packages/llm_dart_provider,packages/llm_dart_ai,packages/llm_dart_chat,packages/*/test]
  Goal: Add a capability gate Interface that consumes provider descriptors for
  app/runtime validation and UI affordance decisions without hard-coding
  provider families.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test/provider_registry_test.dart packages/llm_dart_ai/test packages/llm_dart_chat/test`
  Review: Descriptor data must not overpromise inferred provider behavior.
  Evidence: `ProviderCapabilityGate`, `ModelCapabilityGate`, and
  `CapabilityGateMode` are exported from provider foundation/app surfaces;
  registry facet enforcement now routes through the descriptor-backed gate;
  tests cover known, inferred, unknown, user-provided, media-type, model-kind,
  and provider-object facet decisions.
  Handoff: Non-text request seams should use the gate only for stable facts;
  inferred descriptors are appropriate for affordances but not hard request
  rejection.

## M3 — Non-Text App Request Seams

- [x] RBF-040 [owner=codex] [deps=RBF-030] [scope=packages/llm_dart_ai/lib/src/model,packages/llm_dart_provider/lib/src/model,packages/llm_dart_ai/test,README.md,docs/migration]
  Goal: Apply the deletion test to embed, image, speech, and transcription
  helpers; add deep app request Modules only where they concentrate validation
  and provider request projection complexity.
  Validation: `dart --suppress-analytics test packages/llm_dart_ai/test packages/llm_dart_provider/test`
  Review: Do not create shallow request objects that only mirror provider
  request constructors.
  Evidence: Added `EmbeddingRequest`, `GenerateImageRequest`,
  `GenerateSpeechRequest`, `TranscribeRequest`, and `*ForRequest(...)` helpers.
  Existing convenience helpers delegate through these app request seams. The
  seams freeze app inputs, project provider requests, enforce published model
  count limits, and use capability gates for stable optional features.
  Handoff: Chat turn/transport protocol is next; non-text provider-specific
  option projection remains provider-owned.

## M4 — Chat Turn And Transport Protocol

- [x] RBF-050 [owner=codex] [deps=RBF-030] [scope=packages/llm_dart_chat/lib,packages/llm_dart_chat/test,packages/llm_dart_ai/lib/src/ui]
  Goal: Deepen or explicitly reject a chat turn/transport protocol Interface
  that owns ordering, replay, resume, cancellation, stream error recovery, and
  HTTP chunk protocol invariants.
  Validation: `dart --suppress-analytics test packages/llm_dart_chat/test packages/llm_dart_ai/test/chat_ui_stream_projection_test.dart`
  Review: Keep UI projection in AI/chat layers and provider prompt contracts
  out of app-facing chat input.
  Evidence: Added internal `HttpChatTransportStreamSession` to own frame
  projection, replay/resume mutation, terminal clearing, stream termination,
  and caught transport error recovery. `HttpChatTransportStreamClient` now only
  builds the transport request and delegates stream protocol consumption.
  Handoff: Default chat session turn lifecycle was retained because
  `DefaultChatSessionActiveTurn` already concentrates UI-reader ordering and
  completion semantics; adding a second turn protocol would be shallow.

## M5 — Provider Options Policy

- [x] RBF-060 [owner=codex] [deps=RBF-020,RBF-030] [scope=packages/llm_dart_openai/lib/src/provider,packages/llm_dart_provider/lib/src/common,packages/llm_dart_openai/test]
  Goal: Improve provider options policy locality, especially OpenAI-family
  namespace routing, model-kind applicability, and compatibility warning
  policy, without weakening typed provider options.
  Validation: `dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_openai/test`
  Review: Provider-native options stay provider-owned; shared provider option
  contracts stay generic.
  Evidence: OpenAI-family typed provider options now implement
  `ProviderInvocationOptionsBagProjection` and own their provider namespace
  JSON projection. Namespace constants live in
  `openai_provider_options_namespaces.dart`; legacy bag helper functions
  delegate to typed options. Tests cover common OpenAI, DeepSeek, OpenRouter,
  non-text namespace projection, and model-kind rejection.
  Handoff: Route codecs and compatibility warning Modules were retained; the
  deletion test showed they already concentrate request-shape policy.

## M6 — Serialization Registry Decision

- [x] RBF-070 [owner=codex] [deps=RBF-020,RBF-050] [scope=packages/llm_dart_ai/lib/src/serialization,packages/llm_dart_provider/lib/src/serialization,packages/llm_dart_chat/lib/src,packages/*/test]
  Goal: Decide whether serialization needs a registry/deep Interface or should
  remain explicit codec families. Implement only if the deletion test proves
  repeated boilerplate is worse than registry complexity.
  Validation: `dart --suppress-analytics test packages/llm_dart_provider/test packages/llm_dart_ai/test packages/llm_dart_chat/test`
  Review: Serialization errors, schema versions, and provider option codecs
  must stay easy to diagnose.
  Evidence: Full serialization registry rejected by deletion test. Added
  `VersionedJsonEnvelopeCodec` for repeated schema-version/kind/data envelope
  handling, and retained explicit prompt/event/part/body codec families for
  domain semantics and diagnostics.
  Handoff: Closeout can treat RBF-070 as complete; the remaining work is final
  gate execution, summary, and commit hygiene.

## M7 — Closeout

- [x] RBF-080 [owner=planner] [deps=RBF-070] [scope=docs/workstreams/2026-05-remaining-boundary-fearless-refactor,README.md,docs/migration,tool]
  Goal: Review the lane, run final gates, update docs, close or split any
  incomplete candidate.
  Validation: `dart --suppress-analytics analyze . && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && dart --suppress-analytics run tool/check_example_api_guards.dart && git diff --check`
  Review: Workstream compliance and code-quality review before closing.
  Evidence: Fresh final gates passed; `EVIDENCE_AND_GATES.md`,
  `WORKSTREAM.json`, and `HANDOFF.md` record the closed state.
  Handoff: No required split. Optional follow-ons are provider fixture
  expansion and provider-specific error golden contracts when repeated proof
  surfaces appear.
