# Remaining Boundary Fearless Refactor — Evidence And Gates

Status: Complete
Last updated: 2026-05-27

## Smallest Current Proof

RBF-020 is the first proof: determine whether provider fixture/codecs need a
reusable contract runner or whether provider-local fixtures remain the deeper
Interface.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart
```

## Gate Set

### Targeted Iteration Gate

Use the validation command from the active task in `TODO.md`.

### Package Gate

Run package-level analysis and tests for touched packages:

```powershell
dart --suppress-analytics analyze packages/llm_dart_provider packages/llm_dart_provider_utils packages/llm_dart_ai
dart --suppress-analytics test packages/llm_dart_provider/test packages/llm_dart_provider_utils/test packages/llm_dart_ai/test
```

Adapt package names for chat or concrete provider slices.

### Boundary Guard Gate

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
```

### Broader Closeout Gate

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
git diff --check
```

If a candidate is rejected by the deletion test, record that as evidence rather
than forcing a shallow implementation.

### Review Gate

Review focus:

- Interface depth and deletion-test outcome;
- provider/app/runtime dependency direction;
- provider-native feature preservation;
- error and serialization diagnostics;
- fixture coverage at the seam;
- migration docs for public breaking surfaces.

## Evidence Anchors

- `docs/workstreams/2026-05-core-seam-fearless-refactor/`
- `docs/workstreams/2026-05-provider-fixture-contracts/`
- `docs/workstreams/2026-05-anthropic-fixture-contracts/`
- `docs/workstreams/2026-05-provider-implementation-kit-and-codec-boundaries/`
- `packages/llm_dart_provider_utils/lib/provider_call_kit.dart`
- `packages/llm_dart_ai/lib/app.dart`
- `packages/llm_dart_provider/lib/provider_authoring.dart`

## Evidence Log

### 2026-05-27 — RBF-010 Scope and evidence freeze

Evidence:

- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/DESIGN.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/TODO.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/MILESTONES.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/EVIDENCE_AND_GATES.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/WORKSTREAM.json`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/HANDOFF.md`

Result: completed.

Notes:

- Existing unrelated working-tree changes were left untouched.
- The lane starts with provider codec contract because it has the clearest
  repeated proof surface and does not reopen the closed root/app seam.

### 2026-05-27 — RBF-020 Provider codec contract runner

Evidence:

- `packages/llm_dart_test/lib/src/provider_codec_contract_runner.dart`
- `packages/llm_dart_test/test/fake_support_test.dart`
- `packages/llm_dart_openai/test/openai_fixture_contract_test.dart`
- `packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart`
- `packages/llm_dart_google/test/google_fixture_contract_test.dart`
- `packages/llm_dart_ollama/test/ollama_fixture_contract_test.dart`

Result: completed.

Design decision:

- The reusable contract runner lives in `llm_dart_test`, not
  `llm_dart_provider_utils`, because the shared policy is test-only fixture
  lookup, JSON equality, mismatch diagnostics, and provider stream-event
  projection. Concrete provider codecs remain provider-owned.
- Request bodies, replay metadata, and warning fixtures use generic JSON
  fixture comparison. Stream projection uses
  `expectLanguageModelStreamEventsFixture`.
- Error-projection fixture sharing is explicitly rejected for this slice:
  provider error golden fixtures are not yet repeated enough to justify a
  shared error-specific Interface. The generic JSON method can cover those
  fixtures later without moving error projection out of provider code.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart packages/llm_dart_google/test/google_fixture_contract_test.dart packages/llm_dart_ollama/test/ollama_fixture_contract_test.dart
dart --suppress-analytics test packages/llm_dart_test/test/fake_support_test.dart packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart packages/llm_dart_google/test/google_fixture_contract_test.dart packages/llm_dart_ollama/test/ollama_fixture_contract_test.dart
dart --suppress-analytics analyze packages/llm_dart_test packages/llm_dart_openai packages/llm_dart_anthropic packages/llm_dart_google packages/llm_dart_ollama
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
```

All commands passed on 2026-05-27.

### 2026-05-27 — RBF-030 Capability descriptor enforcement

Evidence:

- `packages/llm_dart_provider/lib/src/provider/provider_capability_gate.dart`
- `packages/llm_dart_provider/lib/src/provider/provider_model_facet_support.dart`
- `packages/llm_dart_provider/lib/src/provider/provider_registry.dart`
- `packages/llm_dart_provider/test/provider_contracts_test.dart`
- `packages/llm_dart_provider/test/provider_registry_test.dart`
- `packages/llm_dart_provider/test/provider_model_facet_support_test.dart`
- `packages/llm_dart_ai/lib/app.dart`

Result: completed.

Design decision:

- `ProviderCapabilityGate` is the descriptor-backed provider gate for hard
  requirements and UI/discovery affordances. It consumes
  `ProviderSpecification`, provider model facet interfaces, optional explicit
  `ProviderModelFacetSupport`, shared capabilities, provider features, input
  shapes, media types, and confidence levels.
