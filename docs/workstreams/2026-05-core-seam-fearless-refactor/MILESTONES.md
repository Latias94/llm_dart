# Core Seam Fearless Refactor — Milestones

Status: Closed
Last updated: 2026-05-27

## M0 — Scope And Evidence Freeze

Exit criteria:

- Problem and target state are explicit.
- Non-goals are explicit.
- Relevant workstreams and `repo-ref/ai` reference docs are linked.
- Six candidates are ordered by dependency and risk.

Primary evidence:

- `docs/workstreams/2026-05-core-seam-fearless-refactor/DESIGN.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/TODO.md`

## M1 — App-Facing Text Generation Request

Status: Complete on 2026-05-26.

Exit criteria:

- A public request object becomes the deep interface for text generation.
- Existing helper functions are adapters, not independent option plumbing.
- Runtime request tests prove prompt normalization, immutability, cancellation,
  callbacks, stop conditions, and structured-output derivation.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_ai/test/text_generation_request_test.dart packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/output_spec_test.dart packages/llm_dart_ai/test/text_call_test.dart
dart --suppress-analytics analyze packages/llm_dart_ai
```

## M2 — Error Module

Status: Complete on 2026-05-26.

Exit criteria:

- Runtime/provider/transport error semantics are documented in one module.
- Stream error projection and thrown error projection use the same taxonomy.
- Existing raw Dart exceptions are either internal implementation details or
  explicit compatibility adapters.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test packages/llm_dart_provider_utils/test packages/llm_dart_ai/test
```

## M3 — Stream Vocabulary Composition

Status: Complete on 2026-05-26.

Exit criteria:

- Provider model-call event vocabulary has one implementation locality where
  the deletion test says duplication would otherwise spread.
- Runtime-only lifecycle events remain AI-owned.
- Provider packages do not emit AI runtime-only events.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart
```

## M4 — Provider Descriptor Modules

Status: Complete on 2026-05-26.

Exit criteria:

- Provider facade modules delegate spec/facet/input-shape description to
  provider-owned descriptor modules.
- Provider registry behavior is unchanged or intentionally improved.
- Provider-native product clients remain provider-owned adapters.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/provider_registry_test.dart packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_google/test/google_entrypoint_test.dart packages/llm_dart_anthropic/test/anthropic_entrypoint_test.dart packages/llm_dart_ollama/test/ollama_entrypoint_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_entrypoint_test.dart
```

## M5 — Provider Call Kit

Status: Complete on 2026-05-26.

Exit criteria:

- Provider-utils exports a named provider call kit rather than loose helpers.
- Provider packages do not reintroduce direct `transport.send` or
  `transport.sendStream` choreography.
- Shared call execution stays provider-facing, not a replacement for
  provider-local codecs.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_provider_utils/test
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
```

## M6 — App And Provider-Authoring Entrypoints

Status: Complete on 2026-05-27.

Exit criteria:

- App examples use app-facing request/message types by default.
- Provider-authoring contracts remain explicit and reachable.
- Root remains a facade, not an implementation owner.
- Migration docs explain breaking import and helper changes.

Primary gates:

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
```

## M7 — Closeout

Status: Complete on 2026-05-27.

Exit criteria:

- All tasks are done, explicitly deferred, or split.
- Fresh final gates are recorded.
- `WORKSTREAM.json` status is updated.
- `HANDOFF.md` contains next action and residual risk.
