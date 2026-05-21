# Fearless Boundary Reset — Evidence And Gates

Status: Closed
Last updated: 2026-05-21

## Smallest Current Proof

The first code proof is FBR-020: split OpenAI language model routing into
route-specific deep adapters without losing Responses, Chat Completions, raw
chunk, warning, cancellation, and provider-family behavior.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_lifecycle_client_test.dart
```

This proves that the first adapter split preserves the public OpenAI language
model behavior while increasing locality around route-specific implementation.

## Gate Set

### Targeted Iteration Gate

Use the task-specific command from `TODO.md`. For the first slice:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_lifecycle_client_test.dart
```

### Package Gate

Run the affected package tests and analysis from either the workspace root or
the package directory:

```powershell
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics test packages/llm_dart_openai/test
```

If workspace-level Dart commands hang, use the direct runner/analyzer API
pattern already documented in prior workstreams and record the exact command.

### Boundary Guard Gate

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
```

These gates prove provider packages do not drift back into runtime/root/chat
ownership and root remains a facade.

### Broader Closeout Gate

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Use narrower closeout gates only when a workspace command is known to hang or
is unrelated to the touched packages. Record the reason and replacement gate.

### Review Gate

Run `review-workstream` before accepting task completion. Because this is a
Dart workspace using Rust-oriented workflow skills, review evidence should
focus on:

- task ledger compliance,
- package ownership and dependency direction,
- interface depth and deletion-test outcomes,
- focused Dart tests,
- guard output,
- migration docs for breaking changes.

### Verification Gate

Run fresh task-specific gates before marking a task complete. Run broader
guards before marking the lane complete. Record command, timestamp, exit code,
and short result summary in this file or a linked evidence note.

## Evidence Anchors

- `docs/workstreams/2026-05-fearless-boundary-reset/DESIGN.md`
- `docs/workstreams/2026-05-fearless-boundary-reset/TODO.md`
- `docs/workstreams/2026-05-fearless-boundary-reset/MILESTONES.md`
- `packages/llm_dart_openai/test/openai_language_model_test.dart`
- `packages/llm_dart_provider_utils/test`
- `packages/llm_dart_provider/test/provider_contracts_test.dart`
- `packages/llm_dart_ai/test/language_model_stream_boundary_test.dart`
- `tool/check_workspace_dependency_guards.dart`
- `tool/check_root_package_boundary_guards.dart`

## Evidence Log

### 2026-05-21 18:07 +08:00 — FBR-020 OpenAI route adapter proof

Implementation evidence:

- Added `OpenAILanguageModelRouteAdapter` and `OpenAILanguageModelRouteAdapters`.
- Added route-local adapters:
  - `OpenAIResponsesLanguageModelRouteAdapter`
  - `OpenAIChatCompletionsLanguageModelRouteAdapter`
- Removed shallow switch modules:
  - `openai_language_model_request.dart`
  - `openai_language_model_response.dart`
  - `openai_language_model_stream.dart`
  - `openai_language_model_transport.dart`
- Updated `OpenAILanguageModel` and prepared-call execution so the selected
  route adapter owns request encoding, generate response decoding, stream
  decoding, and route URI selection.

Fresh command evidence:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_prepared_call_test.dart packages/llm_dart_openai/test/openai_language_model_stream_source_test.dart
```

Result: passed, 4 tests. Proves route adapter selection and source-labeled
stream decoding errors on both Responses and Chat Completions paths.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_lifecycle_client_test.dart
```

Result: passed, 91 tests. Proves the FBR-020 targeted gate: OpenAI language
model behavior, Responses codec behavior, Responses stream codec behavior, and
Responses lifecycle client behavior survive the route adapter split.

```powershell
dart --suppress-analytics analyze packages/llm_dart_openai
```

Result: passed, no issues found. Proves package-local static analysis after
the route adapter split.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test
```

Result: passed, 354 tests. Proves the broader OpenAI package behavior survives
the adapter split, including Chat Completions mainline tests.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors. Proves no workspace dependency/root boundary
regression and no diff whitespace errors.

