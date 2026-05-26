# Core Seam Fearless Refactor — Handoff

Status: Closed
Last updated: 2026-05-27

## Current State

The lane has been opened from the architecture report and the user's explicit
request to break compatibility and complete all six fearless refactor
candidates. CSR-010 through CSR-070 are complete.

CSR-020 added `TextGenerationRequest` as the app-facing text generation seam
and routed base generation, streaming, structured output, and text-call helpers
through request-based entrypoints.

CSR-030 added `ModelException` for typed throwable errors and `modelErrorFrom`
as the shared projection seam into serializable `ModelError` values. Provider
transport mapping, structured-output parsing, stream failure, and chat UI
stream error projection now route through that seam.

CSR-040 consolidated AI/provider stream vocabulary conversion into
`text_stream_event_provider_bridge.dart`. Provider-call events remain
provider-owned, while AI runtime lifecycle events remain AI-owned.

CSR-050 added provider-owned descriptor modules for OpenAI-family, Google,
Anthropic, Ollama, and ElevenLabs. Facade `specification` getters now delegate
to descriptors while model construction and native product clients stay
provider-owned.

CSR-060 made `llm_dart_provider_utils` an explicit provider call kit by adding
`ProviderCallKit` and a `provider_call_kit.dart` aggregate export. Existing
function helpers remain compatibility adapters, and provider-specific codecs
stay in provider packages.

CSR-070 split app-facing and provider-authoring entrypoints. Root `core.dart`
now exports `package:llm_dart_ai/app.dart`; app text helpers accept
`ModelMessage` through `messages:`. Provider-authoring contracts are explicit
through `package:llm_dart/provider_authoring.dart`,
`package:llm_dart_ai/provider_authoring.dart`, and
`package:llm_dart_provider/provider_authoring.dart`. The provider call kit
remains a direct `package:llm_dart_provider_utils/provider_call_kit.dart`
import so root does not gain a provider-utils runtime dependency.

## Active Task

- Task ID: none
- Owner: planner
- Files: `docs/workstreams/2026-05-core-seam-fearless-refactor/**`
- Validation: `dart --suppress-analytics analyze . && dart --suppress-analytics run tool/check_workspace_dependency_guards.dart && dart --suppress-analytics run tool/check_root_package_boundary_guards.dart && git diff --check`
- Status: CLOSED
- Review: completed in CSR-080
- Evidence: recorded in `EVIDENCE_AND_GATES.md`

## Decisions Since Last Update

- Open a new workstream instead of reusing Wave 3 because Wave 3 is closed and
  covered different local-hardening candidates.
- Start with public app-facing text generation request because internal
  `TextGenerationRuntimeRequest` already proves the deep module shape.
- Keep provider-native features provider-owned.
- Use `repo-ref/ai` as ownership reference only, not as a TypeScript/package
  layout template.
- Existing unrelated user changes in the working tree must not be reverted or
  formatted away.
- Keep existing wide helper APIs as adapters until CSR-070 decides the final
  app/provider-authoring entrypoint shape.
- Keep `ModelError.fromUnknown` as compatibility; prefer `modelErrorFrom` for
  new projection points.
- Avoid merging provider stream event classes into AI event classes; use the
  bridge for provider-call subset composition.
- Provider descriptors own specification metadata only; concrete providers
  still own codecs, model construction, and native product clients.
- Provider call execution is now reachable through `ProviderCallKit`; providers
  should keep codecs local and delegate repeated transport/error/stream policy
  to provider-utils.
- The default app facade should not teach provider prompt/request contracts.
  Provider-facing `PromptMessage`, `GenerateTextRequest`, and provider stream
  events remain reachable through provider-authoring entrypoints.
- Root provider-authoring intentionally does not re-export provider-utils; use
  the provider-utils call-kit entrypoint directly where that dependency is
  acceptable.

## Blockers

- None known.

## Next Recommended Action

- No required next action for this lane. Commit only after maintainer review
  and confirmation because the working tree includes other pre-existing
  unrelated changes.