- `ModelCapabilityGate` applies the same confidence policy to concrete
  `ModelCapabilityProfile` values.
- `CapabilityGateMode.requirement` accepts only `known` and `userProvided`
  descriptors. `CapabilityGateMode.affordance` may surface `inferred`
  descriptors but still rejects `unknown` or absent support.
- `ProviderModelFacetSupportResolver` now routes through
  `ProviderCapabilityGate`, so registry model lookup uses the same gate as
  app/UI callers instead of a parallel support policy.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/provider_contracts_test.dart packages/llm_dart_provider/test/provider_registry_test.dart packages/llm_dart_provider/test/provider_model_facet_support_test.dart
dart --suppress-analytics test packages/llm_dart_ai/test packages/llm_dart_chat/test
dart --suppress-analytics analyze packages/llm_dart_provider packages/llm_dart_ai packages/llm_dart_chat
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
```

All commands passed on 2026-05-27.

### 2026-05-27 — RBF-040 Non-text app request seams

Evidence:

- `packages/llm_dart_ai/lib/src/model/embed.dart`
- `packages/llm_dart_ai/lib/src/model/generate_image.dart`
- `packages/llm_dart_ai/lib/src/model/generate_speech.dart`
- `packages/llm_dart_ai/lib/src/model/transcribe.dart`
- `packages/llm_dart_ai/lib/src/model/non_text_request_support.dart`
- `packages/llm_dart_ai/test/capability_helpers_test.dart`
- `docs/migration/0.11-sdk-aligned.md`

Result: completed.

Design decision:

- Added app-facing request seams for all non-text helpers:
  `EmbeddingRequest`, `GenerateImageRequest`, `GenerateSpeechRequest`, and
  `TranscribeRequest`.
- Existing convenience helpers delegate through the new request seams.
- The seams do more than mirror provider request constructors: they freeze app
  input collections, own provider-request projection, enforce published model
  count limits, and use `ModelCapabilityGate` for stable optional features
  such as embedding dimensions, image editing, speech voice selection, and
  speech output formats.
- Provider-native options and wire projection remain provider-owned.

Validation:

```powershell
dart --suppress-analytics analyze packages/llm_dart_ai packages/llm_dart_provider
dart --suppress-analytics test packages/llm_dart_ai/test/capability_helpers_test.dart packages/llm_dart_provider/test/provider_contracts_test.dart
dart --suppress-analytics test packages/llm_dart_ai/test packages/llm_dart_provider/test
```

All commands passed on 2026-05-27.

### 2026-05-27 — RBF-050 Chat turn and transport protocol

Evidence:

- `packages/llm_dart_chat/lib/src/http_chat_transport_stream_session.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_stream_client.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_resume_state.dart`
- `packages/llm_dart_chat/test/http_chat_transport_stream_session_test.dart`
- `packages/llm_dart_chat/test/http_chat_transport_stream_client_test.dart`

Result: completed.

Design decision:

- Added an internal `HttpChatTransportStreamSession` Module. Its Interface is
  the state plus a clear callback and a frame stream; its Implementation owns
  the ordering-sensitive client protocol rules: HTTP status failures clear and
  terminate, received chunks mutate replay/resume state through the chunk
  projection, abort/error chunks stop consumption, and caught stream errors
  preserve reconnectable state only when a resume token exists.
- `HttpChatTransportStreamClient` no longer knows projection, replay, terminal
  cleanup, or caught-error policy. It builds the transport request and delegates
  protocol consumption to the session.
- `HttpChatTransportResumeStateClearer` moved to
  `http_chat_transport_resume_state.dart`; keeping it in error projection made
  callers depend on the wrong Module for a lifecycle type.
- A new chat turn protocol was rejected for this slice. The deletion test
  showed `DefaultChatSessionActiveTurn` already has locality for UI reader
  ordering, active subscription lifecycle, stop/dispose semantics, and prompt
  append timing. Adding a second turn Interface would duplicate that state.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_chat/test/http_chat_transport_stream_session_test.dart packages/llm_dart_chat/test/http_chat_transport_stream_client_test.dart
dart --suppress-analytics analyze packages/llm_dart_chat
dart --suppress-analytics test packages/llm_dart_chat/test packages/llm_dart_ai/test/chat_ui_stream_projection_test.dart
```

All commands passed on 2026-05-27.

### 2026-05-27 — RBF-060 Provider options policy

Evidence:

- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_namespaces.dart`
- `packages/llm_dart_openai/lib/src/language/openai_generate_text_options.dart`
- `packages/llm_dart_openai/lib/src/provider/deepseek_options.dart`
- `packages/llm_dart_openai/lib/src/provider/openrouter_options.dart`
- `packages/llm_dart_openai/lib/src/provider/xai_options.dart`
- `packages/llm_dart_openai/lib/src/embedding/openai_embedding_options.dart`
- `packages/llm_dart_openai/lib/src/image/openai_image_options.dart`
- `packages/llm_dart_openai/lib/src/speech/openai_speech_options.dart`
- `packages/llm_dart_openai/lib/src/transcription/openai_transcription_options.dart`
- `packages/llm_dart_provider/lib/src/common/provider_invocation_options.dart`
- `packages/llm_dart_openai/test/openai_family_option_resolver_test.dart`
- `packages/llm_dart_openai/test/openai_embedding_model_body_test.dart`

Result: completed.

Design decision:

- Followed Vercel AI SDK's provider-options shape: provider-specific options
  are grouped by provider namespace such as `openai`, `deepseek`,
  `openrouter`, and `xai`.
- Kept Dart typed options as the primary Interface, but made OpenAI-family
  typed options implement `ProviderInvocationOptionsBagProjection`. Each typed
  option class now owns its JSON provider-options namespace projection instead
  of relying on duplicated free functions.
- Existing `openAI*OptionsToProviderOptionsBag(...)` helpers remain as
  compatibility wrappers and delegate to the typed option projection, so there
  is one encoding policy.
- `providerOptionsBagFromInvocationOptions(...)` now normalizes an empty typed
  projection back to `null`, preserving the existing "no provider options"
  semantics while allowing non-empty typed options to cross JSON/transport
  seams.
- Model-kind applicability remains enforced by typed resolvers before bag
  parsing. A language provider option that can project to the `openai`
  namespace is still rejected when used with an embedding model.
- Route codecs and compatibility warning Modules were retained. The deletion
  test showed they already concentrate route-specific request-shape policy and
  warning text; moving them into a generic options policy would reduce
  locality.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart packages/llm_dart_openai/test/openai_embedding_model_body_test.dart packages/llm_dart_provider/test/provider_contracts_test.dart
dart --suppress-analytics analyze packages/llm_dart_openai packages/llm_dart_provider
dart --suppress-analytics test packages/llm_dart_openai/test/openai_embedding_model_test.dart packages/llm_dart_openai/test/openai_image_model_test.dart
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_openai/test
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
```

All commands passed on 2026-05-27.

### 2026-05-27 — RBF-070 Serialization registry decision

Evidence:

- `packages/llm_dart_provider/lib/src/serialization/versioned_json_envelope_codec.dart`
- `packages/llm_dart_provider/lib/src/serialization/serialization_envelope_json_codec.dart`
- `packages/llm_dart_ai/lib/src/serialization/ai_serialization_envelope_json_codec.dart`
- `packages/llm_dart_chat/lib/src/http_chat_transport_envelope_json_codec.dart`
- `packages/llm_dart_chat/lib/src/chat_session_snapshot_envelope_json_codec.dart`
- `packages/llm_dart_provider/test/versioned_json_envelope_codec_test.dart`

Result: completed.

Design decision:

- A full serialization registry was rejected. The deletion test showed that
  prompt parts, stream events, UI messages, chat snapshots, and HTTP transport
  payloads need explicit codec families because each family owns different
  domain semantics, compatibility rules, and diagnostic language.
- The repeated deep seam was the schema-versioned envelope shape:
  `schemaVersion`, `kind`, and `data`. `VersionedJsonEnvelopeCodec` now owns
  that cross-package envelope validation while letting each caller supply its
  own unsupported-version wording.
- Provider option codecs and provider-owned serialization hooks remain
  explicit. A registry would hide provider-specific failure points and make
  future wire compatibility harder to audit.

Validation:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/versioned_json_envelope_codec_test.dart packages/llm_dart_provider/test/prompt_json_codec_test.dart packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_ai/test/chat_ui_json_codec_test.dart packages/llm_dart_chat/test/chat_persistence_adapter_test.dart packages/llm_dart_chat/test/http_chat_transport_protocol_test.dart
dart --suppress-analytics analyze packages/llm_dart_provider packages/llm_dart_ai packages/llm_dart_chat
dart --suppress-analytics test packages/llm_dart_provider/test packages/llm_dart_ai/test packages/llm_dart_chat/test
```

All commands passed on 2026-05-27.

### 2026-05-27 — RBF-080 Closeout

Evidence:

- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/DESIGN.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/TODO.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/MILESTONES.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/EVIDENCE_AND_GATES.md`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/WORKSTREAM.json`
- `docs/workstreams/2026-05-remaining-boundary-fearless-refactor/HANDOFF.md`

Result: completed.

Closeout decision:

- All planned tasks completed.
- No required candidate remains open. Speculative seams were rejected where the
  deletion test showed current explicit Modules were deeper than a generic
  abstraction.
- Existing unrelated working-tree changes were left untouched. Commit staging
  must remain path-precise.

Validation:

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
git diff --check
```

All commands passed on 2026-05-27.