Review note:

- Workstream compliance: FBR-020 stayed within OpenAI language/responses/chat
  scope and changed tests only for the moved stream/prepared-call seams.
- Code quality: the route-specific adapters are deeper than the removed switch
  helpers because each adapter owns route-specific request, response, stream,
  and URI behavior behind one interface.
- Residual risk: provider transport execution is still separate and should be
  deepened in FBR-040 instead of widening FBR-020.

### 2026-05-21 18:30 +08:00 — FBR-040 Provider transport kit

Implementation evidence:

- Added `sendProviderModelRequest` and
  `sendProviderLanguageModelStreamRequest` in
  `packages/llm_dart_provider_utils/lib/src/http/provider_transport_call.dart`.
- Added provider-utils tests covering:
  - response body/header decode,
  - transport cancellation normalization to provider cancellation,
  - `StartEvent` ordering before decoded stream events,
  - transport HTTP errors projected to stream `ErrorEvent`.
- Refactored provider language-model stream execution for OpenAI, Google,
  Anthropic, and Ollama to use the shared provider stream request seam.
- Refactored provider one-shot model request wrappers for OpenAI, Google,
  Anthropic, Ollama, and ElevenLabs to use the shared provider model request
  seam.
- Refactored OpenAI Assistants, Files, Moderation, and Responses lifecycle
  support plus Anthropic Files support so product helper clients also inherit
  the same cancellation/error transport boundary.

Fresh command evidence:

```powershell
dart --suppress-analytics test packages/llm_dart_provider_utils/test/provider_transport_call_test.dart
```

Result: passed, 4 tests. Proves the new provider transport call seam in
isolation.

```powershell
dart --suppress-analytics analyze packages/llm_dart_provider_utils
dart --suppress-analytics test packages/llm_dart_provider_utils/test
```

Result: passed, no analyzer issues and 9 provider-utils tests passed. Proves
the package-local helper surface is statically valid.

```powershell
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics analyze packages/llm_dart_google
dart --suppress-analytics analyze packages/llm_dart_anthropic
dart --suppress-analytics analyze packages/llm_dart_ollama
dart --suppress-analytics analyze packages/llm_dart_elevenlabs
dart --suppress-analytics analyze packages/llm_dart_openai packages/llm_dart_google packages/llm_dart_anthropic packages/llm_dart_provider_utils packages/llm_dart_ollama packages/llm_dart_elevenlabs
```

Result: all passed, no issues found. Proves touched provider packages remain
analyzer-clean after moving transport choreography into provider-utils.

```powershell
dart --suppress-analytics test packages/llm_dart_provider_utils/test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_google/test/google_language_model_test.dart packages/llm_dart_anthropic/test/anthropic_language_model_test.dart
```

Result: passed, 59 tests. Proves the FBR-040 targeted gate: provider-utils
plus OpenAI, Google, and Anthropic language model regressions survive the
transport seam extraction.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test
dart --suppress-analytics test packages/llm_dart_google/test
dart --suppress-analytics test packages/llm_dart_anthropic/test
dart --suppress-analytics test packages/llm_dart_ollama/test packages/llm_dart_elevenlabs/test
```

Result: all passed. OpenAI package passed 354 tests, Google package passed 116
tests, Anthropic package passed 125 tests, and Ollama plus ElevenLabs passed 65
tests. Proves broader provider behavior after adopting the shared transport
call seam.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors. Proves no workspace dependency/root boundary
regression and no diff whitespace errors.

Review note:

- Workstream compliance: FBR-040 deepened the provider-utils seam without
  moving transport primitives out of `llm_dart_transport` or model-call
  contracts out of `llm_dart_provider`.
- Code quality: repeated try/send/decode/cancellation/error choreography is now
  tested once and provider packages provide only provider-local request
  construction and response/stream decode callbacks.
- Deliberate widening: Ollama and ElevenLabs wrappers were also moved because
  the same duplicate choreography existed there; this strengthens the seam
  without changing public behavior.
- Residual risk: dependency guard FBR-050 should now codify that provider
  packages use provider-utils for transport call execution and do not re-grow
  direct send/stream choreography.

### 2026-05-21 18:35 +08:00 — FBR-050 Provider transport guardrails

Implementation evidence:

- Updated `tool/check_workspace_dependency_guards.dart` to scan provider
  implementation packages for direct `transport.send(...)` and
  `transport.sendStream(...)` calls.
- Added a focused failure test in
  `test/tool/check_workspace_dependency_guards_test.dart` proving the guard
  rejects provider-local direct transport send choreography.
- Updated the success message so the guard explicitly states that provider
  transport calls must stay behind provider-utils.

Fresh command evidence:

```powershell
dart --suppress-analytics test test/tool/check_workspace_dependency_guards_test.dart
```

Result: passed, 9 tests. Proves current repository passes and the new direct
provider transport send failure fixture is caught.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
```

