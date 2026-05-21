# Fearless Boundary Reset — Milestones

Status: Closed
Last updated: 2026-05-21

## Closeout Summary

Closed at 2026-05-21 21:12 +08:00.

All milestone exit criteria are met. The lane intentionally breaks
compatibility where old surfaces obscured ownership: `llm_dart_core` is
deleted, root remains a focused facade, provider objects declare
`ProviderSpecification`, OpenAI route/provider-family policy is profile-owned,
provider transport execution is behind provider-utils, AI full-stream JSON
composes provider model-call event vocabulary, and AI helper implementation
state now flows through one internal runtime request seam.

## M0 — Scope And Evidence Freeze

Exit criteria:

- The workstream exists with a clear target state and non-goals.
- The first vertical proof is chosen.
- Relevant prior workstreams and `repo-ref/ai` reference areas are linked.
- The task ledger uses bounded, independently verifiable slices.

Primary evidence:

- `docs/workstreams/2026-05-fearless-boundary-reset/DESIGN.md`
- `docs/workstreams/2026-05-fearless-boundary-reset/TODO.md`

## M1 — OpenAI Route Adapter Proof

Exit criteria:

- OpenAI Responses and Chat Completions behavior sit behind route-specific
  adapters or equivalent deep modules.
- OpenAI-compatible family policy is profile-owned where route behavior varies.
- Existing OpenAI provider-native helpers remain provider-owned.
- Focused OpenAI tests pass.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_lifecycle_client_test.dart
```

## M2 — Provider Transport Kit

Exit criteria:

- Repeated provider send/stream/cancellation/error/raw-chunk choreography is
  concentrated behind one deep provider call execution module.
- Transport remains transport-owned; provider model errors remain
  provider-facing.
- At least three provider packages prove the module through focused tests.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_provider_utils/test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_google/test/google_language_model_test.dart packages/llm_dart_anthropic/test/anthropic_language_model_test.dart
```

## M3 — Breaking Compatibility Exit And Provider Spec Freeze

Exit criteria:

- `llm_dart_core` no longer acts as an architecture owner.
- Root remains a focused facade and no longer hides obsolete package choices.
- `llm_dart_provider` exposes an explicit provider specification seam.
- Guard tooling rejects dependency and facade regressions.

Primary gates:

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
```

## M4 — Stream Vocabulary And Runtime Surface

Exit criteria:

- Runtime streams compose provider model-call vocabulary for content/tool
  events while retaining runtime-owned run/step/abort lifecycle events.
- Runtime helper implementation has one primary locality.
- Public helper ergonomics remain clear and provider-neutral.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart
dart --suppress-analytics test packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/output_spec_test.dart packages/llm_dart_ai/test/text_call_test.dart
```

## M5 — Closeout

Exit criteria:

- Migration docs and examples teach the new architecture.
- Fresh targeted and guard evidence is recorded.
- `WORKSTREAM.json` status is updated.
- Remaining work is completed, explicitly deferred, or split into a narrower
  follow-on workstream.

Primary gates:

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```
