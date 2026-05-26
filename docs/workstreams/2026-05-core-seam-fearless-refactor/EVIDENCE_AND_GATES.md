# Core Seam Fearless Refactor — Evidence And Gates

Status: Closed
Last updated: 2026-05-27

## Smallest Current Proof

CSR-020 is the first proof: make the app-facing text generation request a deep
module while keeping current helper ergonomics available as adapters.

```powershell
dart --suppress-analytics test packages/llm_dart_ai/test/text_generation_request_test.dart packages/llm_dart_ai/test/text_generation_runtime_request_test.dart
```

## Gate Set

### Targeted Iteration Gate

Use the validation command from the active task in `TODO.md`.

### Package Gate

Run package-level analysis and tests for touched packages:

```powershell
dart --suppress-analytics analyze packages/llm_dart_ai
dart --suppress-analytics test packages/llm_dart_ai/test
```

Adapt package names for provider, provider-utils, transport, chat, or concrete
provider slices.

### Boundary Guard Gate

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_transport_boundary_guards.dart
```

Use focused guards only when the touched slice cannot affect all boundaries.

### Broader Closeout Gate

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
git diff --check
```

If full workspace commands are too slow or unrelated, record the narrower gate
and why it proves the slice.

### Review Gate

Run a review before accepting task or lane completion. Review focus:

- module interface depth and deletion-test outcome;
- dependency direction;
- public breaking change clarity;
- test coverage at the interface;
- migration docs and examples for app-facing changes.

## Evidence Anchors

- `docs/workstreams/2026-05-core-seam-fearless-refactor/DESIGN.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/TODO.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/MILESTONES.md`
- `packages/llm_dart_ai/lib/src/model/text_generation_request.dart`
- `packages/llm_dart_provider/lib/src/common/model_error.dart`
- `packages/llm_dart_provider_utils/lib/src/http/provider_transport_call.dart`
- stream vocabulary bridge and codec tests
- provider descriptor tests

## Evidence Log

### 2026-05-26 — CSR-010 Scope and evidence freeze

Evidence:

- `docs/workstreams/2026-05-core-seam-fearless-refactor/DESIGN.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/TODO.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/MILESTONES.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/EVIDENCE_AND_GATES.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/WORKSTREAM.json`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/HANDOFF.md`

Result: completed.

Notes:

- This lane follows the architecture report generated at
  `%TEMP%/architecture-review-20260526-220928.html`.
- Existing user changes in unrelated files are left untouched.

### 2026-05-26 — CSR-020 App-facing text generation request

Evidence:

- `packages/llm_dart_ai/lib/src/model/text_generation_request.dart`
- `packages/llm_dart_ai/lib/src/model/generate_text_runner.dart`
- `packages/llm_dart_ai/lib/src/model/stream_text_runner.dart`
- `packages/llm_dart_ai/lib/src/model/language_model.dart`
- `packages/llm_dart_ai/lib/src/model/output_runner.dart`
- `packages/llm_dart_ai/lib/src/model/text_call_runner.dart`
- `packages/llm_dart_ai/test/text_generation_request_test.dart`

Commands:

```powershell
dart test packages\llm_dart_ai\test\text_generation_request_test.dart
dart test packages\llm_dart_ai\test\generate_text_runner_test.dart packages\llm_dart_ai\test\stream_text_runner_test.dart packages\llm_dart_ai\test\output_spec_test.dart packages\llm_dart_ai\test\text_call_test.dart packages\llm_dart_ai\test\text_generation_request_test.dart
dart analyze packages\llm_dart_ai
```

Result: completed.

Notes:

- `TextGenerationRequest.fromPrompt`, `fromMessages`, and `resolve` now own the
  app-facing request invariant.
- `generateTextForRequest`, `streamTextForRequest`,
  `runTextGenerationRequest`, `streamTextRunRequest`,
  `generateOutputForRequest`, `streamOutputForRequest`, and
  `generateTextCallForRequest` are the new request-based seams.
- Existing wide helper APIs remain as adapters so downstream migration can be
  staged deliberately in CSR-070.

### 2026-05-26 — CSR-030 Unified error module

Evidence:

- `packages/llm_dart_provider/lib/src/common/model_exception.dart`
- `packages/llm_dart_provider/lib/src/common/model_error_projection.dart`
- `packages/llm_dart_provider/lib/src/common/model_error.dart`
- `packages/llm_dart_provider_utils/lib/src/common/transport_model_error.dart`
- `packages/llm_dart_ai/lib/src/model/output_runner_parsing.dart`
- `packages/llm_dart_ai/lib/src/model/stream_text_run_lifecycle.dart`
- `packages/llm_dart_ai/lib/src/ui/chat_ui_stream_error.dart`
- `packages/llm_dart_provider/test/model_exception_test.dart`
- `packages/llm_dart_provider_utils/test/transport_model_error_test.dart`

Commands:

```powershell
dart test packages\llm_dart_provider\test\model_exception_test.dart packages\llm_dart_provider\test\model_error_test.dart packages\llm_dart_provider_utils\test\transport_model_error_test.dart packages\llm_dart_provider_utils\test\provider_transport_call_test.dart packages\llm_dart_ai\test\output_spec_test.dart packages\llm_dart_ai\test\stream_text_runner_test.dart packages\llm_dart_ai\test\chat_ui_stream_error_test.dart
dart test packages\llm_dart_provider\test packages\llm_dart_provider_utils\test packages\llm_dart_ai\test
dart analyze packages\llm_dart_provider packages\llm_dart_provider_utils packages\llm_dart_ai
```

Result: completed.

Notes:

- `ModelException` is the typed throwable layer; `ModelError` remains the
  serializable stream/JSON value layer.
- `modelErrorFrom` is the shared projection seam for provider, provider-utils,
  AI runtime, structured-output, and chat UI stream errors.
- Transport mappings preserve bottom-level `originalType` so the typed wrapper
  does not hide diagnostics.

### 2026-05-26 — CSR-040 Stream vocabulary composition

Evidence:

- `packages/llm_dart_ai/lib/src/stream/text_stream_event_provider_bridge.dart`
- `packages/llm_dart_ai/lib/src/stream/provider_to_text_stream_event.dart`
- `packages/llm_dart_ai/lib/src/stream/text_stream_event_to_provider.dart`
- `packages/llm_dart_ai/lib/src/serialization/text_stream_event_json_codec.dart`
- `packages/llm_dart_ai/test/language_model_stream_adapter_test.dart`

Commands:

```powershell
dart test packages\llm_dart_provider\test\language_model_stream_event_json_codec_test.dart packages\llm_dart_ai\test\text_stream_event_json_codec_test.dart packages\llm_dart_ai\test\language_model_stream_boundary_test.dart packages\llm_dart_ai\test\language_model_stream_adapter_test.dart
dart test packages\llm_dart_provider\test packages\llm_dart_ai\test
dart analyze packages\llm_dart_ai
```

Result: completed.

Notes:

- The refactor deliberately did not merge provider and AI event classes:
  provider stream events model one provider call, while AI text stream events
  add runtime lifecycle events.
- `text_stream_event_provider_bridge.dart` now owns provider-call subset
  detection and both conversion directions.
- The previous one-way conversion files remain compatibility exports so
  existing internal imports do not churn.

### 2026-05-26 — CSR-050 Provider descriptor modules

Evidence:

- `packages/llm_dart_openai/lib/src/provider/openai_family_provider_descriptor.dart`
- `packages/llm_dart_google/lib/src/google_provider_descriptor.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_provider_descriptor.dart`
- `packages/llm_dart_ollama/lib/src/ollama_provider_descriptor.dart`
- `packages/llm_dart_elevenlabs/lib/src/elevenlabs_provider_descriptor.dart`
- provider facade `specification` getters delegate to descriptors.

Commands:

```powershell
dart test packages\llm_dart_openai\test\openai_family_profile_test.dart packages\llm_dart_google\test\google_entrypoint_test.dart packages\llm_dart_anthropic\test\anthropic_entrypoint_test.dart packages\llm_dart_ollama\test\ollama_entrypoint_test.dart packages\llm_dart_elevenlabs\test\elevenlabs_entrypoint_test.dart
dart analyze packages\llm_dart_openai packages\llm_dart_google packages\llm_dart_anthropic packages\llm_dart_ollama packages\llm_dart_elevenlabs
```

Result: completed.

Notes:

- Descriptor modules own provider ids, provider specification, model facets,
  capability descriptors, and supported input shapes.
- Facades still own model construction and provider-native product clients.

### 2026-05-26 — CSR-060 Provider call kit

Evidence:

- `packages/llm_dart_provider_utils/lib/src/provider_call_kit.dart`
- `packages/llm_dart_provider_utils/lib/src/http/provider_transport_call.dart`
- `packages/llm_dart_provider_utils/test/provider_transport_call_test.dart`
- `tool/check_workspace_dependency_guards.dart`

Commands:

```powershell
dart test packages\llm_dart_provider_utils\test
dart analyze packages\llm_dart_provider_utils
dart run tool\check_workspace_dependency_guards.dart
```

Result: completed.

Notes:

- `ProviderCallKit` is the explicit object seam for model request and language
  model stream request execution.
- Existing `sendProviderModelRequest` and
  `sendProviderLanguageModelStreamRequest` functions remain compatibility
  adapters.
- Provider-specific request/response codecs stay in provider packages.

### 2026-05-27 — CSR-070 App and provider-authoring entrypoints

Evidence:

- `lib/core.dart`
- `lib/provider_authoring.dart`
- `packages/llm_dart_ai/lib/app.dart`
- `packages/llm_dart_ai/lib/src/app/app_generation.dart`
- `packages/llm_dart_ai/lib/provider_authoring.dart`
- `packages/llm_dart_provider/lib/provider_authoring.dart`
- `packages/llm_dart_provider_utils/lib/provider_call_kit.dart`
- `README.md`
- `docs/migration/0.11-sdk-aligned.md`
- `example/README.md`
- `tool/root_legacy_classification.dart`
- `test/tool/check_root_package_boundary_guards_test.dart`

Commands:

```powershell
dart analyze packages\llm_dart_ai
dart analyze .
dart run tool\check_root_package_boundary_guards.dart
dart run tool\check_example_api_guards.dart
dart test test\tool\check_root_package_boundary_guards_test.dart
dart test test\tool\check_example_api_guards_test.dart
dart test test\llm_dart_test.dart test\ai_entrypoint_test.dart test\tool\check_root_package_boundary_guards_test.dart test\tool\check_example_api_guards_test.dart
```

Result: completed.

Notes:

- `package:llm_dart/core.dart` now exports `package:llm_dart_ai/app.dart`
  instead of the broad AI compatibility barrel.
- `package:llm_dart_ai/app.dart` exposes app-facing generation helpers that
  accept `ModelMessage` through `messages:` and route through
  `TextGenerationRequest.fromMessages`.
- Provider-authoring contracts are explicit through root, AI, and provider
  package entrypoints.
- The provider call kit remains a direct provider-utils import so the root
  package does not gain a provider-utils runtime dependency.
- Advanced examples that intentionally use provider prompt/request contracts
  moved away from the root app facade.

### 2026-05-27 — CSR-080 Closeout

Evidence:

- `docs/workstreams/2026-05-core-seam-fearless-refactor/TODO.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/MILESTONES.md`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/WORKSTREAM.json`
- `docs/workstreams/2026-05-core-seam-fearless-refactor/HANDOFF.md`