Result: passed. Output confirms provider transport calls stay behind
provider-utils.

```powershell
dart --suppress-analytics analyze tool/check_workspace_dependency_guards.dart test/tool/check_workspace_dependency_guards_test.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Review note:

- Workstream compliance: FBR-050 only touched the workspace guard and its
  focused test.
- Code quality: the guard codifies FBR-040's new seam without banning
  `llm_dart_transport` ownership or provider request construction.
- Residual risk: the regex intentionally catches the common `transport` local
  variable name; if a future adapter uses a different variable name, the guard
  may need an AST-based follow-up or a broader call-pattern rule.

### 2026-05-21 19:06 +08:00 — FBR-060 Breaking compatibility exit

Implementation evidence:

- Deleted `packages/llm_dart_core/**` entirely instead of keeping a deprecated
  implementation-owning or alias-owning stub.
- Deleted the obsolete core compatibility-shell guard:
  - `tool/check_core_compatibility_shell_guard.dart`
  - `test/tool/check_core_compatibility_shell_guard_test.dart`
- Removed `llm_dart_core` from root dev dependencies, generated workspace
  override package lists, consumer smoke dependencies, workspace package test
  targets, release readiness steps, the MCP example override, README package
  roles, and `test/test_all.dart`.
- Moved the root prompt-normalization test off the deleted core package and
  onto the owning provider package.
- Updated migration docs to state that `llm_dart_core` has been removed from
  the package graph while keeping a historical before/after import example.
- Kept the transport guard's historical `package:llm_dart_core/...` fixture as
  a deleted-package regression guard so the transport package cannot re-import
  the old compatibility surface.

Fresh command evidence:

```powershell
dart --suppress-analytics run tool/bootstrap_workspace_pubspec_overrides.dart
dart --suppress-analytics pub get
```

Result: passed. Workspace overrides and root dependency resolution were
regenerated after deleting `packages/llm_dart_core`; root dependency resolution
removed the package from the active graph.

```powershell
dart --suppress-analytics analyze lib test tool packages/llm_dart_ai
```

Result: passed, no issues found. Proves the root, tool, test, and touched AI
internal surfaces compile without `llm_dart_core`.

```powershell
dart --suppress-analytics test test/tool/bootstrap_workspace_pubspec_overrides_test.dart test/tool/run_workspace_package_tests_test.dart test/tool/run_consumer_smoke_test.dart test/tool/check_workspace_dependency_guards_test.dart test/tool/check_root_package_boundary_guards_test.dart test/tool/check_transport_boundary_guards_test.dart test/prompt_normalization_test.dart
```

Result: passed, 62 tests. Proves the FBR-060 targeted migration surface:
workspace bootstrap, package-test targets, consumer smoke pubspec/program
builders, dependency/root/transport guards, and prompt normalization no longer
depend on the removed core package.

```powershell
dart --suppress-analytics test test/tool/release_readiness_test.dart
dart --suppress-analytics test test/test_all.dart
```

Result: both passed. Release readiness tests passed 9 tests; aggregate
`test/test_all.dart` passed 152 tests. Proves the removed core guard is no
longer part of release/test orchestration and the root tool/integration suite
still composes.

```powershell
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_transport_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors. Proves root remains a facade, workspace
dependency policy accepts the deleted core package, transport cannot depend on
the removed root/core surfaces, and the diff has no whitespace errors.

Review note:

- Workstream compliance: FBR-060 chose the stronger allowed outcome — full
  deletion from the package graph — and removed orchestration hooks that would
  otherwise keep compatibility-shell ownership alive.
- Code quality: the remaining references to `llm_dart_core` are historical
  migration docs and negative guard fixtures/messages, not active package
  dependencies or implementation imports.
- Residual risk: downstream consumers importing `package:llm_dart_core/...`
  must migrate to `llm_dart`, `llm_dart_ai`, or `llm_dart_provider`; this is
  intentional for the breaking line and is documented in the migration guide.

### 2026-05-21 19:24 +08:00 — FBR-070 Provider specification seam freeze

Implementation evidence:

- Added `ProviderSpecification` in
  `packages/llm_dart_provider/lib/src/provider/provider_specification.dart`.
  The seam includes:
  - `ProviderSpecificationVersion.v1`
  - explicit `ProviderModelFacet` declarations
  - shared capability descriptors
  - provider-owned feature descriptors
  - supported input-shape discovery via `ProviderInputShapeDescriptor`
- Made `Provider.specification` required. This is intentionally breaking for
  custom provider implementations because provider identity, model facets, and
  supported input shapes now live behind one explicit provider seam.
- Updated `ProviderModelFacetSupportResolver` so model support requires both
  the matching provider interface and a matching declared specification facet.
  This removes the old implicit “method implementation equals support” coupling.
- Updated `ProviderRegistry` with sorted `providerSpecifications` and
  `providerSpecification(providerId)` access, and validation that
  `provider.specification.providerId` matches the registry key.
- Added concrete provider facade specifications for:
  - OpenAI and OpenAI-compatible profiles
  - Google
  - Anthropic
  - Ollama
  - ElevenLabs
- Exported provider specification primitives from the provider foundation
  entrypoint while keeping typed provider options as the provider-native
  extension path.

Reference note:

- This follows the `repo-ref/ai` provider direction by making provider objects
  carry an explicit specification/version and model facet surface, but keeps a
  Dart-native single current version instead of copying TypeScript v2/v3/v4
  directory unions.

Fresh command evidence:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/provider_contracts_test.dart packages/llm_dart_provider/test/provider_registry_test.dart packages/llm_dart_provider/test/provider_model_facet_support_test.dart
```

Result: passed, 57 tests. Proves the new provider specification contract,
provider registry specification access/validation, and facet resolver behavior.

```powershell
dart --suppress-analytics analyze packages/llm_dart_provider packages/llm_dart_openai packages/llm_dart_google packages/llm_dart_anthropic packages/llm_dart_ollama packages/llm_dart_elevenlabs
```

Result: passed, no issues found. Proves the breaking `Provider.specification`
getter is implemented by touched concrete provider facades.

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test
```

Result: passed, 93 tests. Proves the full provider-spec package remains green
after freezing the specification seam.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_openai/test/openai_model_describer_test.dart packages/llm_dart_google/test/google_entrypoint_test.dart packages/llm_dart_anthropic/test/anthropic_entrypoint_test.dart packages/llm_dart_ollama/test/ollama_entrypoint_test.dart packages/llm_dart_elevenlabs/test/elevenlabs_entrypoint_test.dart
```

Result: passed, 26 tests. Proves provider facade construction and model
describer behavior still compose with the explicit specification getter.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test packages/llm_dart_google/test packages/llm_dart_anthropic/test packages/llm_dart_ollama/test packages/llm_dart_elevenlabs/test
```

Result: passed, 660 tests. Proves concrete provider packages remain green
after adopting explicit provider specifications.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Review note:

- Workstream compliance: FBR-070 stayed on provider/provider-facade contracts
  and did not move runtime helper ownership into provider specs.
- Code quality: support discovery now has a deep provider seam rather than
  scattered interface checks; registry diagnostics can expose provider specs in
  stable sorted order.
- Residual risk: provider input-shape declarations are intentionally
  conservative and descriptive. Future provider package work should enrich
  them with provider-owned evidence rather than converting them into a
  lowest-common-denominator option bag.

### 2026-05-21 19:32 +08:00 — FBR-080 Stream vocabulary composition

Implementation evidence:

- Updated `TextStreamEventJsonCodec` so AI runtime full-stream serialization
  delegates all provider model-call event JSON to
  `LanguageModelStreamEventJsonCodec` through the existing
  `textStreamEventToProvider` and `textStreamEventFromProvider` bridge.
- Kept runtime-only event serialization in
  `TextStreamLifecycleEventJsonCodec` for:
  - `RunStartEvent`
  - `RunFinishEvent`
  - `StepStartEvent`
  - `StepFinishEvent`
  - `ToolOutputDeniedEvent`
  - `AbortEvent`
- Deleted duplicated AI-side provider-vocabulary codec files:
  - `text_stream_content_event_json_codec.dart`
  - `text_stream_text_content_event_json_codec.dart`
  - `text_stream_tool_event_json_codec.dart`
  - `text_stream_tool_input_event_json_codec.dart`
  - `text_stream_tool_lifecycle_event_json_codec.dart`
- Added tests proving AI model-call event wire shape equals the provider codec
  wire shape, while runtime-only events remain outside provider stream
  serialization.

Fresh command evidence:

```powershell
dart --suppress-analytics test packages/llm_dart_provider/test/language_model_stream_event_json_codec_test.dart packages/llm_dart_ai/test/text_stream_event_json_codec_test.dart packages/llm_dart_ai/test/language_model_stream_boundary_test.dart
```

Result: passed, 11 tests. Proves the FBR-080 targeted gate: provider stream
codec, AI text stream codec composition, and provider-to-runtime stream
boundary behavior.

```powershell
dart --suppress-analytics analyze packages/llm_dart_ai packages/llm_dart_provider
```

Result: passed, no issues found. Proves the deleted AI stream codec files are
not referenced and the provider/AI packages remain statically valid.

```powershell
dart --suppress-analytics test packages/llm_dart_ai/test
dart --suppress-analytics test packages/llm_dart_provider/test
```

Result: both passed. AI package passed 178 tests; provider package passed 93
tests. Proves the broader runtime/provider stream and serialization behavior
after composing provider model-call JSON vocabulary.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Review note:

- Workstream compliance: FBR-080 preserves the provider/runtime seam: provider
  owns model-call event serialization; AI owns full-stream runtime lifecycle
  event serialization.
- Code quality: the repeated content/tool JSON codec implementation has been
  removed from AI. AI now composes the provider codec through an explicit
  bridge, making future model-call vocabulary changes one-provider-package
  concern.
- Residual risk: AI and provider still have separate event classes by design.
  If future work wants deeper composition, it should target value helpers or
  generated bridge helpers without making AI lifecycle events provider-owned.

### 2026-05-21 20:04 +08:00 — FBR-090 Runtime helper option surface consolidation

Implementation evidence:

- Added `TextGenerationRuntimeRequest` as the internal AI text-generation
  runtime request seam. It owns prompt/message normalization, immutable tool
  and stop-condition snapshots, shared step planner/continuation construction,
  cancellation checks, cancellation reason projection, and structured-output
  option derivation.
- Refactored `GenerateTextRunner` and `StreamTextRunner` to hold one runtime
  request instead of duplicating model, prompt, tools, options, callbacks,
  max-step, stop-condition, and cancellation fields.
- Refactored `runTextGeneration(...)`, `streamTextRun(...)`,
  `generateOutput(...)`, `streamOutput(...)`, `generateTextCall(...)`, and
  `streamTextCall(...)` so public helper ergonomics stay stable while internal
  option plumbing flows through the runtime request seam.
- Added `text_generation_runtime_request_test.dart` for the new deep module:
  message normalization, collection freezing, planner/continuation creation,
  prompt-history copying, and structured-output option derivation.

Fresh command evidence:

```powershell
dart --suppress-analytics test packages/llm_dart_ai/test/text_generation_runtime_request_test.dart packages/llm_dart_ai/test/generate_text_runner_test.dart packages/llm_dart_ai/test/stream_text_runner_test.dart packages/llm_dart_ai/test/output_spec_test.dart packages/llm_dart_ai/test/text_call_test.dart
```

Result: passed, 66 tests. Proves the FBR-090 targeted runtime runner,
structured-output, text-call, and new runtime-request behavior.

```powershell
dart --suppress-analytics analyze packages/llm_dart_ai
```

Result: passed, no issues found. Proves the AI runtime package is statically
valid after moving the repeated helper option surface behind the new internal
runtime request.

```powershell
dart --suppress-analytics test packages/llm_dart_ai/test
```

Result: passed, 181 tests. Proves the broader AI runtime, prompt, stream,
output, and UI projection package tests remain green after FBR-090.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_transport_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Review note:

- Workstream compliance: FBR-090 stayed within
  `packages/llm_dart_ai/lib/src/model/**` and `packages/llm_dart_ai/test/**`.
  It keeps public helper signatures stable while moving duplicated runtime
  implementation knobs inward.
- Code quality: the new runtime request is intentionally internal and deep:
  a narrow object captures common request state while runner-specific lifecycle
  and stream behavior remain in their existing specialized modules.
- Residual risk: `generateText(...)` and `streamText(...)` still expose broad
  public convenience signatures by design. Future work can introduce a public
  object-style request API, but this task deliberately avoided changing
  user-facing ergonomics while collapsing implementation duplication.

### 2026-05-21 20:25 +08:00 — FBR-100 Migration docs and examples

Implementation evidence:

- Updated `README.md` to document the active breaking architecture line:
  root remains provider-neutral, concrete provider construction comes from
  direct provider packages, `llm_dart_core` is removed, and root legacy
  provider/model/builder subpaths are migration warnings.
- Updated `CHANGELOG.md` with Unreleased entries for:
  `llm_dart_core` deletion, provider specifications, provider transport seam,
  AI/provider stream-codec composition, OpenAI route adapters, and the new AI
  runtime request seam.
- Updated `docs/migration/0.11-sdk-aligned.md` so before/after imports use
  direct provider packages plus `package:llm_dart/core.dart`, document
  `ProviderSpecification`, and include `llm_dart_core` in the final
  no-obsolete-import checklist.
- Updated `packages/llm_dart_ai/README.md` to explain the internal runtime
  request seam and clarify that `llm_dart_core` no longer owns runtime APIs.
- Updated example README guidance for getting-started, OpenAI, Ollama,
  ElevenLabs, and MCP so examples do not recommend removed root provider
  subpaths or grouped root provider facades.

Fresh command evidence:

```powershell
dart --suppress-analytics analyze .
```

Result: passed, no issues found. Proves the documented breaking line and
example changes remain statically valid across the workspace.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_transport_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Review note:

- Workstream compliance: FBR-100 stayed on docs/examples/changelog surfaces
  and does not introduce implementation changes beyond the already-completed
  architecture slices.
- Code quality: documentation now consistently treats direct provider packages
  and focused runtime facades as the target architecture. Obsolete paths remain
  only in removal warnings, historical changelog entries, or explicit
  before/after migration examples.
- Residual risk: older historical changelog sections still mention legacy
  builder APIs as past release history. That is acceptable as chronology, but
  release-facing guidance now points to direct provider packages instead.

### 2026-05-21 21:12 +08:00 — FBR-030 Profile-owned OpenAI-family policy

Implementation evidence:

- Added `OpenAIFamilyRoutePolicy` and moved OpenAI-family language-model route
  selection behind `OpenAIFamilyProfile.routePolicy`.
- Moved invocation option resolution behind
  `OpenAIFamilyProfile.optionResolver` and kept the existing
  `openAIFamilyOptionResolverFor(...)` helper as a thin compatibility helper.
- Moved model capability feature policy behind
  `OpenAIFamilyProfile.capabilityPolicy` and kept the existing
  `openAIFamilyCapabilityPolicyFor(...)` helper as a thin compatibility
  helper.
- Moved Chat Completions request-field policy behind
  `OpenAIFamilyProfile.chatCompletionsRequestPolicy`.
- Added `supportsOpenAIToolOptions` to the profile seam and changed
  Chat Completions tool-option rejection to use profile policy instead of a
  `providerNamespace != 'openai'` string check.
- Added `OpenAICompatibleProfile` for explicit custom OpenAI-compatible
  endpoints. Examples now use that profile instead of mutating
  `OpenAIProfile`.

Fresh command evidence:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_model_describer_test.dart packages/llm_dart_openai/test/openai_tool_options_test.dart packages/llm_dart_openai/test/openai_responses_request_body_projection_test.dart
```

Result: passed, 19 tests. Proves the FBR-030 targeted describer,
tool-options, and Responses body projection behavior after moving
provider-family policies onto the profile seam.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_profile_test.dart packages/llm_dart_openai/test/openai_family_option_resolver_test.dart packages/llm_dart_openai/test/openai_family_capability_policy_test.dart packages/llm_dart_openai/test/openai_chat_completions_request_policy_test.dart packages/llm_dart_openai/test/openai_language_model_prepared_call_test.dart
```

Result: passed, 26 tests. Proves route policy, option resolver,
capability policy, request policy, and prepared-call route selection through
profile-owned seams.

```powershell
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics test packages/llm_dart_openai/test
```

Result: both passed. Analyzer reported no issues; the OpenAI package test
suite passed 354 tests.

```powershell
dart --suppress-analytics analyze .
```

Result: passed, no issues found. Proves the public example migration to
`OpenAICompatibleProfile` is statically valid across the workspace.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_transport_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Review note:

- Workstream compliance: FBR-030 stayed inside OpenAI provider/language/tests
  plus the custom-compatible example required by the profile API break.
- Code quality: provider-family policy is now profile-owned rather than
  selected by one central `switch(profile)` or provider-id string check.
  `OpenAIProfile` now represents the OpenAI route/policy surface, while
  `OpenAICompatibleProfile` represents generic chat-completions-compatible
  endpoints.
- Residual risk: the historical resolver/capability helper functions remain
  as thin wrappers for internal tests and compatibility. They no longer own
  policy selection; a later cleanup can remove them when downstream imports
  are audited.

### 2026-05-21 21:12 +08:00 — FBR-110 Final closeout verification

Closeout review:

- Workstream compliance: all TODO ledger tasks FBR-010 through FBR-110 are
  complete and have evidence anchors. The lane target state is met: OpenAI
  route adapters are deep, provider transport execution is shared, the core
  compatibility shell is deleted, provider specifications are explicit,
  AI/provider stream JSON vocabulary is composed, runtime helper state has one
  internal seam, and migration docs teach the breaking line.
- Code quality: the remaining public compatibility helpers are thin wrappers
  or historical documentation. No implementation owner remains in
  `llm_dart_core`, root legacy paths, direct provider transport choreography,
  or duplicated AI content/tool stream codecs.

Fresh command evidence:

```powershell
dart --suppress-analytics analyze .
```

Result: passed, no issues found.

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test
```

Result: passed, 354 tests. This package test was rerun during FBR-030 closeout
because OpenAI profile policy was the last implementation slice.

```powershell
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_transport_boundary_guards.dart
git diff --check
```

Result: all passed. The Git command emitted line-ending warnings for touched
files but no whitespace errors.

Residual risks and suggested follow-ons:

- Public convenience helpers still have broad parameter signatures by design.
  A future workstream can consider a public object-style request API once the
  alpha migration surface stabilizes.
- Thin historical OpenAI-family helper functions
  `openAIFamilyOptionResolverFor(...)` and
  `openAIFamilyCapabilityPolicyFor(...)` remain as wrappers. They are no
  longer policy owners and can be removed in a later public API cleanup if
  desired.
- Some older workstream/historical changelog docs mention pre-reset concepts
  such as `supportsResponsesApi`; those are intentionally historical and not
  active migration guidance.