Commands:

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool\check_workspace_dependency_guards.dart
dart --suppress-analytics run tool\check_root_package_boundary_guards.dart
dart --suppress-analytics run tool\check_example_api_guards.dart
dart --suppress-analytics test packages\llm_dart_ai\test
dart --suppress-analytics test packages\llm_dart_provider\test
dart --suppress-analytics test packages\llm_dart_provider_utils\test
dart --suppress-analytics test test\llm_dart_test.dart test\ai_entrypoint_test.dart test\tool\check_root_package_boundary_guards_test.dart test\tool\check_example_api_guards_test.dart test\tool\check_workspace_dependency_guards_test.dart
dart --suppress-analytics test packages\llm_dart_openai\test\openai_family_profile_test.dart packages\llm_dart_google\test\google_entrypoint_test.dart packages\llm_dart_anthropic\test\anthropic_entrypoint_test.dart packages\llm_dart_ollama\test\ollama_entrypoint_test.dart packages\llm_dart_elevenlabs\test\elevenlabs_entrypoint_test.dart
git diff --check
```

Result: completed.

Notes:

- `git diff --check` exited successfully. It printed Git CRLF working-copy
  warnings only, not whitespace errors.
- The closeout audit found and fixed one dependency-direction issue before
  closing: root provider-authoring no longer re-exports provider-utils, so the
  root package keeps the dependency policy enforced by the workspace guard.
- All six scoped seams are complete; no follow-on is required for this lane.
